import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failure.dart';
 import '../domain/purchase_order_repository.dart';
import 'purchase_detail_state.dart';

/// ViewModel for one purchase order: confirm, cancel, delete.
class PurchaseDetailCubit extends Cubit<PurchaseDetailState> {
  PurchaseDetailCubit(this._repo, this._orderId)
      : super(const PurchaseDetailState());

  final PurchaseOrderRepository _repo;
  final String _orderId;

  Future<void> load({bool silent = false}) async {
    if (!silent) emit(state.copyWith(status: PurchaseDetailStatus.loading));
    try {
      final order = await _repo.getOrder(_orderId);
      emit(state.copyWith(status: PurchaseDetailStatus.loaded, order: order));
    } on Failure catch (e) {
      final keep = silent && state.status == PurchaseDetailStatus.loaded;
      emit(state.copyWith(
        status: keep ? PurchaseDetailStatus.loaded : PurchaseDetailStatus.failure,
        errorMessage: e.message,
      ));
    }
  }

  Future<bool> confirm() => _run(() => _repo.confirm(_orderId));

  Future<bool> cancel() => _run(() => _repo.cancel(_orderId));

  /// Returns true when the draft was deleted (the page should close).
  Future<bool> deleteDraft() async {
    emit(state.copyWith(isBusy: true));
    try {
      await _repo.deleteDraft(_orderId);
      emit(state.copyWith(isBusy: false));
      return true;
    } on Failure catch (e) {
      emit(state.copyWith(isBusy: false, errorMessage: e.message));
      return false;
    }
  }

  Future<bool> _run(Future<void> Function() action) async {
    emit(state.copyWith(isBusy: true));
    try {
      await action();
      final order = await _repo.getOrder(_orderId);
      emit(state.copyWith(isBusy: false, order: order));
      return true;
    } on Failure catch (e) {
      emit(state.copyWith(isBusy: false, errorMessage: e.message));
      return false;
    }
  }
}