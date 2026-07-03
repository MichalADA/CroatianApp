import 'package:dio/dio.dart';

import '../domain/entities/room.dart';

class RoomsApi {
  RoomsApi(this._dio);

  final Dio _dio;

  Future<List<Room>> list() async {
    final res = await _dio.get<List<dynamic>>('/rooms');
    return res.data!.cast<Map<String, dynamic>>().map(_normalize).map(Room.fromJson).toList();
  }

  Future<Room> get(int id) async {
    final res = await _dio.get<Map<String, dynamic>>('/rooms/$id');
    return Room.fromJson(_normalize(res.data!));
  }

  Map<String, dynamic> _normalize(Map<String, dynamic> json) => {
        'id': json['id'],
        'name': json['name'],
        'description': json['description'],
        'emoji': json['emoji'],
        'color': json['color'],
        'wordCount': json['word_count'] ?? 0,
        'verbCount': json['verb_count'] ?? 0,
        'knownCount': json['known_count'] ?? 0,
        'dueToday': json['due_today'] ?? 0,
      };
}
