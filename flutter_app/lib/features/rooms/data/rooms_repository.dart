import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/dio_client.dart';
import '../../../core/errors/error_mapper.dart';
import '../domain/entities/room.dart';
import 'rooms_api.dart';

class RoomsRepository {
  RoomsRepository(this._api);

  final RoomsApi _api;

  Future<List<Room>> list() async {
    try {
      return await _api.list();
    } on Object catch (e) {
      throw ErrorMapper.map(e);
    }
  }

  Future<Room> get(int id) async {
    try {
      return await _api.get(id);
    } on Object catch (e) {
      throw ErrorMapper.map(e);
    }
  }
}

final roomsApiProvider = Provider<RoomsApi>((ref) => RoomsApi(ref.watch(dioProvider)));
final roomsRepositoryProvider =
    Provider<RoomsRepository>((ref) => RoomsRepository(ref.watch(roomsApiProvider)));

final roomsListProvider =
    FutureProvider<List<Room>>((ref) => ref.watch(roomsRepositoryProvider).list());

final roomByIdProvider = FutureProvider.family<Room, int>(
  (ref, id) => ref.watch(roomsRepositoryProvider).get(id),
);

/// Wylicza zbiór ID pokoi zablokowanych — pokój jest zablokowany, jeśli
/// jakikolwiek pokój o mniejszym ID nie jest ukończony. Wyjątek: user 'test'.
final lockedRoomsProvider = Provider.family<Set<int>, ({List<Room> rooms, String username})>(
  (ref, args) {
    if (args.username == 'test') return const {};
    final sorted = [...args.rooms]..sort((a, b) => a.id.compareTo(b.id));
    final locked = <int>{};
    var unlockNext = true;
    for (final r in sorted) {
      if (!unlockNext) locked.add(r.id);
      if (!r.isCompleted) unlockNext = false;
    }
    return locked;
  },
);
