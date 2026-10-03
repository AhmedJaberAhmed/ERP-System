import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failure.dart';

import '../domain/supplier.dart';
import '../domain/supplier_repository.dart';
import 'suppliers_state.dart';

class SuppliersCubit extends Cubit<SuppliersState> {
  SuppliersCubit(this._repo, this._companyId) : super(const SuppliersState());

  final SupplierRepository _repo;
  final String _companyId;

  int _request = 0; // ignore out-of-order search responses

  Future<void> load({bool silent = false}) async {
    if (!silent) emit(state.copyWith(status: SuppliersStatus.loading));
    final id = ++_request;
    try {
      final list = await _repo.search(_companyId, query: state.query);
      if (id != _request || isClosed) return;
      emit(state.copyWith(status: SuppliersStatus.loaded, suppliers: list));
    } on Failure catch (e) {
      if (id != _request || isClosed) return;
      final keep = silent && state.status == SuppliersStatus.loaded;
      emit(state.copyWith(
        status: keep ? SuppliersStatus.loaded : SuppliersStatus.failure,
        errorMessage: e.message,
      ));
    }
  }

  Future<void> search(String query) {
    emit(state.copyWith(query: query.trim()));
    return load(silent: true);
  }

  Future<bool> save(Supplier supplier) =>
      _run(() => _repo.save(_companyId, supplier));

  Future<bool> delete(Supplier supplier) =>
      _run(() => _repo.delete(supplier.id));

  Future<bool> _run(Future<void> Function() action) async {
    emit(state.copyWith(isBusy: true));
    try {
      await action();
      final list = await _repo.search(_companyId, query: state.query);
      emit(state.copyWith(isBusy: false, suppliers: list));
      return true;
    } on Failure catch (e) {
      emit(state.copyWith(isBusy: false, errorMessage: e.message));
      return false;
    }
  }
}