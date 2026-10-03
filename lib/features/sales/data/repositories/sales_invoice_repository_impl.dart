import '../../domain/entities/invoice_draft.dart';
import '../../domain/entities/sales_invoice.dart';
import '../../domain/repositories/sales_invoice_repository.dart';
import '../datasources/sales_invoice_remote_data_source.dart';

class SalesInvoiceRepositoryImpl implements SalesInvoiceRepository {
  SalesInvoiceRepositoryImpl(this._remote);

  final SalesInvoiceRemoteDataSource _remote;

  @override
  Future<List<SalesInvoice>> getInvoices(
    String companyId, {
    InvoiceStatus? status,
    String query = '',
  }) =>
      _remote.fetchInvoices(companyId, status, query);

  @override
  Future<SalesInvoice> getInvoice(String invoiceId) => _remote.fetchInvoice(invoiceId);

  @override
  Future<String> saveDraft(String companyId, InvoiceDraft draft) =>
      _remote.saveDraft(companyId, draft);

  @override
  Future<void> confirm(String invoiceId) => _remote.confirm(invoiceId);

  @override
  Future<void> cancel(String invoiceId) => _remote.cancel(invoiceId);

  @override
  Future<void> deleteDraft(String invoiceId) => _remote.deleteDraft(invoiceId);

  @override
  Future<void> addPayment({
    required String invoiceId,
    required double amount,
    required PaymentMethod method,
    String? reference,
  }) =>
      _remote.addPayment(
        invoiceId: invoiceId,
        amount: amount,
        method: method,
        reference: reference,
      );
}
