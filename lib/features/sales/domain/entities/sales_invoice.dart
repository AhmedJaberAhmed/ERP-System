import 'package:equatable/equatable.dart';

import 'invoice_item.dart';

enum InvoiceStatus { draft, confirmed, cancelled }

enum PaymentStatus { unpaid, partial, paid }

enum PaymentMethod { cash, card, bankTransfer, wallet, cheque }

extension InvoiceStatusX on InvoiceStatus {
  String get label => switch (this) {
        InvoiceStatus.draft => 'Draft',
        InvoiceStatus.confirmed => 'Confirmed',
        InvoiceStatus.cancelled => 'Cancelled',
      };
}

extension PaymentStatusX on PaymentStatus {
  String get label => switch (this) {
        PaymentStatus.unpaid => 'Unpaid',
        PaymentStatus.partial => 'Partial',
        PaymentStatus.paid => 'Paid',
      };
}

extension PaymentMethodX on PaymentMethod {
  String get label => switch (this) {
        PaymentMethod.cash => 'Cash',
        PaymentMethod.card => 'Card',
        PaymentMethod.bankTransfer => 'Bank transfer',
        PaymentMethod.wallet => 'Wallet',
        PaymentMethod.cheque => 'Cheque',
      };

  /// Value of the `payment_method` enum in Postgres.
  String get dbValue => switch (this) {
        PaymentMethod.cash => 'cash',
        PaymentMethod.card => 'card',
        PaymentMethod.bankTransfer => 'bank_transfer',
        PaymentMethod.wallet => 'wallet',
        PaymentMethod.cheque => 'cheque',
      };
}

class InvoicePayment extends Equatable {
  const InvoicePayment({
    required this.id,
    required this.amount,
    required this.method,
    required this.paidAt,
    this.reference,
  });

  final String id;
  final double amount;
  final PaymentMethod method;
  final DateTime paidAt;
  final String? reference;

  @override
  List<Object?> get props => [id, amount, method, paidAt, reference];
}

class SalesInvoice extends Equatable {
  const SalesInvoice({
    required this.id,
    required this.status,
    required this.payStatus,
    required this.warehouseId,
    required this.invoiceDate,
    required this.subtotal,
    required this.discount,
    required this.taxTotal,
    required this.total,
    required this.paidAmount,
    this.number,
    this.customerId,
    this.customerName,
    this.warehouseName,
    this.dueDate,
    this.note,
    this.items = const [],
    this.payments = const [],
  });

  final String id;

  /// Assigned when the invoice is confirmed.
  final String? number;
  final InvoiceStatus status;
  final PaymentStatus payStatus;
  final String? customerId;
  final String? customerName;
  final String warehouseId;
  final String? warehouseName;
  final DateTime invoiceDate;
  final DateTime? dueDate;
  final double subtotal;
  final double discount;
  final double taxTotal;
  final double total;
  final double paidAmount;
  final String? note;
  final List<InvoiceItem> items;
  final List<InvoicePayment> payments;

  bool get isDraft => status == InvoiceStatus.draft;
  bool get isConfirmed => status == InvoiceStatus.confirmed;
  double get balance => total - paidAmount;

  @override
  List<Object?> get props => [
        id, number, status, payStatus, customerId, customerName, warehouseId,
        warehouseName, invoiceDate, dueDate, subtotal, discount, taxTotal, total,
        paidAmount, note, items, payments,
      ];
}
