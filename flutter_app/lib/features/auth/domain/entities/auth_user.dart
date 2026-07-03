import 'package:freezed_annotation/freezed_annotation.dart';

part 'auth_user.freezed.dart';
part 'auth_user.g.dart';

/// Zalogowany użytkownik. Immutable entity — cały stan idzie przez [AuthState].
@freezed
class AuthUser with _$AuthUser {
  const factory AuthUser({
    required int id,
    required String username,
    required String email,
    @Default('hr') String selectedLanguage,
    @Default('dark') String theme,
    String? avatar,
    DateTime? createdAt,
  }) = _AuthUser;

  factory AuthUser.fromJson(Map<String, dynamic> json) => _$AuthUserFromJson(json);
}
