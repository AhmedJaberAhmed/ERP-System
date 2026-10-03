import 'package:equatable/equatable.dart';

import '../../domain/entities/customer.dart';

enum CustomersStatus { initial, loading, loaded, failure }

class CustomersState extends Equatable {
  const CustomersState({
    this.status = CustomersStatus.initial,
    this.customers = const [],
    this.query = '',
    this.isBusy = false,
    this.errorMessage,
  });

  final CustomersStatus status;
  final List<Customer> customers;
  final String query;
  final bool isBusy;
  final String? errorMessage;

  /// errorMessage is cleared on every copy unless passed again.
  CustomersState copyWith({
    CustomersStatus? status,
    List<Customer>? customers,
    String? query,
    bool? isBusy,
    String? errorMessage,
  }) =>
      CustomersState(
        status: status ?? this.status,
        customers: customers ?? this.customers,
        query: query ?? this.query,
        isBusy: isBusy ?? this.isBusy,
        errorMessage: errorMessage,
      );

  @override
  List<Object?> get props => [status, customers, query, isBusy, errorMessage];
}
