import 'package:freezed_annotation/freezed_annotation.dart';

part 'verb.freezed.dart';
part 'verb.g.dart';

@freezed
class Verb with _$Verb {
  const factory Verb({
    required int id,
    required int roomId,
    required String infinitive,
    required String polish,
    String? conjJa,
    String? conjTi,
    String? conjOn,
    String? conjMi,
    String? conjVi,
    String? conjOni,
    String? exampleHr,
    String? examplePl,
    @Default('nowe') String status,
    DateTime? nextReview,
  }) = _Verb;

  factory Verb.fromJson(Map<String, dynamic> json) => _$VerbFromJson(json);
}
