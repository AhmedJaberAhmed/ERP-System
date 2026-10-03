import '../../../../core/utils/format.dart';
import '../domain/DashboardSummary.dart';

class DashboardModels {
  DashboardModels._();

  static int _int(dynamic v) => asDouble(v).round();

  static DashboardSummary summary(Map<String, dynamic>? j) {
    if (j == null) return const DashboardSummary();
    return DashboardSummary(
      todaySales: asDouble(j['today_sales']),
      todayInvoices: _int(j['today_invoices']),
      unpaidCount: _int(j['unpaid_count']),
      unpaidTotal: asDouble(j['unpaid_total']),
      lowStockCount: _int(j['low_stock_count']),
    );
  }

  static DailySales daily(Map<String, dynamic> j) => DailySales(
    day: DateTime.parse(j['day'] as String),
    total: asDouble(j['total']),
  );

  static TopProduct top(Map<String, dynamic> j) => TopProduct(
    productId: j['product_id'] as String,
    name: (j['name'] as String?) ?? '',
    unit: (j['unit'] as String?) ?? 'pcs',
    quantity: asDouble(j['quantity']),
    revenue: asDouble(j['revenue']),
  );

  static LowStockProduct low(Map<String, dynamic> j) => LowStockProduct(
    productId: j['product_id'] as String,
    sku: (j['sku'] as String?) ?? '',
    name: (j['name'] as String?) ?? '',
    unit: (j['unit'] as String?) ?? 'pcs',
    minStock: asDouble(j['min_stock']),
    quantity: asDouble(j['quantity']),
  );

  static UnpaidInvoice unpaid(Map<String, dynamic> j) => UnpaidInvoice(
    invoiceId: j['invoice_id'] as String,
    number: j['number'] as String?,
    customerName: j['customer_name'] as String?,
    dueDate: j['due_date'] == null ? null : DateTime.parse(j['due_date'] as String),
    total: asDouble(j['total']),
    paidAmount: asDouble(j['paid_amount']),
    balance: asDouble(j['balance']),
    isOverdue: j['is_overdue'] == true,
  );
}