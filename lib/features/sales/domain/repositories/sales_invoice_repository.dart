import '../entities/invoice_draft.dart';
import '../entities/sales_invoice.dart';

abstract class SalesInvoiceRepository {
  /// Newest first. [query] matches the invoice number.
  Future<List<SalesInvoice>> getInvoices(
    String companyId, {
    InvoiceStatus? status,
    String query = '',
  });

  /// With items and payments.
  Future<SalesInvoice> getInvoice(String invoiceId);

  /// Creates or updates a draft atomically. Returns the invoice id.
  Future<String> saveDraft(String companyId, InvoiceDraft draft);

  /// Checks stock, deducts it, assigns the invoice number.
  Future<void> confirm(String invoiceId);

  /// Confirmed + unpaid invoices only. Puts the stock back.
  Future<void> cancel(String invoiceId);

  Future<void> deleteDraft(String invoiceId);

  Future<void> addPayment({
    required String invoiceId,
    required double amount,
    required PaymentMethod method,
    String? reference,
  });
}
