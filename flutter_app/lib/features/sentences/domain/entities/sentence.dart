import 'package:freezed_annotation/freezed_annotation.dart';

part 'sentence.freezed.dart';
part 'sentence.g.dart';

@freezed
class Sentence with _$Sentence {
  const factory Sentence({
    required int id,
    required int roomId,
    required String textHr,
    String? textPl,
    String? note,
    @Default('do sprawdzenia') String status,
    DateTime? createdAt,
  }) = _Sentence;

  factory Sentence.fromJson(Map<String, dynamic> json) => _$SentenceFromJson(json);
}
