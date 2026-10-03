import '../entities/stock_item.dart';
import '../entities/stock_movement.dart';
import '../entities/warehouse_stock.dart';

abstract class StockRepository {
  /// Tracked, active products with their quantity. Missing stock rows count as 0.
  Future<List<StockItem>> getStock(
    String companyId, {
    String? warehouseId,
    String query = '',
  });

  /// Quantity of one product in every active warehouse.
  Future<List<WarehouseStock>> getProductStock(String companyId, String productId);

  Future<List<StockMovement>> getMovements(
    String companyId,
    String productId, {
    int limit = 30,
  });

  /// [delta] > 0 adds stock, < 0 removes it (never below zero).
  Future<void> adjust({
    required String companyId,
    required String warehouseId,
    required String productId,
    required double delta,
    String? note,
  });
}
