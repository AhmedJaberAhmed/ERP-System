import 'package:equatable/equatable.dart';

class Product extends Equatable {
  const Product({
    required this.id,
    required this.sku,
    required this.name,
    this.barcode,
    this.categoryId,
    this.unit = 'pcs',
    this.costPrice = 0,
    this.salePrice = 0,
    this.taxRate = 0,
    this.minStock = 0,
    this.trackStock = true,
    this.isActive = true,
  });

  /// Empty id means "not saved yet".
  final String id;
  final String sku;
  final String name;
  final String? barcode;
  final String? categoryId;
  final String unit;
  final double costPrice;
  final double salePrice;
  final double taxRate;
  final double minStock;
  final bool trackStock;
  final bool isActive;

  bool get isNew => id.isEmpty;

  @override
  List<Object?> get props => [
        id, sku, name, barcode, categoryId, unit, costPrice, salePrice,
        taxRate, minStock, trackStock, isActive,
      ];
}
