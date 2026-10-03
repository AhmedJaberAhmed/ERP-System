import 'package:equatable/equatable.dart';

import '../../../../core/utils/format.dart';
import '../../warehouses/domain/entities/warehouse.dart';
import '../domain/purchase_item.dart';


const Object _unset = Object();

T? _pick<T>(Object? value, T? old) => identical(value, _unset) ? old : value as T?;

class PurchaseEditorState extends Equatable {
  const PurchaseEditorState({
    required this.orderDate,
    this.isLoading = true,
    this.warehouses = const [],
    this.warehouseId,
    this.supplierId,
    this.supplierName,
    this.note,
    this.items = const [],
    this.isSaving = false,
    this.errorMessage,
  });

  final bool isLoading;
  final List<Warehouse> warehouses;

  /// null = server uses the default warehouse.
  final String? warehouseId;
  final String? supplierId;
  final String? supplierName;
  final DateTime orderDate;
  final String? note;
  final List<PurchaseItem> items;
  final bool isSaving;
  final String? errorMessage;

  // Same formulas as the SQL, so the preview matches what gets saved.
  double get subtotal => round2(items.fold(0.0, (s, i) => s + i.lineTotal));
  double get taxTotal => round2(items.fold(0.0, (s, i) => s + i.taxAmount));
  double get total => round2(subtotal + taxTotal);

  /// Nullable fields: leave the argument out to keep the value, pass null to clear it.
  /// errorMessage is cleared on every copy unless passed again.
  PurchaseEditorState copyWith({
    bool? isLoading,
    List<Warehouse>? warehouses,
    Object? warehouseId = _unset,
    Object? supplierId = _unset,
    Object? supplierName = _unset,
    DateTime? orderDate,
    Object? note = _unset,
    List<PurchaseItem>? items,
    bool? isSaving,
    String? errorMessage,
  }) =>
      PurchaseEditorState(
        isLoading: isLoading ?? this.isLoading,
        warehouses: warehouses ?? this.warehouses,
        warehouseId: _pick<String>(warehouseId, this.warehouseId),
        supplierId: _pick<String>(supplierId, this.supplierId),
        supplierName: _pick<String>(supplierName, this.supplierName),
        orderDate: orderDate ?? this.orderDate,
        note: _pick<String>(note, this.note),
        items: items ?? this.items,
        isSaving: isSaving ?? this.isSaving,
        errorMessage: errorMessage,
      );

  @override
  List<Object?> get props => [
    isLoading, warehouses, warehouseId, supplierId, supplierName, orderDate,
    note, items, isSaving, errorMessage,
  ];
}