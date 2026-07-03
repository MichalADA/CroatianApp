import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/dio_client.dart';
import '../../../core/errors/error_mapper.dart';
import '../domain/entities/sentence.dart';

class SentencesRepository {
  SentencesRepository(this._dio);

  final Dio _dio;

  Future<List<Sentence>> list(int roomId) async {
    try {
      final res = await _dio.get<List<dynamic>>('/rooms/$roomId/sentences');
      return res.data!.cast<Map<String, dynamic>>().map(_normalize).map(Sentence.fromJson).toList();
    } on Object catch (e) {
      throw ErrorMapper.map(e);
    }
  }

  Future<Sentence> create({
    required int roomId,
    required String textHr,
    String? textPl,
    String? note,
    String status = 'do sprawdzenia',
  }) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '/sentences',
        data: {
          'room_id': roomId,
          'text_hr': textHr,
          'text_pl': textPl,
          'note': note,
          'status': status,
        },
      );
      return Sentence.fromJson(_normalize(res.data!));
    } on Object catch (e) {
      throw ErrorMapper.map(e);
    }
  }

  Future<void> delete(int id) async {
    try {
      await _dio.delete<Map<String, dynamic>>('/sentences/$id');
    } on Object catch (e) {
      throw ErrorMapper.map(e);
    }
  }

  Map<String, dynamic> _normalize(Map<String, dynamic> json) => {
        'id': json['id'],
        'roomId': json['room_id'],
        'textHr': json['text_hr'],
        'textPl': json['text_pl'],
        'note': json['note'],
        'status': json['status'] ?? 'do sprawdzenia',
        'createdAt': json['created_at'],
      };
}

final sentencesRepositoryProvider = Provider<SentencesRepository>(
  (ref) => SentencesRepository(ref.watch(dioProvider)),
);

final sentencesProvider = FutureProvider.family<List<Sentence>, int>(
  (ref, roomId) => ref.watch(sentencesRepositoryProvider).list(roomId),
);
