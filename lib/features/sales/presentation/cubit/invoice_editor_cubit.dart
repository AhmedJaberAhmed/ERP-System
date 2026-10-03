import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failure.dart';
import '../../../products/domain/entities/product.dart';
import '../../../products/domain/repositories/product_repository.dart';
import '../../../warehouses/domain/entities/warehouse.dart';
import '../../../warehouses/domain/repositories/warehouse_repository.dart';
import '../../domain/entities/invoice_draft.dart';
import '../../domain/entities/invoice_item.dart';
import '../../domain/entities/sales_invoice.dart';
import '../../domain/repositories/sales_invoice_repository.dart';
import 'invoice_editor_state.dart';

/// ViewModel for creating or editing a DRAFT invoice.
class InvoiceEditorCubit extends Cubit<InvoiceEditorState> {
  InvoiceEditorCubit(
    this._invoices,
    this._warehouses,
    this._products,
    this._companyId, {
    SalesInvoice? existing,
  })  : _invoiceId = existing?.id,
        super(_initialState(existing));

  final SalesInvoiceRepository _invoices;
  final WarehouseRepository _warehouses;
  final ProductRepository _products;
  final String _companyId;
  final String? _invoiceId;

  static InvoiceEditorState _initialState(SalesInvoice? e) {
    if (e == null) {
      final now = DateTime.now();
      return InvoiceEditorState(invoiceDate: DateTime(now.year, now.month, now.day));
    }
    return InvoiceEditorState(
      warehouseId: e.warehouseId,
      customerId: e.customerId,
      customerName: e.customerName,
      invoiceDate: e.invoiceDate,
      dueDate: e.dueDate,
      discount: e.discount,
      note: e.note,
      items: e.items,
    );
  }

  /// Loads the warehouse list. Optional: a role without warehouses.read still
  /// works, the server then uses the default warehouse.
  Future<void> init() async {
    List<Warehouse> list = const [];
    try {
      list = await _warehouses.getWarehouses(_companyId, activeOnly: true);
    } on Failure {
      // ignore
    }
    String? selected = state.warehouseId;
    if (list.isNotEmpty && !list.any((w) => w.id == selected)) {
      final defaults = list.where((w) => w.isDefault);
      selected = (defaults.isNotEmpty ? defaults.first : list.first).id;
    }
    if (!isClosed) {
      emit(state.copyWith(isLoading: false, warehouses: list, warehouseId: selected));
    }
  }

  void setCustomer(String id, String name) =>
      emit(state.copyWith(customerId: id, customerName: name));

  void clearCustomer() => emit(state.copyWith(customerId: null, customerName: null));

  void setWarehouse(String? id) => emit(state.copyWith(warehouseId: id));

  void setInvoiceDate(DateTime d) => emit(state.copyWith(invoiceDate: d));

  /// null clears the due date.
  void setDueDate(DateTime? d) => emit(state.copyWith(dueDate: d));

  void setDiscount(double v) => emit(state.copyWith(discount: v < 0 ? 0 : v));

  void setNote(String v) => emit(state.copyWith(note: v.trim().isEmpty ? null : v));

  /// Adds one unit, or +1 if the product is already on the invoice.
  void addProduct(Product p) {
    final items = [...state.items];
    final i = items.indexWhere((e) => e.productId == p.id);
    if (i >= 0) {
      items[i] = items[i].copyWith(quantity: items[i].quantity + 1);
    } else {
      items.add(InvoiceItem(
        productId: p.id,
        productName: p.name,
        sku: p.sku,
        unit: p.unit,
        quantity: 1,
        unitPrice: p.salePrice,
        taxRate: p.taxRate,
      ));
    }
    emit(state.copyWith(items: items));
  }

  void changeQuantity(int index, double delta) {
    final item = state.items[index];
    final q = item.quantity + delta;
    if (q < 1) return; // use the delete button to remove a line
    _replace(index, item.copyWith(quantity: q));
  }

  void updateItem(
    int index, {
    required double quantity,
    required double unitPrice,
    required double discount,
  }) =>
      _replace(
        index,
        state.items[index].copyWith(
          quantity: quantity,
          unitPrice: unitPrice,
          discount: discount,
        ),
      );

  void removeItem(int index) {
    final items = [...state.items]..removeAt(index);
    emit(state.copyWith(items: items));
  }

  /// Saves the draft. Returns the invoice id, or null on failure.
  Future<String?> save() async {
    if (state.items.isEmpty) {
      emit(state.copyWith(errorMessage: 'Add at least one item.'));
      return null;
    }
    if (state.total < 0) {
      emit(state.copyWith(errorMessage: 'Discount exceeds the invoice total.'));
      return null;
    }
    emit(state.copyWith(isSaving: true));
    try {
      final id = await _invoices.saveDraft(
        _companyId,
        InvoiceDraft(
          id: _invoiceId,
          customerId: state.customerId,
          warehouseId: state.warehouseId,
          invoiceDate: state.invoiceDate,
          dueDate: state.dueDate,
          discount: state.discount,
          note: state.note,
          items: state.items,
        ),
      );
      emit(state.copyWith(isSaving: false));
      return id;
    } on Failure catch (e) {
      emit(state.copyWith(isSaving: false, errorMessage: e.message));
      return null;
    }
  }

  void _replace(int index, InvoiceItem item) {
    final items = [...state.items];
    items[index] = item;
    emit(state.copyWith(items: items));
  }
}
