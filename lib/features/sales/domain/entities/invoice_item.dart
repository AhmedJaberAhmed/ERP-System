import 'package:equatable/equatable.dart';

import '../../../../core/utils/format.dart';

class InvoiceItem extends Equatable {
  const InvoiceItem({
    required this.productId,
    required this.productName,
    required this.sku,
    required this.unit,
    required this.quantity,
    required this.unitPrice,
    this.discount = 0,
    this.taxRate = 0,
  });

  final String productId;
  final String productName;
  final String sku;
  final String unit;
  final double quantity;
  final double unitPrice;

  /// Line discount as an amount (not a percentage).
  final double discount;

  /// Percentage, copied from the product.
  final double taxRate;

  // Mirrors the SQL: line_total = round(qty * price - discount, 2)
  double get lineTotal => round2(quantity * unitPrice - discount);
  double get taxAmount => round2(lineTotal * taxRate / 100);

  InvoiceItem copyWith({double? quantity, double? unitPrice, double? discount}) =>
      InvoiceItem(
        productId: productId,
        productName: productName,
        sku: sku,
        unit: unit,
        quantity: quantity ?? this.quantity,
        unitPrice: unitPrice ?? this.unitPrice,
        discount: discount ?? this.discount,
        taxRate: taxRate,
      );

  @override
  List<Object?> get props =>
      [productId, productName, sku, unit, quantity, unitPrice, discount, taxRate];
}
