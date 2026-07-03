import 'package:dio/dio.dart';

import '../domain/entities/language.dart';

class LanguagesApi {
  LanguagesApi(this._dio);

  final Dio _dio;

  Future<List<Language>> list() async {
    final res = await _dio.get<List<dynamic>>('/languages');
    return res.data!
        .cast<Map<String, dynamic>>()
        .map(_normalize)
        .map(Language.fromJson)
        .toList();
  }

  Future<Language> mine() async {
    final res = await _dio.get<Map<String, dynamic>>('/me/language');
    return Language.fromJson(_normalize(res.data!));
  }

  Future<Language> setMine(String code) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/me/language',
      data: {'language': code},
    );
    return Language.fromJson(_normalize(res.data!));
  }

  Map<String, dynamic> _normalize(Map<String, dynamic> json) => {
        'code': json['code'],
        'name': json['name'],
        'title': json['title'],
        'flag': json['flag'],
        'hasContent': json['has_content'] ?? false,
        'isCurrent': json['is_current'] ?? false,
      };
}
