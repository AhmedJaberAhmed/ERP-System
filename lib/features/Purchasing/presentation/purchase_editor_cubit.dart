import 'package:erb3/features/Purchasing/presentation/purchase_editor_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failure.dart';
import '../../products/domain/entities/product.dart';
import '../../warehouses/domain/entities/warehouse.dart';
import '../../warehouses/domain/repositories/warehouse_repository.dart';
import '../domain/purchase_draft.dart';
import '../domain/purchase_item.dart';
import '../domain/purchase_order.dar.dart';
import '../domain/purchase_order_repository.dart';


/// ViewModel for creating or editing a DRAFT purchase order.
class PurchaseEditorCubit extends Cubit<PurchaseEditorState> {
  PurchaseEditorCubit(
      this._orders,
      this._warehouses,
      this._companyId, {
        PurchaseOrder? existing,
      })  : _orderId = existing?.id,
        super(_initialState(existing));

  final PurchaseOrderRepository _orders;
  final WarehouseRepository _warehouses;
  final String _companyId;
  final String? _orderId;

  static PurchaseEditorState _initialState(PurchaseOrder? e) {
    if (e == null) {
      final now = DateTime.now();
      return PurchaseEditorState(orderDate: DateTime(now.year, now.month, now.day));
    }
    return PurchaseEditorState(
      warehouseId: e.warehouseId,
      supplierId: e.supplierId,
      supplierName: e.supplierName,
      orderDate: e.orderDate,
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

  void setSupplier(String id, String name) =>
      emit(state.copyWith(supplierId: id, supplierName: name));

  void clearSupplier() => emit(state.copyWith(supplierId: null, supplierName: null));

  void setWarehouse(String? id) => emit(state.copyWith(warehouseId: id));

  void setOrderDate(DateTime d) => emit(state.copyWith(orderDate: d));

  void setNote(String v) => emit(state.copyWith(note: v.trim().isEmpty ? null : v));

  /// Adds one unit at the product's cost price, or +1 if already on the order.
  void addProduct(Product p) {
    final items = [...state.items];
    final i = items.indexWhere((e) => e.productId == p.id);
    if (i >= 0) {
      items[i] = items[i].copyWith(quantity: items[i].quantity + 1);
    } else {
      items.add(PurchaseItem(
        productId: p.id,
        productName: p.name,
        sku: p.sku,
        unit: p.unit,
        quantity: 1,
        unitCost: p.costPrice,
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

  void updateItem(int index, {required double quantity, required double unitCost}) =>
      _replace(index, state.items[index].copyWith(quantity: quantity, unitCost: unitCost));

  void removeItem(int index) {
    final items = [...state.items]..removeAt(index);
    emit(state.copyWith(items: items));
  }

  /// Saves the draft. Returns the order id, or null on failure.
  Future<String?> save() async {
    if (state.items.isEmpty) {
      emit(state.copyWith(errorMessage: 'Add at least one item.'));
      return null;
    }
    emit(state.copyWith(isSaving: true));
    try {
      final id = await _orders.saveDraft(
        _companyId,
        PurchaseDraft(
          id: _orderId,
          supplierId: state.supplierId,
          warehouseId: state.warehouseId,
          orderDate: state.orderDate,
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

  void _replace(int index, PurchaseItem item) {
    final items = [...state.items];
    items[index] = item;
    emit(state.copyWith(items: items));
  }
}