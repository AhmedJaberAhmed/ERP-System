import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/errors/guard_remote.dart';
import '../../../../core/utils/format.dart';
import '../../../../core/utils/search_filter.dart';
import '../../domain/entities/invoice_draft.dart';
import '../../domain/entities/sales_invoice.dart';
import '../models/sales_invoice_model.dart';

abstract class SalesInvoiceRemoteDataSource {
  Future<List<SalesInvoice>> fetchInvoices(
      String companyId, InvoiceStatus? status, String query);
  Future<SalesInvoice> fetchInvoice(String invoiceId);
  Future<String> saveDraft(String companyId, InvoiceDraft draft);
  Future<void> confirm(String invoiceId);
  Future<void> cancel(String invoiceId);
  Future<void> deleteDraft(String invoiceId);
  Future<void> addPayment({
    required String invoiceId,
    required double amount,
    required PaymentMethod method,
    String? reference,
  });
}

class SalesInvoiceRemoteDataSourceImpl implements SalesInvoiceRemoteDataSource {
  SalesInvoiceRemoteDataSourceImpl(this._client);

  final SupabaseClient _client;

  static const _limit = 100;

  static const _listColumns =
      'id, number, status, pay_status, customer_id, warehouse_id, invoice_date, '
      'due_date, subtotal, discount, tax_total, total, paid_amount, note, '
      'customers(name)';

  static const _detailColumns =
      '*, customers(name), warehouses(name), '
      'sales_invoice_items(product_id, quantity, unit_price, discount, tax_rate, '
      'products(name, sku, unit)), '
      'sales_payments(id, amount, method, paid_at, reference)';

  @override
  Future<List<SalesInvoice>> fetchInvoices(
          String companyId, InvoiceStatus? status, String query) =>
      guardRemote(() async {
        var req = _client
            .from('sales_invoices')
            .select(_listColumns)
            .eq('company_id', companyId);
        if (status != null) req = req.eq('status', status.name);
        final q = sanitizeSearch(query);
        if (q.isNotEmpty) req = req.ilike('number', '%$q%');
        final rows = await req.order('created_at', ascending: false).limit(_limit);
        return rows.map(SalesInvoiceModel.fromJson).toList();
      });

  @override
  Future<SalesInvoice> fetchInvoice(String invoiceId) => guardRemote(() async {
        final row = await _client
            .from('sales_invoices')
            .select(_detailColumns)
            .eq('id', invoiceId)
            .single();
        return SalesInvoiceModel.fromJson(row);
      });

  @override
  Future<String> saveDraft(String companyId, InvoiceDraft draft) =>
      guardRemote(() async {
        final id = await _client.rpc('save_sales_draft', params: {
          'p_company': companyId,
          'p_invoice_id': draft.id,
          'p_customer': draft.customerId,
          'p_warehouse': draft.warehouseId,
          'p_invoice_date': fmtDate(draft.invoiceDate),
          'p_due_date': draft.dueDate == null ? null : fmtDate(draft.dueDate!),
          'p_discount': draft.discount,
          'p_note': draft.note,
          'p_items': [
            for (final i in draft.items)
              {
                'product_id': i.productId,
                'quantity': i.quantity,
                'unit_price': i.unitPrice,
                'discount': i.discount,
              },
          ],
        });
        return id as String;
      });

  @override
  Future<void> confirm(String invoiceId) => guardRemote(() async {
        await _client.rpc('confirm_sales_invoice', params: {'p_invoice_id': invoiceId});
      });

  @override
  Future<void> cancel(String invoiceId) => guardRemote(() async {
        await _client.rpc('cancel_sales_invoice', params: {'p_invoice_id': invoiceId});
      });

  @override
  Future<void> deleteDraft(String invoiceId) => guardRemote(() async {
        await _client.rpc('delete_sales_draft', params: {'p_invoice_id': invoiceId});
      });

  @override
  Future<void> addPayment({
    required String invoiceId,
    required double amount,
    required PaymentMethod method,
    String? reference,
  }) =>
      guardRemote(() async {
        await _client.rpc('add_sales_payment', params: {
          'p_invoice_id': invoiceId,
          'p_amount': amount,
          'p_method': method.dbValue,
          'p_ref': reference,
        });
      });
}
