import 'package:equatable/equatable.dart';

import '../../domain/entities/warehouse.dart';

enum WarehousesStatus { initial, loading, loaded, failure }

class WarehousesState extends Equatable {
  const WarehousesState({
    this.status = WarehousesStatus.initial,
    this.warehouses = const [],
    this.isBusy = false,
    this.errorMessage,
  });

  final WarehousesStatus status;
  final List<Warehouse> warehouses;
  final bool isBusy;
  final String? errorMessage;

  /// errorMessage is cleared on every copy unless passed again.
  WarehousesState copyWith({
    WarehousesStatus? status,
    List<Warehouse>? warehouses,
    bool? isBusy,
    String? errorMessage,
  }) =>
      WarehousesState(
        status: status ?? this.status,
        warehouses: warehouses ?? this.warehouses,
        isBusy: isBusy ?? this.isBusy,
        errorMessage: errorMessage,
      );

  @override
  List<Object?> get props => [status, warehouses, isBusy, errorMessage];
}
