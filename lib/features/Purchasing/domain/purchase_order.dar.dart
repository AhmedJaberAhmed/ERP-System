import 'package:equatable/equatable.dart';

import 'purchase_item.dart';

enum PurchaseStatus { draft, confirmed, cancelled }

extension PurchaseStatusX on PurchaseStatus {
  String get label => switch (this) {
    PurchaseStatus.draft => 'Draft',
    PurchaseStatus.confirmed => 'Received',
    PurchaseStatus.cancelled => 'Cancelled',
  };
}

class PurchaseOrder extends Equatable {
  const PurchaseOrder({
    required this.id,
    required this.status,
    required this.warehouseId,
    required this.orderDate,
    required this.subtotal,
    required this.taxTotal,
    required this.total,
    this.number,
    this.supplierId,
    this.supplierName,
    this.warehouseName,
    this.note,
    this.items = const [],
  });

  final String id;

  /// Assigned when the order is confirmed.
  final String? number;
  final PurchaseStatus status;
  final String? supplierId;
  final String? supplierName;
  final String warehouseId;
  final String? warehouseName;
  final DateTime orderDate;
  final double subtotal;
  final double taxTotal;
  final double total;
  final String? note;
  final List<PurchaseItem> items;

  bool get isDraft => status == PurchaseStatus.draft;
  bool get isConfirmed => status == PurchaseStatus.confirmed;

  @override
  List<Object?> get props => [
    id, number, status, supplierId, supplierName, warehouseId, warehouseName,
    orderDate, subtotal, taxTotal, total, note, items,
  ];
}