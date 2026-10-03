import '../../../../core/utils/format.dart';
import '../../domain/entities/invoice_item.dart';
import '../../domain/entities/sales_invoice.dart';

class SalesInvoiceModel {
  SalesInvoiceModel._();

  static InvoiceStatus _status(String v) => InvoiceStatus.values.firstWhere(
        (s) => s.name == v,
        orElse: () => InvoiceStatus.draft,
      );

  static PaymentStatus _pay(String v) => PaymentStatus.values.firstWhere(
        (s) => s.name == v,
        orElse: () => PaymentStatus.unpaid,
      );

  static PaymentMethod _method(String v) => PaymentMethod.values.firstWhere(
        (m) => m.dbValue == v,
        orElse: () => PaymentMethod.cash,
      );

  static InvoiceItem _item(Map<String, dynamic> j) {
    final product = (j['products'] as Map<String, dynamic>?) ?? const {};
    return InvoiceItem(
      productId: j['product_id'] as String,
      productName: (product['name'] as String?) ?? '',
      sku: (product['sku'] as String?) ?? '',
      unit: (product['unit'] as String?) ?? 'pcs',
      quantity: asDouble(j['quantity']),
      unitPrice: asDouble(j['unit_price']),
      discount: asDouble(j['discount']),
      taxRate: asDouble(j['tax_rate']),
    );
  }

  static InvoicePayment _payment(Map<String, dynamic> j) => InvoicePayment(
        id: j['id'] as String,
        amount: asDouble(j['amount']),
        method: _method(j['method'] as String),
        paidAt: DateTime.parse(j['paid_at'] as String).toLocal(),
        reference: j['reference'] as String?,
      );

  /// Works for both list rows (no items) and detail rows (items + payments).
  static SalesInvoice fromJson(Map<String, dynamic> j) {
    final items = (j['sales_invoice_items'] as List?) ?? const [];
    final payments = (j['sales_payments'] as List?) ?? const [];
    final customer = j['customers'] as Map<String, dynamic>?;
    final warehouse = j['warehouses'] as Map<String, dynamic>?;
    return SalesInvoice(
      id: j['id'] as String,
      number: j['number'] as String?,
      status: _status(j['status'] as String),
      payStatus: _pay(j['pay_status'] as String),
      customerId: j['customer_id'] as String?,
      customerName: customer?['name'] as String?,
      warehouseId: j['warehouse_id'] as String,
      warehouseName: warehouse?['name'] as String?,
      invoiceDate: DateTime.parse(j['invoice_date'] as String),
      dueDate: j['due_date'] == null ? null : DateTime.parse(j['due_date'] as String),
      subtotal: asDouble(j['subtotal']),
      discount: asDouble(j['discount']),
      taxTotal: asDouble(j['tax_total']),
      total: asDouble(j['total']),
      paidAmount: asDouble(j['paid_amount']),
      note: j['note'] as String?,
      items: items.map((e) => _item(e as Map<String, dynamic>)).toList(),
      payments: payments
          .map((e) => _payment(e as Map<String, dynamic>))
          .toList()
        ..sort((a, b) => a.paidAt.compareTo(b.paidAt)), // oldest first
    );
  }
}
