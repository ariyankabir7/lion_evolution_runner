#!/usr/bin/env python3
"""Synthesises every sound effect and the music loop, then writes OGG files to assets/audio/.

Stand-ins until recorded/CC0 audio arrives: drop a file with the same name into assets/audio/
and it replaces the generated one (see docs/AUDIO.md). Existing files are left alone, so dropped-in
audio is never overwritten; pass --force to regenerate everything after tweaking a synth:

    python3 tools/generate_audio.py [--force]

Needs numpy and ffmpeg (libvorbis).
"""
import os
import subprocess
import sys
import tempfile
import wave

import numpy as np

SR = 44100
ROOT = os.path.join(os.path.dirname(__file__), '..', 'assets', 'audio')
rng = np.random.default_rng(7)


# ---- building blocks ---------------------------------------------------------------------------

def t_axis(dur):
    return np.arange(int(SR * dur)) / SR


def env(n, attack=0.005, release=0.1, dur=None):
    """Linear attack, exponential-ish release to zero at the end."""
    dur = dur or n / SR
    t = np.arange(n) / SR
    a = np.clip(t / max(attack, 1e-4), 0, 1)
    r = np.clip((dur - t) / max(release, 1e-4), 0, 1) ** 2
    return a * r


def sweep(f0, f1, dur, shape='sine', curve=1.0):
    t = t_axis(dur)
    f = f0 + (f1 - f0) * (t / dur) ** curve
    phase = 2 * np.pi * np.cumsum(f) / SR
    return wave_of(phase, shape)


def tone(freq, dur, shape='sine'):
    phase = 2 * np.pi * freq * t_axis(dur)
    return wave_of(phase, shape)


def wave_of(phase, shape):
    if shape == 'sine':
        return np.sin(phase)
    if shape == 'square':
        return np.sign(np.sin(phase)) * 0.6
    if shape == 'saw':
        return 2 * ((phase / (2 * np.pi)) % 1) - 1
    if shape == 'tri':
        return 2 * np.abs(2 * ((phase / (2 * np.pi)) % 1) - 1) - 1
    raise ValueError(shape)


def noise(dur):
    return rng.uniform(-1, 1, int(SR * dur))


def lowpass(x, cutoff):
    """One-pole low-pass; cutoff may be a scalar or an array (sweeping filter)."""
    cutoff = np.broadcast_to(np.asarray(cutoff, dtype=float), x.shape)
    a = 1 - np.exp(-2 * np.pi * cutoff / SR)
    y = np.empty_like(x)
    acc = 0.0
    for i, (v, k) in enumerate(zip(x, a)):
        acc += k * (v - acc)
        y[i] = acc
    return y


def highpass(x, cutoff):
    return x - lowpass(x, cutoff)


def place(parts, total=None):
    """Mixes (start_seconds, signal) pairs into one buffer."""
    end = max(int(s * SR) + len(sig) for s, sig in parts)
    out = np.zeros(max(end, int((total or 0) * SR)))
    for s, sig in parts:
        i = int(s * SR)
        out[i:i + len(sig)] += sig
    return out


def note(n):
    """MIDI note number to Hz."""
    return 440.0 * 2 ** ((n - 69) / 12)


def pluck(freq, dur, shape='square', release=None, attack=0.004, vib=0.0):
    t = t_axis(dur)
    f = freq * (1 + vib * np.sin(2 * np.pi * 6 * t))
    sig = wave_of(2 * np.pi * np.cumsum(f) / SR, shape)
    return sig * env(len(sig), attack=attack, release=release or dur * 0.9)


def normalize(x, peak=0.89):
    m = np.max(np.abs(x))
    return x if m == 0 else x * (peak / m)


FORCE = '--force' in sys.argv


