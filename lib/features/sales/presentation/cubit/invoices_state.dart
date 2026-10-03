import 'package:equatable/equatable.dart';

import '../../domain/entities/sales_invoice.dart';

enum InvoicesStatus { initial, loading, loaded, failure }

const Object _unset = Object();

class InvoicesState extends Equatable {
  const InvoicesState({
    this.status = InvoicesStatus.initial,
    this.invoices = const [],
    this.statusFilter,
    this.query = '',
    this.errorMessage,
  });

  final InvoicesStatus status;
  final List<SalesInvoice> invoices;

  /// null = all statuses.
  final InvoiceStatus? statusFilter;
  final String query;
  final String? errorMessage;

  /// errorMessage is cleared on every copy unless passed again.
  InvoicesState copyWith({
    InvoicesStatus? status,
    List<SalesInvoice>? invoices,
    Object? statusFilter = _unset,
    String? query,
    String? errorMessage,
  }) =>
      InvoicesState(
        status: status ?? this.status,
        invoices: invoices ?? this.invoices,
        statusFilter: identical(statusFilter, _unset)
            ? this.statusFilter
            : statusFilter as InvoiceStatus?,
        query: query ?? this.query,
        errorMessage: errorMessage,
      );

  @override
  List<Object?> get props => [status, invoices, statusFilter, query, errorMessage];
}
