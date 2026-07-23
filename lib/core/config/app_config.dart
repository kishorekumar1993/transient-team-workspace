import 'package:flutter/foundation.dart';

enum Environment { dev, prod }

class AppConfig {
  final Environment environment;
  final String apiBaseUrl;

  AppConfig({required this.environment, required this.apiBaseUrl});

  static AppConfig? _instance;

  static void initialize({
    required Environment environment,
    required String apiBaseUrl,
  }) {
    _instance = AppConfig(environment: environment, apiBaseUrl: apiBaseUrl);
  }

  static AppConfig get instance {
    if (_instance == null) {
      // Fallback configuration if run directly without main_xxx entrypoints
      return AppConfig(
        environment: Environment.dev,
        apiBaseUrl: 'https://api.workspace.com/v1/tasks',
      );
    }
    return _instance!;
  }

  static bool get isDev => instance.environment == Environment.dev;
  static bool get isProd => instance.environment == Environment.prod;
}
