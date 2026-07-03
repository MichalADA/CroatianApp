import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/dio_client.dart';
import '../../../core/errors/error_mapper.dart';
import '../domain/auth_repository.dart';
import '../domain/entities/auth_user.dart';
import 'auth_api.dart';
import 'models/auth_dtos.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._api);

  final AuthApi _api;

  @override
  Future<String> login({required String identifier, required String password}) async {
    try {
      final res = await _api.login(LoginRequest(identifier: identifier, password: password));
      return res.accessToken;
    } on Object catch (e) {
      throw ErrorMapper.map(e);
    }
  }

  @override
  Future<String> register({
    required String username,
    required String email,
    required String password,
  }) async {
    try {
      final res = await _api.register(
        RegisterRequest(username: username, email: email, password: password),
      );
      return res.accessToken;
    } on Object catch (e) {
      throw ErrorMapper.map(e);
    }
  }

  @override
  Future<AuthUser> currentUser() async {
    try {
      return await _api.me();
    } on Object catch (e) {
      throw ErrorMapper.map(e);
    }
  }
}

final authApiProvider = Provider<AuthApi>((ref) => AuthApi(ref.watch(dioProvider)));

/// Ten provider zastępuje domyślny [authRepositoryProvider]. Uruchamia się
/// automatycznie dzięki `.overrideWith` w [authRepositoryProviders] poniżej,
/// który jest wpięty w `ProviderScope.overrides` w `main.dart`.
final authRepositoryImplProvider = Provider<AuthRepository>(
  (ref) => AuthRepositoryImpl(ref.watch(authApiProvider)),
);

/// Lista override'ów dla `ProviderScope` w main.dart. Trzymamy tu jedną
/// listę — łatwo dodać kolejne repozytoria (rooms, learning, ...).
final authRepositoryOverride = authRepositoryProvider.overrideWith(
  (ref) => ref.watch(authRepositoryImplProvider),
);
