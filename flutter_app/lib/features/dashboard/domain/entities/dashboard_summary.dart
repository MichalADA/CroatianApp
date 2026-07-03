import 'package:freezed_annotation/freezed_annotation.dart';

part 'dashboard_summary.freezed.dart';
part 'dashboard_summary.g.dart';

@freezed
class RecentSentence with _$RecentSentence {
  const factory RecentSentence({
    required int id,
    required int roomId,
    required String textHr,
    String? textPl,
  }) = _RecentSentence;

  factory RecentSentence.fromJson(Map<String, dynamic> json) =>
      _$RecentSentenceFromJson(json);
}

@freezed
class DashboardSummary with _$DashboardSummary {
  const factory DashboardSummary({
    @Default(0) int totalWords,
    @Default(0) int totalVerbs,
    @Default(0) int known,
    @Default(0) int learning,
    @Default(0) int hard,
    @Default(0) int dueToday,
    @Default([]) List<RecentSentence> recentSentences,
  }) = _DashboardSummary;

  factory DashboardSummary.fromJson(Map<String, dynamic> json) =>
      _$DashboardSummaryFromJson(json);
}
