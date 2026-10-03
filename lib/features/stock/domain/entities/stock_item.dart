import 'package:equatable/equatable.dart';

/// Stock of one product (all warehouses, or the selected one).
class StockItem extends Equatable {
  const StockItem({
    required this.productId,
    required this.sku,
    required this.name,
    required this.unit,
    required this.minStock,
    required this.quantity,
    required this.isLow,
  });

  final String productId;
  final String sku;
  final String name;
  final String unit;
  final double minStock;
  final double quantity;

  /// quantity <= minStock (only when minStock > 0).
  final bool isLow;

  @override
  List<Object?> get props => [productId, sku, name, unit, minStock, quantity, isLow];
}
