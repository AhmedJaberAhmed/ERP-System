import '../../domain/entities/product.dart';
import '../../domain/entities/product_category.dart';

double _d(dynamic v) => v == null ? 0 : (v as num).toDouble();

class ProductModel {
  ProductModel._();

  static Product fromJson(Map<String, dynamic> j) => Product(
        id: j['id'] as String,
        sku: j['sku'] as String,
        name: j['name'] as String,
        barcode: j['barcode'] as String?,
        categoryId: j['category_id'] as String?,
        unit: (j['unit'] as String?) ?? 'pcs',
        costPrice: _d(j['cost_price']),
        salePrice: _d(j['sale_price']),
        taxRate: _d(j['tax_rate']),
        minStock: _d(j['min_stock']),
        trackStock: (j['track_stock'] as bool?) ?? true,
        isActive: (j['is_active'] as bool?) ?? true,
      );

  static Map<String, dynamic> toJson(Product p) => {
        'sku': p.sku,
        'name': p.name,
        'barcode': p.barcode,
        'category_id': p.categoryId,
        'unit': p.unit,
        'cost_price': p.costPrice,
        'sale_price': p.salePrice,
        'tax_rate': p.taxRate,
        'min_stock': p.minStock,
        'track_stock': p.trackStock,
        'is_active': p.isActive,
      };

  static ProductCategory categoryFromJson(Map<String, dynamic> j) =>
      ProductCategory(id: j['id'] as String, name: j['name'] as String);
}
