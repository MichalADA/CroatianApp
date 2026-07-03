import 'package:dio/dio.dart';

import '../domain/entities/auth_user.dart';
import 'models/auth_dtos.dart';

/// Cienka warstwa nad Dio — jedno miejsce, gdzie żyją endpointy auth.
/// Nie mapuje błędów (to robi repository → ErrorMapper).
class AuthApi {
  AuthApi(this._dio);

  final Dio _dio;

  Future<TokenResponse> login(LoginRequest req) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/auth/login',
      data: req.toJson(),
    );
    return TokenResponse.fromJson(res.data!);
  }

  Future<TokenResponse> register(RegisterRequest req) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/auth/register',
      data: req.toJson(),
    );
    return TokenResponse.fromJson(res.data!);
  }

  Future<AuthUser> me() async {
    final res = await _dio.get<Map<String, dynamic>>('/auth/me');
    return AuthUser.fromJson(_normalizeUser(res.data!));
  }

  Future<AuthUser> updateSettings(SettingsUpdateRequest req) async {
    final res = await _dio.patch<Map<String, dynamic>>(
      '/me/settings',
      data: req.toJson(includeNulls: false),
    );
    return AuthUser.fromJson(_normalizeUser(res.data!));
  }

  /// Backend zwraca `selected_language` / `created_at` — mapujemy na
  /// camelCase, którego oczekuje freezed.
  Map<String, dynamic> _normalizeUser(Map<String, dynamic> json) {
    return {
      'id': json['id'],
      'username': json['username'],
      'email': json['email'],
      'selectedLanguage': json['selected_language'] ?? 'hr',
      'theme': json['theme'] ?? 'dark',
      'avatar': json['avatar'],
      'createdAt': json['created_at'],
    };
  }
}

extension _SettingsToJson on SettingsUpdateRequest {
  Map<String, dynamic> toJson({bool includeNulls = false}) {
    final json = <String, dynamic>{};
    if (theme != null || includeNulls) json['theme'] = theme;
    if (avatar != null || includeNulls) json['avatar'] = avatar;
    return json;
  }
}
