import 'package:freezed_annotation/freezed_annotation.dart';

part 'learning_item.freezed.dart';
part 'learning_item.g.dart';

/// Karta w sesji nauki lub powtórki — może być słowem albo czasownikiem.
/// Backend zwraca oba typy w jednej kolejce (`items`).
@freezed
class LearningItem with _$LearningItem {
  const factory LearningItem({
    required String type, // 'word' | 'verb'
    required int id,
    required String targetText,
    required String polish,
    String? category,
    @Default('nowe') String status,
    String? exampleHr,
    String? examplePl,
    // Verb-only:
    String? conjJa,
    String? conjTi,
    String? conjOn,
    String? conjMi,
    String? conjVi,
    String? conjOni,
    int? progressId,
  }) = _LearningItem;

  factory LearningItem.fromJson(Map<String, dynamic> json) =>
      _$LearningItemFromJson(json);
}

extension LearningItemX on LearningItem {
  bool get isVerb => type == 'verb';
  bool get isWord => type == 'word';
  bool get hasConjugations => isVerb && (conjJa ?? '').isNotEmpty;
}

enum ReviewAnswer { nieWiem, prawie, wiem }

extension ReviewAnswerX on ReviewAnswer {
  String get apiValue => switch (this) {
        ReviewAnswer.nieWiem => 'nie wiem',
        ReviewAnswer.prawie => 'prawie',
        ReviewAnswer.wiem => 'wiem',
      };

  String get label => switch (this) {
        ReviewAnswer.nieWiem => 'Nie wiem',
        ReviewAnswer.prawie => 'Prawie',
        ReviewAnswer.wiem => 'Wiem',
      };
}
