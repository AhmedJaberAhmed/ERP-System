import '../../../../core/utils/format.dart';
import '../domain/purchase_item.dart';
import '../domain/purchase_order.dar.dart';


class PurchaseOrderModel {
  PurchaseOrderModel._();

  static PurchaseStatus _status(String v) => PurchaseStatus.values.firstWhere(
        (s) => s.name == v,
    orElse: () => PurchaseStatus.draft,
  );

  static PurchaseItem _item(Map<String, dynamic> j) {
    final product = (j['products'] as Map<String, dynamic>?) ?? const {};
    return PurchaseItem(
      productId: j['product_id'] as String,
      productName: (product['name'] as String?) ?? '',
      sku: (product['sku'] as String?) ?? '',
      unit: (product['unit'] as String?) ?? 'pcs',
      quantity: asDouble(j['quantity']),
      unitCost: asDouble(j['unit_cost']),
      taxRate: asDouble(j['tax_rate']),
    );
  }

  /// Works for both list rows (no items) and detail rows (with items).
  static PurchaseOrder fromJson(Map<String, dynamic> j) {
    final items = (j['purchase_order_items'] as List?) ?? const [];
    final supplier = j['suppliers'] as Map<String, dynamic>?;
    final warehouse = j['warehouses'] as Map<String, dynamic>?;
    return PurchaseOrder(
      id: j['id'] as String,
      number: j['number'] as String?,
      status: _status(j['status'] as String),
      supplierId: j['supplier_id'] as String?,
      supplierName: supplier?['name'] as String?,
      warehouseId: j['warehouse_id'] as String,
      warehouseName: warehouse?['name'] as String?,
      orderDate: DateTime.parse(j['order_date'] as String),
      subtotal: asDouble(j['subtotal']),
      taxTotal: asDouble(j['tax_total']),
      total: asDouble(j['total']),
      note: j['note'] as String?,
      items: items.map((e) => _item(e as Map<String, dynamic>)).toList(),
    );
  }
}