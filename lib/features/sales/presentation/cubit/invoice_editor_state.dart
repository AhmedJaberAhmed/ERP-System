import 'package:equatable/equatable.dart';

import '../../../../core/utils/format.dart';
import '../../../warehouses/domain/entities/warehouse.dart';
import '../../domain/entities/invoice_item.dart';

const Object _unset = Object();

T? _pick<T>(Object? value, T? old) => identical(value, _unset) ? old : value as T?;

class InvoiceEditorState extends Equatable {
  const InvoiceEditorState({
    required this.invoiceDate,
    this.isLoading = true,
    this.warehouses = const [],
    this.warehouseId,
    this.customerId,
    this.customerName,
    this.dueDate,
    this.discount = 0,
    this.note,
    this.items = const [],
    this.isSaving = false,
    this.errorMessage,
  });

  final bool isLoading;
  final List<Warehouse> warehouses;

  /// null = server uses the default warehouse.
  final String? warehouseId;
  final String? customerId;
  final String? customerName;
  final DateTime invoiceDate;
  final DateTime? dueDate;
  final double discount;
  final String? note;
  final List<InvoiceItem> items;
  final bool isSaving;
  final String? errorMessage;

  // Same formulas as the SQL, so the preview matches what gets saved.
  double get subtotal => round2(items.fold(0.0, (s, i) => s + i.lineTotal));
  double get taxTotal => round2(items.fold(0.0, (s, i) => s + i.taxAmount));
  double get total => round2(subtotal - discount + taxTotal);

  /// Nullable fields: leave the argument out to keep the value, pass null to clear it.
  /// errorMessage is cleared on every copy unless passed again.
  InvoiceEditorState copyWith({
    bool? isLoading,
    List<Warehouse>? warehouses,
    Object? warehouseId = _unset,
    Object? customerId = _unset,
    Object? customerName = _unset,
    DateTime? invoiceDate,
    Object? dueDate = _unset,
    double? discount,
    Object? note = _unset,
    List<InvoiceItem>? items,
    bool? isSaving,
    String? errorMessage,
  }) =>
      InvoiceEditorState(
        isLoading: isLoading ?? this.isLoading,
        warehouses: warehouses ?? this.warehouses,
        warehouseId: _pick<String>(warehouseId, this.warehouseId),
        customerId: _pick<String>(customerId, this.customerId),
        customerName: _pick<String>(customerName, this.customerName),
        invoiceDate: invoiceDate ?? this.invoiceDate,
        dueDate: _pick<DateTime>(dueDate, this.dueDate),
        discount: discount ?? this.discount,
        note: _pick<String>(note, this.note),
        items: items ?? this.items,
        isSaving: isSaving ?? this.isSaving,
        errorMessage: errorMessage,
      );

  @override
  List<Object?> get props => [
        isLoading, warehouses, warehouseId, customerId, customerName, invoiceDate,
        dueDate, discount, note, items, isSaving, errorMessage,
      ];
}
