import '../../../../core/utils/format.dart';
import '../../domain/entities/stock_item.dart';
import '../../domain/entities/stock_movement.dart';
import '../../domain/entities/warehouse_stock.dart';

class StockModels {
  StockModels._();

  static StockItem item(Map<String, dynamic> j) => StockItem(
        productId: j['product_id'] as String,
        sku: j['sku'] as String,
        name: j['name'] as String,
        unit: (j['unit'] as String?) ?? 'pcs',
        minStock: asDouble(j['min_stock']),
        quantity: asDouble(j['quantity']),
        isLow: (j['is_low'] as bool?) ?? false,
      );

  static WarehouseStock level(Map<String, dynamic> j) => WarehouseStock(
        warehouseId: j['warehouse_id'] as String,
        warehouseName: j['warehouse_name'] as String,
        quantity: asDouble(j['quantity']),
      );

  static StockMovement movement(Map<String, dynamic> j) => StockMovement(
        id: j['id'] as String,
        type: j['type'] as String,
        quantity: asDouble(j['quantity']),
        createdAt: DateTime.parse(j['created_at'] as String).toLocal(),
        warehouseName: (j['warehouse_name'] as String?) ?? '',
        note: j['note'] as String?,
      );
}
