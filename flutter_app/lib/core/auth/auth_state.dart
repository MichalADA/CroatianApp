import '../../features/auth/domain/entities/auth_user.dart';

/// Sealed hierarchy — router używa `switch` żeby zdecydować, gdzie przekierować.
sealed class AuthState {
  const AuthState();
}

/// Stan startowy — trzymamy splash / loader, dopóki nie sprawdzimy tokena.
class AuthUnknown extends AuthState {
  const AuthUnknown();
}

class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated({this.reason});

  /// Ustawiane, gdy wylogowanie było wymuszone (np. 401 z serwera) —
  /// ekran logowania może to pokazać jako snackbar.
  final String? reason;
}

class AuthAuthenticated extends AuthState {
  const AuthAuthenticated(this.user);

  final AuthUser user;
}
