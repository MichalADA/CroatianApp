import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/dio_client.dart';
import '../../../core/errors/error_mapper.dart';
import '../domain/entities/learning_item.dart';
import 'learning_api.dart';

class LearningRepository {
  LearningRepository(this._api);

  final LearningApi _api;

  Future<List<LearningItem>> session(int roomId) async {
    try {
      return await _api.session(roomId);
    } on Object catch (e) {
      throw ErrorMapper.map(e);
    }
  }

  Future<List<LearningItem>> reviews(int roomId) async {
    try {
      return await _api.reviews(roomId);
    } on Object catch (e) {
      throw ErrorMapper.map(e);
    }
  }

  Future<void> submitAnswer({
    required LearningItem item,
    required int roomId,
    required ReviewAnswer answer,
  }) async {
    try {
      await _api.submitProgress(
        itemType: item.type,
        itemId: item.id,
        roomId: roomId,
        answer: answer,
      );
    } on Object catch (e) {
      throw ErrorMapper.map(e);
    }
  }
}

final learningApiProvider =
    Provider<LearningApi>((ref) => LearningApi(ref.watch(dioProvider)));
final learningRepositoryProvider = Provider<LearningRepository>(
  (ref) => LearningRepository(ref.watch(learningApiProvider)),
);
