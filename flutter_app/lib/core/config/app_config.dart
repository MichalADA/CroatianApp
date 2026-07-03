import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';

/// Konfiguracja aplikacji ładowana z compile-time defines.
///
/// Przekazuj wartości przez `--dart-define`:
/// ```
/// flutter run --dart-define=API_BASE_URL=http://localhost:8000
/// ```
class AppConfig {
  const AppConfig._({
    required this.apiBaseUrl,
    required this.appName,
    required this.appVersion,
  });

  final String apiBaseUrl;
  final String appName;
  final String appVersion;

  static const String _envApiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );

  static const String _envAppName = String.fromEnvironment(
    'APP_NAME',
    defaultValue: 'Memory Palace',
  );

  static const String _envAppVersion = String.fromEnvironment(
    'APP_VERSION',
    defaultValue: '1.0.0',
  );

  /// Fabryka wybierająca sensowny domyślny host jeśli nie podano.
  ///
  /// - Android emulator → `10.0.2.2` (mapowany host)
  /// - iOS symulator / desktop / web → `localhost`
  factory AppConfig.fromEnv() {
    final baseUrl = _envApiBaseUrl.isNotEmpty ? _envApiBaseUrl : _defaultBaseUrl();
    return AppConfig._(
      apiBaseUrl: baseUrl,
      appName: _envAppName,
      appVersion: _envAppVersion,
    );
  }

  static String _defaultBaseUrl() {
    if (kIsWeb) return 'http://localhost:8000';
    try {
      if (Platform.isAndroid) return 'http://10.0.2.2:8000';
    } on Object {
      // Platform nie działa na web; kIsWeb wyżej to załatwia.
    }
    return 'http://localhost:8000';
  }

  bool get isDev => kDebugMode;
}
