import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failure.dart';
import '../../../warehouses/domain/repositories/warehouse_repository.dart';
import '../../domain/repositories/stock_repository.dart';
import 'stock_state.dart';

class StockCubit extends Cubit<StockState> {
  StockCubit(this._stock, this._warehouses, this._companyId)
      : super(const StockState());

  final StockRepository _stock;
  final WarehouseRepository _warehouses;
  final String _companyId;

  int _request = 0; // ignore out-of-order responses

  Future<void> load({bool silent = false}) async {
    if (!silent) emit(state.copyWith(status: StockStatus.loading));
    final id = ++_request;
    try {
      final items = await _stock.getStock(
        _companyId,
        warehouseId: state.warehouseId,
        query: state.query,
      );
      if (id != _request || isClosed) return;
      emit(state.copyWith(status: StockStatus.loaded, items: items));
      _loadWarehousesOnce();
    } on Failure catch (e) {
      if (id != _request || isClosed) return;
      final keep = silent && state.status == StockStatus.loaded;
      emit(state.copyWith(
        status: keep ? StockStatus.loaded : StockStatus.failure,
        errorMessage: e.message,
      ));
    }
  }

  Future<void> search(String query) {
    emit(state.copyWith(query: query.trim()));
    return load(silent: true);
  }

  Future<void> selectWarehouse(String? warehouseId) {
    emit(state.copyWith(warehouseId: warehouseId));
    return load(silent: true);
  }

  void toggleLowOnly() => emit(state.copyWith(lowOnly: !state.lowOnly));

  // The warehouse filter is optional: a role without warehouses.read still works.
  Future<void> _loadWarehousesOnce() async {
    if (state.warehouses.isNotEmpty) return;
    try {
      final list = await _warehouses.getWarehouses(_companyId, activeOnly: true);
      if (!isClosed) emit(state.copyWith(warehouses: list));
    } on Failure {
      // ignore
    }
  }
}
