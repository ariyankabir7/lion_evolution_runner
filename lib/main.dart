import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app.dart';
import 'core/services/services.dart';
import 'data/level_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  await Future.wait([Services.init(), LevelRepository.init()]);
  unawaited(services.audio.init()); // loads in the background; SFX are silent until ready
  runApp(const LionApp());
}
