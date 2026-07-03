import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/domain/auth_repository.dart';
import '../../features/auth/domain/entities/auth_user.dart';
import '../errors/failure.dart';
import '../storage/secure_storage.dart';
import 'auth_state.dart';

/// Centralny controller stanu sesji.
///
/// Odpowiedzialności:
///  - Boot: sprawdź token w SecureStorage, spróbuj `GET /auth/me`, ustaw stan.
///  - Login/Register: deleguje do [AuthRepository], zapisuje token, ładuje usera.
///  - Logout: czyści token i przechodzi w [AuthUnauthenticated].
///  - handleUnauthorized: wywoływane przez interceptor przy 401.
class AuthController extends StateNotifier<AuthState> {
  AuthController({
    required this.storage,
    required this.repository,
  }) : super(const AuthUnknown()) {
    _bootstrap();
  }

  final SecureStorage storage;
  final AuthRepository repository;

  Future<void> _bootstrap() async {
    // Wszystko w jednym try/catch — nie ma opcji zostawić stanu w
    // AuthUnknown, bo router pokazuje wtedy splash w nieskończoność.
    // Głównie chodzi o SecureStorage na web (flutter_secure_storage_web
    // potrafi rzucać PlatformException, jeśli klucz szyfrujący zmienił
    // się między sesjami przeglądarki albo storage jest zablokowany).
    try {
      final token = await storage.readToken();
      if (token == null || token.isEmpty) {
        state = const AuthUnauthenticated();
        return;
      }
      final user = await repository.currentUser();
      state = AuthAuthenticated(user);
    } on UnauthorizedFailure {
      await _clearTokenSafely();
      state = const AuthUnauthenticated();
    } on Failure catch (e) {
      debugPrint('AuthController.bootstrap Failure: ${e.message}');
      state = const AuthUnauthenticated();
    } on Object catch (e, st) {
      // Nieoczekiwane (secure_storage crypto errors na web, kwoty
      // storage itd.) — czyścimy token i idziemy na login.
      debugPrint('AuthController.bootstrap unexpected: $e\n$st');
      await _clearTokenSafely();
      state = const AuthUnauthenticated();
    }
  }

  Future<void> _clearTokenSafely() async {
    try {
      await storage.clearToken();
    } on Object catch (e) {
      debugPrint('SecureStorage.clearToken failed: $e');
    }
  }

  Future<void> login({required String identifier, required String password}) async {
    final token = await repository.login(identifier: identifier, password: password);
    await storage.writeToken(token);
    final user = await repository.currentUser();
    state = AuthAuthenticated(user);
  }

  Future<void> register({
    required String username,
    required String email,
    required String password,
  }) async {
    final token = await repository.register(
      username: username,
      email: email,
      password: password,
    );
    await storage.writeToken(token);
    final user = await repository.currentUser();
    state = AuthAuthenticated(user);
  }

  Future<void> logout() async {
    await storage.clearToken();
    state = const AuthUnauthenticated();
  }

  /// Wywoływane przez interceptor przy 401. Nie robimy tu niczego
  /// asynchronicznego — token już wyczyścił interceptor.
  void handleUnauthorized() {
    if (state is AuthAuthenticated) {
      state = const AuthUnauthenticated(reason: 'Sesja wygasła — zaloguj się ponownie');
    }
  }

  /// Aktualizuje usera po zmianie ustawień/języka — bez re-logowania.
  void updateUser(AuthUser user) {
    if (state is AuthAuthenticated) {
      state = AuthAuthenticated(user);
    }
  }
}

/// Provider [AuthController]. Wymaga override'a [authRepositoryProvider]
/// z feature/auth/data.
final authControllerProvider =
    StateNotifierProvider<AuthController, AuthState>((ref) {
  return AuthController(
    storage: ref.watch(secureStorageProvider),
    repository: ref.watch(authRepositoryProvider),
  );
});
