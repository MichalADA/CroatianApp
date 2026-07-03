import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_controller.dart';
import '../config/app_config.dart';
import '../storage/secure_storage.dart';
import 'auth_interceptor.dart';

/// Provider Dio z podpiętymi interceptorami. Widok/repo zawsze pobierają
/// klienta stąd — nigdy nie tworzą własnego. Dzięki temu jest jedno miejsce
/// do zmiany base URL, timeoutów, logowania i obsługi 401.
final dioProvider = Provider<Dio>((ref) {
  final config = AppConfig.fromEnv();
  final storage = ref.watch(secureStorageProvider);

  final dio = Dio(
    BaseOptions(
      baseUrl: config.apiBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 20),
      sendTimeout: const Duration(seconds: 20),
      responseType: ResponseType.json,
      headers: {
        'Accept': 'application/json',
      },
    ),
  );

  dio.interceptors.add(
    AuthInterceptor(
      storage: storage,
      onUnauthorized: () {
        // AuthController zna cały stan — wywołuje logout, który
        // przekaże aplikację na ekran logowania (przez router).
        ref.read(authControllerProvider.notifier).handleUnauthorized();
      },
    ),
  );

  if (kDebugMode) {
    dio.interceptors.add(
      LogInterceptor(
        request: false,
        requestHeader: false,
        requestBody: false,
        responseHeader: false,
        responseBody: false,
        error: true,
      ),
    );
  }

  return dio;
});
