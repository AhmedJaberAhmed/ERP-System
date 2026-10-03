import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failure.dart';
import '../../domain/entities/sales_invoice.dart';
import '../../domain/repositories/sales_invoice_repository.dart';
import 'invoice_detail_state.dart';

/// ViewModel for one invoice: confirm, cancel, delete, payments.
class InvoiceDetailCubit extends Cubit<InvoiceDetailState> {
  InvoiceDetailCubit(this._repo, this._invoiceId) : super(const InvoiceDetailState());

  final SalesInvoiceRepository _repo;
  final String _invoiceId;

  Future<void> load({bool silent = false}) async {
    if (!silent) emit(state.copyWith(status: InvoiceDetailStatus.loading));
    try {
      final invoice = await _repo.getInvoice(_invoiceId);
      emit(state.copyWith(status: InvoiceDetailStatus.loaded, invoice: invoice));
    } on Failure catch (e) {
      final keep = silent && state.status == InvoiceDetailStatus.loaded;
      emit(state.copyWith(
        status: keep ? InvoiceDetailStatus.loaded : InvoiceDetailStatus.failure,
        errorMessage: e.message,
      ));
    }
  }

  Future<bool> confirm() => _run(() => _repo.confirm(_invoiceId));

  Future<bool> cancel() => _run(() => _repo.cancel(_invoiceId));

  Future<bool> addPayment({
    required double amount,
    required PaymentMethod method,
    String? reference,
  }) =>
      _run(() => _repo.addPayment(
            invoiceId: _invoiceId,
            amount: amount,
            method: method,
            reference: reference,
          ));

  /// Returns true when the draft was deleted (the page should close).
  Future<bool> deleteDraft() async {
    emit(state.copyWith(isBusy: true));
    try {
      await _repo.deleteDraft(_invoiceId);
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
      final invoice = await _repo.getInvoice(_invoiceId);
      emit(state.copyWith(isBusy: false, invoice: invoice));
      return true;
    } on Failure catch (e) {
      emit(state.copyWith(isBusy: false, errorMessage: e.message));
      return false;
    }
  }
}
