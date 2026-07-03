import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/dio_client.dart';
import '../../../core/errors/error_mapper.dart';
import '../domain/entities/language.dart';
import 'languages_api.dart';

class LanguagesRepository {
  LanguagesRepository(this._api);

  final LanguagesApi _api;

  Future<List<Language>> list() async {
    try {
      return await _api.list();
    } on Object catch (e) {
      throw ErrorMapper.map(e);
    }
  }

  Future<Language> setMine(String code) async {
    try {
      return await _api.setMine(code);
    } on Object catch (e) {
      throw ErrorMapper.map(e);
    }
  }
}

final languagesApiProvider = Provider<LanguagesApi>(
  (ref) => LanguagesApi(ref.watch(dioProvider)),
);

final languagesRepositoryProvider = Provider<LanguagesRepository>(
  (ref) => LanguagesRepository(ref.watch(languagesApiProvider)),
);

/// AsyncValue z listą języków — konsumowany przez language switcher.
final languagesListProvider = FutureProvider<List<Language>>(
  (ref) => ref.watch(languagesRepositoryProvider).list(),
);
