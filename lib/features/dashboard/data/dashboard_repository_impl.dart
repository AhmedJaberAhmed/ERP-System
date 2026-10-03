

import '../domain/DashboardSummary.dart';
import '../domain/dashboard_repository.dart';
import 'dashboard_remote_data_source.dart';

class DashboardRepositoryImpl implements DashboardRepository {
  DashboardRepositoryImpl(this._remote);

  final DashboardRemoteDataSource _remote;

  @override
  Future<DashboardData> getDashboard(String companyId, {bool includeStock = true}) =>
      _remote.fetch(companyId, includeStock: includeStock);
}