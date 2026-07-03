import 'package:dio/dio.dart';

import 'failure.dart';

/// Mapuje [DioException] i inne błędy na znormalizowane [Failure] z ładnym
/// komunikatem dla użytkownika. Backend zwraca `{"detail": "..."}` lub
/// listę Pydantic validation errors — obsługujemy oba.
class ErrorMapper {
  const ErrorMapper._();

  static Failure map(Object error) {
    if (error is Failure) return error;
    if (error is DioException) return _fromDio(error);
    return const UnknownFailure();
  }

  static Failure _fromDio(DioException e) {
    // Bez `switch` z exhaustive matching — Dio dorzuca nowe typy między
    // wersjami (np. transformTimeout w 5.10). Domyślnie traktujemy jak
    // problem z odpowiedzią serwera.
    final type = e.type;
    if (type == DioExceptionType.connectionTimeout ||
        type == DioExceptionType.sendTimeout ||
        type == DioExceptionType.receiveTimeout) {
      return const TimeoutFailure();
    }
    if (type == DioExceptionType.connectionError) {
      return const NetworkFailure();
    }
    if (type == DioExceptionType.cancel) {
      return const UnknownFailure('Żądanie anulowane');
    }
    if (type == DioExceptionType.badCertificate) {
      return const NetworkFailure('Niepoprawny certyfikat');
    }
    // badResponse, unknown i wszystkie nowe typy → mapujemy po status code.
    return _fromResponse(e);
  }

  static Failure _fromResponse(DioException e) {
    final status = e.response?.statusCode;
    final detail = _extractDetail(e.response?.data);
    switch (status) {
      case 400:
        return ValidationFailure(detail ?? 'Nieprawidłowe dane');
      case 401:
        return UnauthorizedFailure(detail ?? 'Sesja wygasła — zaloguj się ponownie');
      case 403:
        return UnauthorizedFailure(detail ?? 'Brak dostępu');
      case 404:
        return NotFoundFailure(detail ?? 'Nie znaleziono');
      case 422:
        return ValidationFailure(detail ?? 'Błąd walidacji');
      case 500:
      case 502:
      case 503:
      case 504:
        return ServerFailure(detail ?? 'Błąd serwera');
      default:
        return UnknownFailure(detail ?? e.message ?? 'Coś poszło nie tak');
    }
  }

  static String? _extractDetail(Object? data) {
    if (data is Map<String, dynamic>) {
      final detail = data['detail'];
      if (detail is String) return detail;
      if (detail is List) {
        return detail.map((it) {
          if (it is Map) {
            final loc = (it['loc'] as List?)?.lastOrNull;
            final msg = it['msg'] ?? it['type'] ?? 'błąd';
            return loc == null ? '$msg' : '$loc: $msg';
          }
          return it.toString();
        }).join(' • ');
      }
      if (detail is Map) return detail.toString();
    }
    return null;
  }
}

extension _ListExt<T> on List<T> {
  T? get lastOrNull => isEmpty ? null : last;
}
