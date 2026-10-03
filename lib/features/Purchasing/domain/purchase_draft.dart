import 'purchase_item.dart';

/// What the editor sends to save a draft purchase order.
class PurchaseDraft {
  const PurchaseDraft({
    required this.orderDate,
    required this.items,
    this.id,
    this.supplierId,
    this.warehouseId,
    this.note,
  });

  /// null = create a new draft, otherwise update that draft.
  final String? id;
  final String? supplierId;

  /// null = the company's default warehouse.
  final String? warehouseId;
  final DateTime orderDate;
  final String? note;
  final List<PurchaseItem> items;
}