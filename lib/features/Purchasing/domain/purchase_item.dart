import 'package:equatable/equatable.dart';

import '../../../../core/utils/format.dart';

class PurchaseItem extends Equatable {
  const PurchaseItem({
    required this.productId,
    required this.productName,
    required this.sku,
    required this.unit,
    required this.quantity,
    required this.unitCost,
    this.taxRate = 0,
  });

  final String productId;
  final String productName;
  final String sku;
  final String unit;
  final double quantity;
  final double unitCost;

  /// Percentage, copied from the product.
  final double taxRate;

  // Mirrors the SQL: line_total = round(qty * unit_cost, 2)
  double get lineTotal => round2(quantity * unitCost);
  double get taxAmount => round2(lineTotal * taxRate / 100);

  PurchaseItem copyWith({double? quantity, double? unitCost}) => PurchaseItem(
    productId: productId,
    productName: productName,
    sku: sku,
    unit: unit,
    quantity: quantity ?? this.quantity,
    unitCost: unitCost ?? this.unitCost,
    taxRate: taxRate,
  );

  @override
  List<Object?> get props =>
      [productId, productName, sku, unit, quantity, unitCost, taxRate];
}