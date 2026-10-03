import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failure.dart';
import '../../domain/entities/warehouse.dart';
import '../../domain/repositories/warehouse_repository.dart';
import 'warehouses_state.dart';

class WarehousesCubit extends Cubit<WarehousesState> {
  WarehousesCubit(this._repo, this._companyId) : super(const WarehousesState());

  final WarehouseRepository _repo;
  final String _companyId;

  Future<void> load({bool silent = false}) async {
    if (!silent) emit(state.copyWith(status: WarehousesStatus.loading));
    try {
      final list = await _repo.getWarehouses(_companyId);
      emit(state.copyWith(status: WarehousesStatus.loaded, warehouses: list));
    } on Failure catch (e) {
      final keep = silent && state.status == WarehousesStatus.loaded;
      emit(state.copyWith(
        status: keep ? WarehousesStatus.loaded : WarehousesStatus.failure,
        errorMessage: e.message,
      ));
    }
  }

  Future<bool> save(Warehouse warehouse) =>
      _run(() => _repo.save(_companyId, warehouse));

  Future<bool> setDefault(Warehouse warehouse) =>
      _run(() => _repo.setDefault(_companyId, warehouse.id));

  Future<bool> delete(Warehouse warehouse) => _run(() => _repo.delete(warehouse.id));

  Future<bool> _run(Future<void> Function() action) async {
    emit(state.copyWith(isBusy: true));
    try {
      await action();
      final list = await _repo.getWarehouses(_companyId);
      emit(state.copyWith(isBusy: false, warehouses: list));
      return true;
    } on Failure catch (e) {
      emit(state.copyWith(isBusy: false, errorMessage: e.message));
      return false;
    }
  }
}
