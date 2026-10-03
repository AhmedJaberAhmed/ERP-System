import 'package:equatable/equatable.dart';

import '../../domain/entities/sales_invoice.dart';

enum InvoiceDetailStatus { initial, loading, loaded, failure }

class InvoiceDetailState extends Equatable {
  const InvoiceDetailState({
    this.status = InvoiceDetailStatus.initial,
    this.invoice,
    this.isBusy = false,
    this.errorMessage,
  });

  final InvoiceDetailStatus status;
  final SalesInvoice? invoice;
  final bool isBusy;
  final String? errorMessage;

  /// errorMessage is cleared on every copy unless passed again.
  InvoiceDetailState copyWith({
    InvoiceDetailStatus? status,
    SalesInvoice? invoice,
    bool? isBusy,
    String? errorMessage,
  }) =>
      InvoiceDetailState(
        status: status ?? this.status,
        invoice: invoice ?? this.invoice,
        isBusy: isBusy ?? this.isBusy,
        errorMessage: errorMessage,
      );

  @override
  List<Object?> get props => [status, invoice, isBusy, errorMessage];
}
