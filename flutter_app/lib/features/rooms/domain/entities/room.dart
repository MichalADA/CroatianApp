import 'package:freezed_annotation/freezed_annotation.dart';

part 'room.freezed.dart';
part 'room.g.dart';

@freezed
class Room with _$Room {
  const factory Room({
    required int id,
    required String name,
    String? description,
    String? emoji,
    String? color,
    @Default(0) int wordCount,
    @Default(0) int verbCount,
    @Default(0) int knownCount,
    @Default(0) int dueToday,
  }) = _Room;

  factory Room.fromJson(Map<String, dynamic> json) => _$RoomFromJson(json);
}

extension RoomX on Room {
  int get totalItems => wordCount + verbCount;
  bool get isCompleted => totalItems > 0 && knownCount >= totalItems;
  double get progressRatio => totalItems == 0 ? 0 : knownCount / totalItems;
}
