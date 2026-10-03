import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failure.dart';
import '../../domain/repositories/stock_repository.dart';
import 'stock_detail_state.dart';

class StockDetailCubit extends Cubit<StockDetailState> {
  StockDetailCubit(
    this._repo,
    this._companyId,
    this._productId, {
    required this.canViewMovements,
  }) : super(const StockDetailState());

  final StockRepository _repo;
  final String _companyId;
  final String _productId;

  /// Movements need stock_movements.read; skip the call when the role lacks it.
  final bool canViewMovements;

  Future<void> load({bool silent = false}) async {
    if (!silent) emit(state.copyWith(status: StockDetailStatus.loading));
    try {
      final levels = await _repo.getProductStock(_companyId, _productId);
      final movements = canViewMovements
          ? await _repo.getMovements(_companyId, _productId)
          : state.movements;
      emit(StockDetailState(
        status: StockDetailStatus.loaded,
        levels: levels,
        movements: movements,
      ));
    } on Failure catch (e) {
      final keep = silent && state.status == StockDetailStatus.loaded;
      emit(state.copyWith(
        status: keep ? StockDetailStatus.loaded : StockDetailStatus.failure,
        errorMessage: e.message,
      ));
    }
  }

  /// [delta] > 0 adds stock, < 0 removes it.
  Future<bool> adjust({
    required String warehouseId,
    required double delta,
    String? note,
  }) async {
    emit(state.copyWith(isBusy: true));
    try {
      await _repo.adjust(
        companyId: _companyId,
        warehouseId: warehouseId,
        productId: _productId,
        delta: delta,
        note: note,
      );
      final levels = await _repo.getProductStock(_companyId, _productId);
      final movements = canViewMovements
          ? await _repo.getMovements(_companyId, _productId)
          : state.movements;
      emit(state.copyWith(isBusy: false, levels: levels, movements: movements));
      return true;
    } on Failure catch (e) {
      emit(state.copyWith(isBusy: false, errorMessage: e.message));
      return false;
    }
  }
}
