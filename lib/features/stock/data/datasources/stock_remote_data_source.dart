import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/errors/guard_remote.dart';
import '../../domain/entities/stock_item.dart';
import '../../domain/entities/stock_movement.dart';
import '../../domain/entities/warehouse_stock.dart';
import '../models/stock_models.dart';

abstract class StockRemoteDataSource {
  Future<List<StockItem>> getStock(String companyId, String? warehouseId, String query);
  Future<List<WarehouseStock>> getProductStock(String companyId, String productId);
  Future<List<StockMovement>> getMovements(String companyId, String productId, int limit);
  Future<void> adjust({
    required String companyId,
    required String warehouseId,
    required String productId,
    required double delta,
    String? note,
  });
}

class StockRemoteDataSourceImpl implements StockRemoteDataSource {
  StockRemoteDataSourceImpl(this._client);

  final SupabaseClient _client;

  List<Map<String, dynamic>> _rows(dynamic res) =>
      (res as List).map((e) => e as Map<String, dynamic>).toList();

  @override
  Future<List<StockItem>> getStock(
          String companyId, String? warehouseId, String query) =>
      guardRemote(() async {
        final res = await _client.rpc('get_stock', params: {
          'p_company': companyId,
          'p_warehouse': warehouseId,
          'p_search': query,
        });
        return _rows(res).map(StockModels.item).toList();
      });

  @override
  Future<List<WarehouseStock>> getProductStock(String companyId, String productId) =>
      guardRemote(() async {
        final res = await _client.rpc('get_product_stock', params: {
          'p_company': companyId,
          'p_product': productId,
        });
        return _rows(res).map(StockModels.level).toList();
      });

  @override
  Future<List<StockMovement>> getMovements(
          String companyId, String productId, int limit) =>
      guardRemote(() async {
        final res = await _client.rpc('get_product_movements', params: {
          'p_company': companyId,
          'p_product': productId,
          'p_limit': limit,
        });
        return _rows(res).map(StockModels.movement).toList();
      });

  @override
  Future<void> adjust({
    required String companyId,
    required String warehouseId,
    required String productId,
    required double delta,
    String? note,
  }) =>
      guardRemote(() async {
        await _client.rpc('adjust_stock', params: {
          'p_company': companyId,
          'p_warehouse': warehouseId,
          'p_product': productId,
          'p_delta': delta,
          'p_note': note,
        });
      });
}
