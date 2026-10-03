import 'package:equatable/equatable.dart';

import '../../domain/entities/stock_movement.dart';
import '../../domain/entities/warehouse_stock.dart';

enum StockDetailStatus { initial, loading, loaded, failure }

class StockDetailState extends Equatable {
  const StockDetailState({
    this.status = StockDetailStatus.initial,
    this.levels = const [],
    this.movements = const [],
    this.isBusy = false,
    this.errorMessage,
  });

  final StockDetailStatus status;
  final List<WarehouseStock> levels;
  final List<StockMovement> movements;
  final bool isBusy;
  final String? errorMessage;

  double get total => levels.fold(0, (sum, l) => sum + l.quantity);

  /// errorMessage is cleared on every copy unless passed again.
  StockDetailState copyWith({
    StockDetailStatus? status,
    List<WarehouseStock>? levels,
    List<StockMovement>? movements,
    bool? isBusy,
    String? errorMessage,
  }) =>
      StockDetailState(
        status: status ?? this.status,
        levels: levels ?? this.levels,
        movements: movements ?? this.movements,
        isBusy: isBusy ?? this.isBusy,
        errorMessage: errorMessage,
      );

  @override
  List<Object?> get props => [status, levels, movements, isBusy, errorMessage];
}
