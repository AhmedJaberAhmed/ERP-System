
import 'DashboardSummary.dart';

abstract class DashboardRepository {
  /// [includeStock] = false skips the low-stock list (user can't read stock).
  Future<DashboardData> getDashboard(String companyId, {bool includeStock = true});
}