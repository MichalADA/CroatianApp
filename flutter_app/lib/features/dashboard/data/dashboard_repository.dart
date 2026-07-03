import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/dio_client.dart';
import '../../../core/errors/error_mapper.dart';
import '../domain/entities/dashboard_summary.dart';
import 'dashboard_api.dart';

class DashboardRepository {
  DashboardRepository(this._api);

  final DashboardApi _api;

  Future<DashboardSummary> summary() async {
    try {
      return await _api.summary();
    } on Object catch (e) {
      throw ErrorMapper.map(e);
    }
  }
}

final dashboardApiProvider =
    Provider<DashboardApi>((ref) => DashboardApi(ref.watch(dioProvider)));

final dashboardRepositoryProvider = Provider<DashboardRepository>(
  (ref) => DashboardRepository(ref.watch(dashboardApiProvider)),
);

final dashboardSummaryProvider = FutureProvider<DashboardSummary>(
  (ref) => ref.watch(dashboardRepositoryProvider).summary(),
);
