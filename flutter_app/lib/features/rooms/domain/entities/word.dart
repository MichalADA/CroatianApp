import 'package:freezed_annotation/freezed_annotation.dart';

part 'word.freezed.dart';
part 'word.g.dart';

@freezed
class Word with _$Word {
  const factory Word({
    required int id,
    required int roomId,
    required String targetWord,
    required String polish,
    String? category,
    int? difficulty,
    String? exampleHr,
    String? examplePl,
    @Default('nowe') String status,
    DateTime? nextReview,
  }) = _Word;

  factory Word.fromJson(Map<String, dynamic> json) => _$WordFromJson(json);
}
