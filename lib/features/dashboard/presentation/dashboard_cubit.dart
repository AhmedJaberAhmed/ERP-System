import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failure.dart';
 import '../domain/dashboard_repository.dart';
import 'dashboard_state.dart';

class DashboardCubit extends Cubit<DashboardState> {
  DashboardCubit(this._repo, this._companyId, {required this.includeStock})
      : super(const DashboardState());

  final DashboardRepository _repo;
  final String _companyId;
  final bool includeStock;

  Future<void> load({bool silent = false}) async {
    if (!silent) emit(state.copyWith(status: DashboardStatus.loading));
    try {
      final data = await _repo.getDashboard(_companyId, includeStock: includeStock);
      if (isClosed) return;
      emit(state.copyWith(status: DashboardStatus.loaded, data: data));
    } on Failure catch (e) {
      if (isClosed) return;
      final keep = silent && state.status == DashboardStatus.loaded;
      emit(state.copyWith(
        status: keep ? DashboardStatus.loaded : DashboardStatus.failure,
        errorMessage: e.message,
      ));
    }
  }
}