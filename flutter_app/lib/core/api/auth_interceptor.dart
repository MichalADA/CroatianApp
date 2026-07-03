import 'package:dio/dio.dart';

import '../storage/secure_storage.dart';

/// Callback wywoływany, gdy interceptor wykryje 401 na dowolnym żądaniu.
/// Podpięty jest do [AuthController] w [DioClient] — czyści token i wysyła
/// aplikację do ekranu logowania.
typedef OnUnauthorized = void Function();

/// - Docleja `Authorization: Bearer <token>` jeśli token jest w [SecureStorage].
/// - Na 401 czyści token i wywołuje [onUnauthorized] (router przekieruje na login).
class AuthInterceptor extends Interceptor {
  AuthInterceptor({
    required this.storage,
    required this.onUnauthorized,
  });

  final SecureStorage storage;
  final OnUnauthorized onUnauthorized;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await storage.readToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode == 401) {
      await storage.clearToken();
      onUnauthorized();
    }
    handler.next(err);
  }
}
