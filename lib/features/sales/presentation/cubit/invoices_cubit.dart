import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failure.dart';
import '../../domain/entities/sales_invoice.dart';
import '../../domain/repositories/sales_invoice_repository.dart';
import 'invoices_state.dart';

/// ViewModel for the invoice list.
class InvoicesCubit extends Cubit<InvoicesState> {
  InvoicesCubit(this._repo, this._companyId) : super(const InvoicesState());

  final SalesInvoiceRepository _repo;
  final String _companyId;

  int _request = 0; // ignore out-of-order responses

  Future<void> load({bool silent = false}) async {
    if (!silent) emit(state.copyWith(status: InvoicesStatus.loading));
    final id = ++_request;
    try {
      final list = await _repo.getInvoices(
        _companyId,
        status: state.statusFilter,
        query: state.query,
      );
      if (id != _request || isClosed) return;
      emit(state.copyWith(status: InvoicesStatus.loaded, invoices: list));
    } on Failure catch (e) {
      if (id != _request || isClosed) return;
      final keep = silent && state.status == InvoicesStatus.loaded;
      emit(state.copyWith(
        status: keep ? InvoicesStatus.loaded : InvoicesStatus.failure,
        errorMessage: e.message,
      ));
    }
  }

  Future<void> search(String query) {
    emit(state.copyWith(query: query.trim()));
    return load(silent: true);
  }

  /// null = all.
  Future<void> filterBy(InvoiceStatus? status) {
    emit(state.copyWith(statusFilter: status));
    return load(silent: true);
  }
}
