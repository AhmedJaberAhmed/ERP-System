import 'package:equatable/equatable.dart';

import '../../../warehouses/domain/entities/warehouse.dart';
import '../../domain/entities/stock_item.dart';

enum StockStatus { initial, loading, loaded, failure }

const Object _unset = Object();

class StockState extends Equatable {
  const StockState({
    this.status = StockStatus.initial,
    this.items = const [],
    this.warehouses = const [],
    this.warehouseId,
    this.query = '',
    this.lowOnly = false,
    this.errorMessage,
  });

  final StockStatus status;
  final List<StockItem> items;
  final List<Warehouse> warehouses;

  /// null = all warehouses.
  final String? warehouseId;
  final String query;
  final bool lowOnly;
  final String? errorMessage;

  int get lowCount => items.where((i) => i.isLow).length;

  List<StockItem> get visibleItems =>
      lowOnly ? items.where((i) => i.isLow).toList() : items;

  /// errorMessage is cleared on every copy unless passed again.
  StockState copyWith({
    StockStatus? status,
    List<StockItem>? items,
    List<Warehouse>? warehouses,
    Object? warehouseId = _unset,
    String? query,
    bool? lowOnly,
    String? errorMessage,
  }) =>
      StockState(
        status: status ?? this.status,
        items: items ?? this.items,
        warehouses: warehouses ?? this.warehouses,
        warehouseId:
            identical(warehouseId, _unset) ? this.warehouseId : warehouseId as String?,
        query: query ?? this.query,
        lowOnly: lowOnly ?? this.lowOnly,
        errorMessage: errorMessage,
      );

  @override
  List<Object?> get props =>
      [status, items, warehouses, warehouseId, query, lowOnly, errorMessage];
}
