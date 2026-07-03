import 'package:dio/dio.dart';

import '../domain/entities/learning_item.dart';

class LearningApi {
  LearningApi(this._dio);

  final Dio _dio;

  Future<List<LearningItem>> session(int roomId, {int limit = 20, int newLimit = 5}) async {
    final res = await _dio.get<Map<String, dynamic>>(
      '/rooms/$roomId/learning-session',
      queryParameters: {'limit': limit, 'new_limit': newLimit},
    );
    final items = (res.data!['items'] as List).cast<Map<String, dynamic>>();
    return items.map(_normalize).map(LearningItem.fromJson).toList();
  }

  Future<List<LearningItem>> reviews(int roomId) async {
    final res = await _dio.get<Map<String, dynamic>>('/rooms/$roomId/reviews');
    final items = (res.data!['items'] as List).cast<Map<String, dynamic>>();
    return items.map(_normalize).map(LearningItem.fromJson).toList();
  }

  Future<void> submitProgress({
    required String itemType,
    required int itemId,
    required int roomId,
    required ReviewAnswer answer,
  }) async {
    await _dio.post<Map<String, dynamic>>(
      '/progress',
      data: {
        'item_type': itemType,
        'item_id': itemId,
        'room_id': roomId,
        'answer': answer.apiValue,
      },
    );
  }

  Future<void> startLearning({
    required String itemType,
    required int itemId,
    required int roomId,
  }) async {
    await _dio.post<Map<String, dynamic>>(
      '/progress/start',
      data: {
        'item_type': itemType,
        'item_id': itemId,
        'room_id': roomId,
      },
    );
  }

  Map<String, dynamic> _normalize(Map<String, dynamic> json) => {
        'type': json['type'],
        'id': json['id'],
        'targetText': json['croatian'] ?? json['target'] ?? '',
        'polish': json['polish'],
        'category': json['category'],
        'status': json['status'] ?? 'nowe',
        'exampleHr': json['example_hr'],
        'examplePl': json['example_pl'],
        'conjJa': json['conj_ja'],
        'conjTi': json['conj_ti'],
        'conjOn': json['conj_on'],
        'conjMi': json['conj_mi'],
        'conjVi': json['conj_vi'],
        'conjOni': json['conj_oni'],
        'progressId': json['progress_id'],
      };
}
