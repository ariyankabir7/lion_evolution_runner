import 'package:shared_preferences/shared_preferences.dart';

import 'audio_service.dart';

export 'audio_service.dart' show Sfx;
import 'progress_service.dart';
import 'settings_service.dart';
import 'upgrade_service.dart';
import 'wallet_service.dart';

/// App-wide service locator. Created once in `main()` before `runApp`.
class Services {
  Services._(SharedPreferences prefs)
      : progress = ProgressService(prefs),
        wallet = WalletService(prefs),
        settings = SettingsService(prefs) {
    upgrades = UpgradeService(prefs, wallet);
    audio = AudioService(settings);
  }

  static late final Services instance;

  static Future<void> init() async {
    instance = Services._(await SharedPreferences.getInstance());
  }

  final ProgressService progress;
  final WalletService wallet;
  final SettingsService settings;
  late final UpgradeService upgrades;
  late final AudioService audio;
}

Services get services => Services.instance;
