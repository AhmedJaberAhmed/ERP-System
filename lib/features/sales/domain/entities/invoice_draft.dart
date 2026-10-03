import 'invoice_item.dart';

/// What the editor sends to save a draft invoice.
class InvoiceDraft {
  const InvoiceDraft({
    required this.invoiceDate,
    required this.discount,
    required this.items,
    this.id,
    this.customerId,
    this.warehouseId,
    this.dueDate,
    this.note,
  });

  /// null = create a new draft, otherwise update that draft.
  final String? id;
  final String? customerId;

  /// null = the company's default warehouse.
  final String? warehouseId;
  final DateTime invoiceDate;
  final DateTime? dueDate;
  final double discount;
  final String? note;
  final List<InvoiceItem> items;
}
