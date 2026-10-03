import 'package:equatable/equatable.dart';

import '../domain/purchase_order.dar.dart';


enum PurchaseDetailStatus { initial, loading, loaded, failure }

class PurchaseDetailState extends Equatable {
  const PurchaseDetailState({
    this.status = PurchaseDetailStatus.initial,
    this.order,
    this.isBusy = false,
    this.errorMessage,
  });

  final PurchaseDetailStatus status;
  final PurchaseOrder? order;
  final bool isBusy;
  final String? errorMessage;

  /// errorMessage is cleared on every copy unless passed again.
  PurchaseDetailState copyWith({
    PurchaseDetailStatus? status,
    PurchaseOrder? order,
    bool? isBusy,
    String? errorMessage,
  }) =>
      PurchaseDetailState(
        status: status ?? this.status,
        order: order ?? this.order,
        isBusy: isBusy ?? this.isBusy,
        errorMessage: errorMessage,
      );

  @override
  List<Object?> get props => [status, order, isBusy, errorMessage];
}