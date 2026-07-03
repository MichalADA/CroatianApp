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
    final token = await storage.readToken();
    if (token == null || token.isEmpty) {
      state = const AuthUnauthenticated();
      return;
    }
    try {
      final user = await repository.currentUser();
      state = AuthAuthenticated(user);
    } on UnauthorizedFailure {
      await storage.clearToken();
      state = const AuthUnauthenticated();
    } on Failure catch (e) {
      // Sieć padła — traktujemy jak niezalogowanego, ale nie kasujemy tokena
      // (może user wróci online i zadziała).
      debugPrint('AuthController.bootstrap failed: ${e.message}');
      state = const AuthUnauthenticated();
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