def write(name, x, peak=0.89):
    path = os.path.join(ROOT, name + '.ogg')
    if os.path.exists(path) and not FORCE:
        print(f'{path}  kept (exists)')
        return
    x = normalize(x, peak)
    # 4ms fade at both ends to avoid clicks.
    f = min(len(x) // 2, int(SR * 0.004))
    x[:f] *= np.linspace(0, 1, f)
    x[-f:] *= np.linspace(1, 0, f)
    pcm = (x * 32767).astype(np.int16)
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with tempfile.NamedTemporaryFile(suffix='.wav', delete=False) as tmp:
        with wave.open(tmp.name, 'wb') as w:
            w.setnchannels(1)
            w.setsampwidth(2)
            w.setframerate(SR)
            w.writeframes(pcm.tobytes())
    subprocess.run(['ffmpeg', '-y', '-loglevel', 'error', '-i', tmp.name, '-c:a', 'libvorbis', '-q:a', '4', path],
                   check=True)
    os.unlink(tmp.name)
    print(f'{path}  {len(x) / SR:.2f}s')


# ---- sound effects -----------------------------------------------------------------------------

def sfx_coin():
    # Classic two-step "bling": B5 then E6, square with a quick decay.
    a = pluck(note(83), 0.07, 'square', release=0.07)
    b = pluck(note(88), 0.28, 'square', release=0.26)
    return place([(0, a * 0.8), (0.06, b * 0.8)])


def sfx_meat():
    # Chomp: two filtered noise bites over a low thump, then a happy up-blip.
    parts = []
    for i, s in enumerate((0.0, 0.11)):
        n = lowpass(noise(0.09), 1800) * env(int(SR * 0.09), 0.002, 0.08)
        thump = sweep(220, 90, 0.09) * env(int(SR * 0.09), 0.002, 0.08)
        parts.append((s, n * 1.4 + thump * 0.7))
    blip = sweep(note(72), note(84), 0.14, 'tri') * env(int(SR * 0.14), 0.005, 0.1)
    parts.append((0.22, blip * 0.6))
    return place(parts)


def sfx_broccoli():
    # "Bleh": a wobbly descending buzzy tone.
    t = t_axis(0.42)
    f = 330 * (1 - 0.45 * t / 0.42) * (1 + 0.06 * np.sin(2 * np.pi * 14 * t))
    sig = wave_of(2 * np.pi * np.cumsum(f) / SR, 'saw')
    sig = lowpass(sig, 1400) * env(len(sig), 0.01, 0.3)
    squish = lowpass(noise(0.08), 900) * env(int(SR * 0.08), 0.002, 0.07)
    return place([(0, squish * 0.9), (0.03, sig)])


def sfx_hit():
    # Heavy impact: pitch-dropping kick, crunchy noise, a little rumble tail.
    kick = sweep(160, 40, 0.35, curve=0.4) * env(int(SR * 0.35), 0.001, 0.33)
    crunch = lowpass(noise(0.22), np.linspace(5000, 400, int(SR * 0.22))) * env(int(SR * 0.22), 0.001, 0.2)
    rumble = lowpass(noise(0.5), 180) * env(int(SR * 0.5), 0.01, 0.45)
    return place([(0, kick * 1.1), (0, crunch * 0.9), (0.02, rumble * 1.6)])


def sfx_shield():
    # Metallic "clang" (inharmonic partials) with a bright shimmer.
    dur = 0.6
    t = t_axis(dur)
    sig = sum(np.sin(2 * np.pi * f * t) * np.exp(-t * d) * a
              for f, d, a in ((880, 7, 1.0), (1397, 9, 0.6), (2217, 12, 0.45), (3150, 16, 0.3)))
    click = highpass(noise(0.02), 2000) * env(int(SR * 0.02), 0.0005, 0.018)
    return place([(0, sig), (0, click * 0.7)])


def sfx_shield_graze():
    # Softer ping when an obstacle bounces off during shield grace.
    t = t_axis(0.3)
    sig = (np.sin(2 * np.pi * 1320 * t) + 0.5 * np.sin(2 * np.pi * 1980 * t)) * np.exp(-t * 14)
    return sig


def sfx_evolve():
    # Rising power-up arpeggio with a sparkle on top.
    seq = [60, 64, 67, 72, 76, 79, 84]
    parts = [(i * 0.055, pluck(note(n), 0.16, 'square', release=0.15) * 0.7) for i, n in enumerate(seq)]
    parts.append((0.0, sweep(200, 900, 0.4, 'saw') * env(int(SR * 0.4), 0.02, 0.2) * 0.25))
    shimmer = highpass(noise(0.5), 6000) * env(int(SR * 0.5), 0.2, 0.3) * 0.35
    parts.append((0.3, shimmer))
    parts.append((0.38, pluck(note(88), 0.45, 'tri', release=0.43) * 0.6))
    return place(parts)


def sfx_devolve():
    seq = [72, 67, 63, 60]
    return place([(i * 0.07, pluck(note(n), 0.16, 'tri', release=0.15)) for i, n in enumerate(seq)])


def sfx_swoosh():
    # Lane change: band-passed noise sweeping up then down.
    n = int(SR * 0.22)
    cut = np.concatenate([np.linspace(600, 3200, n // 2), np.linspace(3200, 900, n - n // 2)])
    sig = highpass(lowpass(noise(0.22), cut), 300)
    return sig * env(n, 0.05, 0.14)


def sfx_finish():
    # Short fanfare: G C E G(8va) with a held chord.
    seq = [(0.0, 67), (0.09, 72), (0.18, 76)]
    parts = [(s, pluck(note(n), 0.14, 'square', release=0.13) * 0.6) for s, n in seq]
    for n in (72, 76, 79, 84):
        parts.append((0.27, pluck(note(n), 0.6, 'square', release=0.5, vib=0.004) * 0.35))
    return place(parts)


def sfx_fight():
    # Cartoon brawl: a burst of random thumps and scuffs over 1.2s.
    parts = []
    s = 0.0
    while s < 1.1:
        d = rng.uniform(0.04, 0.09)
        if rng.random() < 0.5:
            sig = sweep(rng.uniform(140, 260), 50, d) * env(int(SR * d), 0.001, d)
        else:
            sig = lowpass(noise(d), rng.uniform(1200, 4000)) * env(int(SR * d), 0.001, d)
        parts.append((s, sig * rng.uniform(0.5, 1.0)))
        s += rng.uniform(0.04, 0.1)
    dust = lowpass(noise(1.2), 500) * env(int(SR * 1.2), 0.05, 0.3) * 0.6
    parts.append((0, dust))
    return place(parts)


def sfx_victory():
    # Upbeat jingle: C E G C' | A B C'' held.
    seq = [(0.0, 72, 0.12), (0.12, 76, 0.12), (0.24, 79, 0.12), (0.36, 84, 0.24),
           (0.62, 81, 0.12), (0.74, 83, 0.12), (0.86, 84, 0.7)]
    parts = [(s, pluck(note(n), d, 'square', release=d * 0.9, vib=0.005 if d > 0.5 else 0) * 0.55)
             for s, n, d in seq]
    for s, n in ((0.0, 48), (0.36, 55), (0.62, 53), (0.86, 48)):
        parts.append((s, pluck(note(n), 0.3, 'tri', release=0.28)))
    parts.append((0.86, highpass(noise(0.6), 7000) * env(int(SR * 0.6), 0.1, 0.4) * 0.25))
    return place(parts)


def sfx_defeat():
    # Sad trombone: four descending notes, the last one wobbling.
    seq = [(0.0, 67, 0.25), (0.28, 66, 0.25), (0.56, 65, 0.25), (0.84, 64, 0.8)]
    parts = []
    for s, n, d in seq:
        sig = pluck(note(n) / 2, d, 'saw', release=d * 0.6, attack=0.03, vib=0.03 if d > 0.5 else 0.008)
        parts.append((s, lowpass(sig, 1500)))
    return place(parts)


def sfx_tap():
    # UI button: short soft pop.
    return sweep(900, 500, 0.06, 'tri') * env(int(SR * 0.06), 0.001, 0.055)


def sfx_buy():
    # Cash register-ish: coin clink then bright confirm.
    clink = sfx_coin()
    confirm = place([(0, pluck(note(79), 0.1, 'square', release=0.09)),
                     (0.08, pluck(note(84), 0.3, 'square', release=0.28))])
    return place([(0, clink * 0.7), (0.12, confirm * 0.6)])


def sfx_star():
    # Star pop on the results screen.
    return place([(0, sweep(note(84), note(96), 0.12, 'tri') * env(int(SR * 0.12), 0.002, 0.1)),
                  (0, highpass(noise(0.2), 5000) * env(int(SR * 0.2), 0.005, 0.18) * 0.3)])


# ---- music -------------------------------------------------------------------------------------

def music_loop():
    """A 16-bar, 120 bpm chiptune loop (32s): bass, chords, lead and drums. Loops seamlessly."""
    bpm = 120
    beat = 60 / bpm
    bars = 16
    total = bars * 4 * beat
    parts = []
    # I - vi - IV - V in C, twice with a lead variation.
    prog = [(48, [60, 64, 67]), (45, [57, 60, 64]), (41, [57, 60, 65]), (43, [59, 62, 67])]
    lead_a = [72, 74, 76, 79, 76, 74, 72, 67]
    lead_b = [76, 79, 81, 79, 76, 74, 76, 72]
    for bar in range(bars):
        root, chord = prog[bar % 4]
        t0 = bar * 4 * beat
        # Bass on each beat, octave jump on the off-beat.
        for b in range(4):
            parts.append((t0 + b * beat, pluck(note(root - 12), beat * 0.45, 'tri', release=beat * 0.4) * 0.9))
            parts.append((t0 + b * beat + beat / 2, pluck(note(root), beat * 0.3, 'tri', release=beat * 0.25) * 0.5))
        # Off-beat chord stabs.
        for b in range(4):
            for n in chord:
                parts.append((t0 + b * beat + beat / 2, pluck(note(n), beat * 0.25, 'square', release=beat * 0.2) * 0.11))
        # Lead: eighth notes, rests on the first half of each 4-bar phrase.
        if bar % 4 >= 2 or bar >= 8:
            line = lead_b if bar >= 8 else lead_a
            for i, n in enumerate(line):
                parts.append((t0 + i * beat / 2, pluck(note(n), beat * 0.45, 'square', release=beat * 0.4, vib=0.003) * 0.22))
        # Drums: kick on 1 and 3, snare on 2 and 4, hats on eighths.
        for b in range(4):
            s = t0 + b * beat
            if b % 2 == 0:
                parts.append((s, sweep(140, 45, 0.15, curve=0.5) * env(int(SR * 0.15), 0.001, 0.14) * 0.9))
            else:
                sn = highpass(noise(0.12), 1500) * env(int(SR * 0.12), 0.001, 0.11) * 0.35
                parts.append((s, sn))
                parts.append((s, sweep(220, 160, 0.08) * env(int(SR * 0.08), 0.001, 0.07) * 0.3))
            for h in (0, 0.5):
                parts.append((s + h * beat, highpass(noise(0.03), 7000) * env(int(SR * 0.03), 0.001, 0.028) * 0.18))
    mix = place(parts, total)
    # Wrap the tail that rings past the loop point back onto the start, so the loop is seamless.
    n = int(total * SR)
    tail = mix[n:]
    mix = mix[:n]
    mix[:len(tail)] += tail
    return mix


def main():
    sfx = {
        'coin': sfx_coin, 'meat': sfx_meat, 'broccoli': sfx_broccoli, 'hit': sfx_hit,
        'shield_block': sfx_shield, 'shield_graze': sfx_shield_graze, 'evolve': sfx_evolve,
        'devolve': sfx_devolve, 'swoosh': sfx_swoosh, 'finish': sfx_finish, 'fight': sfx_fight,
        'victory': sfx_victory, 'defeat': sfx_defeat, 'tap': sfx_tap, 'buy': sfx_buy, 'star': sfx_star,
    }
    for name, fn in sfx.items():
        write(f'sfx/{name}', fn())
    write('music/run_loop', music_loop(), peak=0.7)


if __name__ == '__main__':
    main()
