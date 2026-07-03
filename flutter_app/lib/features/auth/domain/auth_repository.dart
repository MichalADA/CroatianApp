import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'entities/auth_user.dart';

/// Kontrakt na repozytorium autoryzacji — implementacja żyje w `data/`.
/// Provider domyślnie rzuca — override w [authRepositoryImplProvider] w
/// data/auth_repository_impl.dart podpina konkretną implementację.
abstract interface class AuthRepository {
  /// Zwraca `access_token`.
  Future<String> login({required String identifier, required String password});

  /// Zwraca `access_token` nowego konta.
  Future<String> register({
    required String username,
    required String email,
    required String password,
  });

  /// `GET /auth/me` — używa aktualnego tokena z SecureStorage (interceptor).
  Future<AuthUser> currentUser();
}

/// Provider — musi zostać nadpisany przez [authRepositoryImplProvider]
/// (jest to robione automatycznie przez `data/auth_repository_impl.dart`
/// dzięki `ProviderScope`'a global override w main lub .overrideWith na
/// providerze). Domyślna implementacja jest importowana w providerze
/// w impl-file — tam robimy definicję finalną.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  throw UnimplementedError(
    'authRepositoryProvider nie jest nadpisany. Sprawdź, czy '
    'authRepositoryImplProvider jest importowany w main.dart',
  );
});
