import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failure.dart';

import '../domain/purchase_order.dar.dart';
import '../domain/purchase_order_repository.dart';
import 'purchase_orders_state.dart';

class PurchaseOrdersCubit extends Cubit<PurchaseOrdersState> {
  PurchaseOrdersCubit(this._repo, this._companyId)
      : super(const PurchaseOrdersState());

  final PurchaseOrderRepository _repo;
  final String _companyId;

  int _request = 0; // ignore out-of-order responses

  Future<void> load({bool silent = false}) async {
    if (!silent) emit(state.copyWith(status: PurchaseOrdersStatus.loading));
    final id = ++_request;
    try {
      final list = await _repo.getOrders(
        _companyId,
        status: state.statusFilter,
        query: state.query,
      );
      if (id != _request || isClosed) return;
      emit(state.copyWith(status: PurchaseOrdersStatus.loaded, orders: list));
    } on Failure catch (e) {
      if (id != _request || isClosed) return;
      final keep = silent && state.status == PurchaseOrdersStatus.loaded;
      emit(state.copyWith(
        status: keep ? PurchaseOrdersStatus.loaded : PurchaseOrdersStatus.failure,
        errorMessage: e.message,
      ));
    }
  }

  Future<void> search(String query) {
    emit(state.copyWith(query: query.trim()));
    return load(silent: true);
  }

  /// null = all.
  Future<void> filterBy(PurchaseStatus? status) {
    emit(state.copyWith(statusFilter: status));
    return load(silent: true);
  }
}