import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/dio_client.dart';
import '../../../core/errors/error_mapper.dart';
import '../domain/entities/verb.dart';
import '../domain/entities/word.dart';
import 'words_api.dart';

class WordsRepository {
  WordsRepository(this._api);

  final WordsApi _api;

  Future<List<Word>> words(int roomId, {String? q, String? category}) async {
    try {
      return await _api.list(roomId, q: q, category: category);
    } on Object catch (e) {
      throw ErrorMapper.map(e);
    }
  }

  Future<List<String>> categories(int roomId) async {
    try {
      return await _api.categories(roomId);
    } on Object catch (e) {
      throw ErrorMapper.map(e);
    }
  }

  Future<List<Verb>> verbs(int roomId, {String? q}) async {
    try {
      return await _api.verbs(roomId, q: q);
    } on Object catch (e) {
      throw ErrorMapper.map(e);
    }
  }
}

final wordsApiProvider = Provider<WordsApi>((ref) => WordsApi(ref.watch(dioProvider)));
final wordsRepositoryProvider =
    Provider<WordsRepository>((ref) => WordsRepository(ref.watch(wordsApiProvider)));

/// Argumenty: roomId + filtry.
typedef WordsQuery = ({int roomId, String? q, String? category});

final wordsProvider = FutureProvider.family<List<Word>, WordsQuery>(
  (ref, args) =>
      ref.watch(wordsRepositoryProvider).words(args.roomId, q: args.q, category: args.category),
);

final wordCategoriesProvider = FutureProvider.family<List<String>, int>(
  (ref, roomId) => ref.watch(wordsRepositoryProvider).categories(roomId),
);

typedef VerbsQuery = ({int roomId, String? q});

final verbsProvider = FutureProvider.family<List<Verb>, VerbsQuery>(
  (ref, args) => ref.watch(wordsRepositoryProvider).verbs(args.roomId, q: args.q),
);
