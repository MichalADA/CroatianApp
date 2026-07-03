/// Znormalizowany błąd domenowy — używany przez repozytoria, providery i UI.
///
/// Zamiast wyrzucać [DioException] w warstwę UI, mapujemy błędy przez
/// [ErrorMapper] do jednego z tych typów. Dzięki temu prezentacja może się
/// zdecydować, co pokazać, bez wiedzy o transporcie.
sealed class Failure implements Exception {
  const Failure(this.message);

  final String message;

  @override
  String toString() => 'Failure($runtimeType): $message';
}

class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'Brak połączenia z serwerem']);
}

class TimeoutFailure extends Failure {
  const TimeoutFailure([super.message = 'Serwer nie odpowiada']);
}

class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure([super.message = 'Sesja wygasła — zaloguj się ponownie']);
}

class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}

class NotFoundFailure extends Failure {
  const NotFoundFailure([super.message = 'Nie znaleziono zasobu']);
}

class ServerFailure extends Failure {
  const ServerFailure([super.message = 'Błąd serwera']);
}

class UnknownFailure extends Failure {
  const UnknownFailure([super.message = 'Coś poszło nie tak']);
}
