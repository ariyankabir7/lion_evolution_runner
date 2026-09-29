import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  SettingsService(this._prefs)
      : sound = ValueNotifier(_prefs.getBool(_kSound) ?? true),
        music = ValueNotifier(_prefs.getBool(_kMusic) ?? true),
        haptics = ValueNotifier(_prefs.getBool(_kHaptics) ?? true) {
    sound.addListener(() => _prefs.setBool(_kSound, sound.value));
    music.addListener(() => _prefs.setBool(_kMusic, music.value));
    haptics.addListener(() => _prefs.setBool(_kHaptics, haptics.value));
  }

  static const _kSound = 'settings.sound';
  static const _kMusic = 'settings.music';
  static const _kHaptics = 'settings.haptics';

  final SharedPreferences _prefs;
  final ValueNotifier<bool> sound;
  final ValueNotifier<bool> music;
  final ValueNotifier<bool> haptics;
}
