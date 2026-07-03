import 'package:dio/dio.dart';

import '../domain/entities/verb.dart';
import '../domain/entities/word.dart';

class WordsApi {
  WordsApi(this._dio);

  final Dio _dio;

  Future<List<Word>> list(int roomId, {String? q, String? category}) async {
    final params = <String, dynamic>{};
    if (q != null && q.isNotEmpty) params['q'] = q;
    if (category != null && category != 'wszystkie') params['category'] = category;
    final res = await _dio.get<List<dynamic>>(
      '/rooms/$roomId/words',
      queryParameters: params,
    );
    return res.data!
        .cast<Map<String, dynamic>>()
        .map(_normalizeWord)
        .map(Word.fromJson)
        .toList();
  }

  Future<List<String>> categories(int roomId) async {
    final res = await _dio.get<List<dynamic>>('/rooms/$roomId/words/categories');
    return res.data!.cast<String>();
  }

  Future<List<Verb>> verbs(int roomId, {String? q}) async {
    final params = <String, dynamic>{};
    if (q != null && q.isNotEmpty) params['q'] = q;
    final res = await _dio.get<List<dynamic>>(
      '/rooms/$roomId/verbs',
      queryParameters: params,
    );
    return res.data!
        .cast<Map<String, dynamic>>()
        .map(_normalizeVerb)
        .map(Verb.fromJson)
        .toList();
  }

  Map<String, dynamic> _normalizeWord(Map<String, dynamic> json) => {
        'id': json['id'],
        'roomId': json['room_id'],
        'targetWord': json['croatian'] ?? json['target'] ?? '',
        'polish': json['polish'],
        'category': json['category'],
        'difficulty': json['difficulty'],
        'exampleHr': json['example_hr'],
        'examplePl': json['example_pl'],
        'status': json['status'] ?? 'nowe',
        'nextReview': json['next_review'],
      };

  Map<String, dynamic> _normalizeVerb(Map<String, dynamic> json) => {
        'id': json['id'],
        'roomId': json['room_id'],
        'infinitive': json['infinitive'],
        'polish': json['polish'],
        'conjJa': json['conj_ja'],
        'conjTi': json['conj_ti'],
        'conjOn': json['conj_on'],
        'conjMi': json['conj_mi'],
        'conjVi': json['conj_vi'],
        'conjOni': json['conj_oni'],
        'exampleHr': json['example_hr'],
        'examplePl': json['example_pl'],
        'status': json['status'] ?? 'nowe',
        'nextReview': json['next_review'],
      };
}
