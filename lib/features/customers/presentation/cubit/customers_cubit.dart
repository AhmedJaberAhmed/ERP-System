import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failure.dart';
import '../../domain/entities/customer.dart';
import '../../domain/repositories/customer_repository.dart';
import 'customers_state.dart';

class CustomersCubit extends Cubit<CustomersState> {
  CustomersCubit(this._repo, this._companyId) : super(const CustomersState());

  final CustomerRepository _repo;
  final String _companyId;

  int _request = 0; // ignore out-of-order search responses

  Future<void> load({bool silent = false}) async {
    if (!silent) emit(state.copyWith(status: CustomersStatus.loading));
    final id = ++_request;
    try {
      final list = await _repo.search(_companyId, query: state.query);
      if (id != _request || isClosed) return;
      emit(state.copyWith(status: CustomersStatus.loaded, customers: list));
    } on Failure catch (e) {
      if (id != _request || isClosed) return;
      final keep = silent && state.status == CustomersStatus.loaded;
      emit(state.copyWith(
        status: keep ? CustomersStatus.loaded : CustomersStatus.failure,
        errorMessage: e.message,
      ));
    }
  }

  Future<void> search(String query) {
    emit(state.copyWith(query: query.trim()));
    return load(silent: true);
  }

  Future<bool> save(Customer customer) =>
      _run(() => _repo.save(_companyId, customer));

  Future<bool> delete(Customer customer) =>
      _run(() => _repo.delete(customer.id));

  Future<bool> _run(Future<void> Function() action) async {
    emit(state.copyWith(isBusy: true));
    try {
      await action();
      final list = await _repo.search(_companyId, query: state.query);
      emit(state.copyWith(isBusy: false, customers: list));
      return true;
    } on Failure catch (e) {
      emit(state.copyWith(isBusy: false, errorMessage: e.message));
      return false;
    }
  }
}
