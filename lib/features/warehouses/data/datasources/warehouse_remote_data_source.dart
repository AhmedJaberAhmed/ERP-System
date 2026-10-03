import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/errors/guard_remote.dart';
import '../../domain/entities/warehouse.dart';
import '../models/warehouse_model.dart';

abstract class WarehouseRemoteDataSource {
  Future<List<Warehouse>> fetch(String companyId, bool activeOnly);
  Future<void> save(String companyId, Warehouse warehouse);
  Future<void> setDefault(String companyId, String warehouseId);
  Future<void> delete(String warehouseId);
}

class WarehouseRemoteDataSourceImpl implements WarehouseRemoteDataSource {
  WarehouseRemoteDataSourceImpl(this._client);

  final SupabaseClient _client;

  @override
  Future<List<Warehouse>> fetch(String companyId, bool activeOnly) =>
      guardRemote(() async {
        var req = _client.from('warehouses').select().eq('company_id', companyId);
        if (activeOnly) req = req.eq('is_active', true);
        final rows = await req.order('is_default', ascending: false).order('name');
        return rows.map(WarehouseModel.fromJson).toList();
      });

  @override
  Future<void> save(String companyId, Warehouse warehouse) =>
      guardRemote(() async {
        try {
          final data = WarehouseModel.toJson(warehouse);
          if (warehouse.isNew) {
            await _client.from('warehouses').insert({...data, 'company_id': companyId});
          } else {
            await _client.from('warehouses').update(data).eq('id', warehouse.id);
          }
        } on PostgrestException catch (e) {
          if (e.code == '23505') {
            throw const Failure('A warehouse with this name already exists.');
          }
          rethrow;
        }
      });

  @override
  Future<void> setDefault(String companyId, String warehouseId) =>
      guardRemote(() async {
        await _client.rpc('set_default_warehouse', params: {
          'p_company': companyId,
          'p_warehouse': warehouseId,
        });
      });

  @override
  Future<void> delete(String warehouseId) => guardRemote(() async {
        try {
          await _client.from('warehouses').delete().eq('id', warehouseId);
        } on PostgrestException catch (e) {
          if (e.code == '23503') {
            throw const Failure(
                'This warehouse has stock history or documents. Deactivate it instead.');
          }
          rethrow;
        }
      });
}
