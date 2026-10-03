import '../../domain/entities/stock_item.dart';
import '../../domain/entities/stock_movement.dart';
import '../../domain/entities/warehouse_stock.dart';
import '../../domain/repositories/stock_repository.dart';
import '../datasources/stock_remote_data_source.dart';

class StockRepositoryImpl implements StockRepository {
  StockRepositoryImpl(this._remote);

  final StockRemoteDataSource _remote;

  @override
  Future<List<StockItem>> getStock(
    String companyId, {
    String? warehouseId,
    String query = '',
  }) =>
      _remote.getStock(companyId, warehouseId, query);

  @override
  Future<List<WarehouseStock>> getProductStock(String companyId, String productId) =>
      _remote.getProductStock(companyId, productId);

  @override
  Future<List<StockMovement>> getMovements(
    String companyId,
    String productId, {
    int limit = 30,
  }) =>
      _remote.getMovements(companyId, productId, limit);

  @override
  Future<void> adjust({
    required String companyId,
    required String warehouseId,
    required String productId,
    required double delta,
    String? note,
  }) =>
      _remote.adjust(
        companyId: companyId,
        warehouseId: warehouseId,
        productId: productId,
        delta: delta,
        note: note,
      );
}
