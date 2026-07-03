import 'package:dio/dio.dart';

import '../domain/entities/dashboard_summary.dart';

class DashboardApi {
  DashboardApi(this._dio);

  final Dio _dio;

  Future<DashboardSummary> summary() async {
    final res = await _dio.get<Map<String, dynamic>>('/dashboard');
    return DashboardSummary.fromJson(_normalize(res.data!));
  }

  Map<String, dynamic> _normalize(Map<String, dynamic> json) => {
        'totalWords': json['total_words'] ?? 0,
        'totalVerbs': json['total_verbs'] ?? 0,
        'known': json['known'] ?? 0,
        'learning': json['learning'] ?? 0,
        'hard': json['hard'] ?? 0,
        'dueToday': json['due_today'] ?? 0,
        'recentSentences': ((json['recent_sentences'] as List?) ?? [])
            .cast<Map<String, dynamic>>()
            .map((s) => {
                  'id': s['id'],
                  'roomId': s['room_id'],
                  'textHr': s['text_hr'],
                  'textPl': s['text_pl'],
                })
            .toList(),
      };
}
