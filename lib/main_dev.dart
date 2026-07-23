import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'core/config/app_config.dart';
import 'core/di/service_locator.dart' as di;
import 'firebase_options.dart';
import 'main.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  AppConfig.initialize(
    environment: Environment.dev,
    apiBaseUrl: 'https://api-dev.workspace.com/v1/tasks',
  );

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    // ignore: avoid_print
    print('Firebase initialization failed (expected if config is missing): $e');
  }

  await di.init();

  runApp(const MyApp());
}
