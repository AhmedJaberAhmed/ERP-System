import 'package:equatable/equatable.dart';

import '../domain/supplier.dart';


enum SuppliersStatus { initial, loading, loaded, failure }

class SuppliersState extends Equatable {
  const SuppliersState({
    this.status = SuppliersStatus.initial,
    this.suppliers = const [],
    this.query = '',
    this.isBusy = false,
    this.errorMessage,
  });

  final SuppliersStatus status;
  final List<Supplier> suppliers;
  final String query;
  final bool isBusy;
  final String? errorMessage;

  /// errorMessage is cleared on every copy unless passed again.
  SuppliersState copyWith({
    SuppliersStatus? status,
    List<Supplier>? suppliers,
    String? query,
    bool? isBusy,
    String? errorMessage,
  }) =>
      SuppliersState(
        status: status ?? this.status,
        suppliers: suppliers ?? this.suppliers,
        query: query ?? this.query,
        isBusy: isBusy ?? this.isBusy,
        errorMessage: errorMessage,
      );

  @override
  List<Object?> get props => [status, suppliers, query, isBusy, errorMessage];
}