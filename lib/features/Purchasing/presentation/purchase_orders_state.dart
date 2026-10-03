import 'package:equatable/equatable.dart';

import '../domain/purchase_order.dar.dart';


enum PurchaseOrdersStatus { initial, loading, loaded, failure }

const Object _unset = Object();

class PurchaseOrdersState extends Equatable {
  const PurchaseOrdersState({
    this.status = PurchaseOrdersStatus.initial,
    this.orders = const [],
    this.statusFilter,
    this.query = '',
    this.errorMessage,
  });

  final PurchaseOrdersStatus status;
  final List<PurchaseOrder> orders;

  /// null = all statuses.
  final PurchaseStatus? statusFilter;
  final String query;
  final String? errorMessage;

  /// errorMessage is cleared on every copy unless passed again.
  PurchaseOrdersState copyWith({
    PurchaseOrdersStatus? status,
    List<PurchaseOrder>? orders,
    Object? statusFilter = _unset,
    String? query,
    String? errorMessage,
  }) =>
      PurchaseOrdersState(
        status: status ?? this.status,
        orders: orders ?? this.orders,
        statusFilter: identical(statusFilter, _unset)
            ? this.statusFilter
            : statusFilter as PurchaseStatus?,
        query: query ?? this.query,
        errorMessage: errorMessage,
      );

  @override
  List<Object?> get props => [status, orders, statusFilter, query, errorMessage];
}