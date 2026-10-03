import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/errors/guard_remote.dart';
import '../domain/DashboardSummary.dart';
import 'dashboard_models.dart';

abstract class DashboardRemoteDataSource {
  Future<DashboardData> fetch(String companyId, {required bool includeStock});
}

class DashboardRemoteDataSourceImpl implements DashboardRemoteDataSource {
  DashboardRemoteDataSourceImpl(this._client);

  final SupabaseClient _client;

  Future<Map<String, dynamic>?> _summary(String c) async {
    final row = await _client
        .from('v_dashboard_summary')
        .select()
        .eq('company_id', c)
        .maybeSingle();
    return row;
  }

  Future<List<Map<String, dynamic>>> _daily(String c) async {
    final rows = await _client
        .from('v_sales_daily')
        .select('day, total, invoices')
        .eq('company_id', c)
        .order('day', ascending: true);
    return rows;
  }

  Future<List<Map<String, dynamic>>> _top(String c) async {
    final rows = await _client
        .from('v_top_products')
        .select()
        .eq('company_id', c)
        .order('rnk', ascending: true);
    return rows;
  }

  Future<List<Map<String, dynamic>>> _unpaid(String c) async {
    final rows = await _client
        .from('v_unpaid_invoices')
        .select()
        .eq('company_id', c)
        .order('due_date', ascending: true, nullsFirst: false)
        .limit(5);
    return rows;
  }

  Future<List<Map<String, dynamic>>> _low(String c) async {
    final rows = await _client
        .from('v_low_stock')
        .select()
        .eq('company_id', c)
        .order('quantity', ascending: true)
        .limit(5);
    return rows;
  }

  List<Map<String, dynamic>> _rows(Object? v) =>
      (v as List).map((e) => e as Map<String, dynamic>).toList();

  @override
  Future<DashboardData> fetch(String companyId, {required bool includeStock}) =>
      guardRemote(() async {
        final r = await Future.wait<Object?>([
          _summary(companyId),
          _daily(companyId),
          _top(companyId),
          _unpaid(companyId),
          includeStock
              ? _low(companyId)
              : Future.value(const <Map<String, dynamic>>[]),
        ]);
        return DashboardData(
          summary: DashboardModels.summary(r[0] as Map<String, dynamic>?),
          last7Days: _rows(r[1]).map(DashboardModels.daily).toList(),
          topProducts: _rows(r[2]).map(DashboardModels.top).toList(),
          unpaid: _rows(r[3]).map(DashboardModels.unpaid).toList(),
          lowStock: _rows(r[4]).map(DashboardModels.low).toList(),
        );
      });
}