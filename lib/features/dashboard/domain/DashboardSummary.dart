import 'package:equatable/equatable.dart';

class DashboardSummary extends Equatable {
  const DashboardSummary({
    this.todaySales = 0,
    this.todayInvoices = 0,
    this.unpaidCount = 0,
    this.unpaidTotal = 0,
    this.lowStockCount = 0,
  });

  final double todaySales;
  final int todayInvoices;
  final int unpaidCount;
  final double unpaidTotal;
  final int lowStockCount;

  @override
  List<Object?> get props =>
      [todaySales, todayInvoices, unpaidCount, unpaidTotal, lowStockCount];
}

class DailySales extends Equatable {
  const DailySales({required this.day, required this.total});

  final DateTime day;
  final double total;

  @override
  List<Object?> get props => [day, total];
}

class TopProduct extends Equatable {
  const TopProduct({
    required this.productId,
    required this.name,
    required this.unit,
    required this.quantity,
    required this.revenue,
  });

  final String productId;
  final String name;
  final String unit;
  final double quantity;
  final double revenue;

  @override
  List<Object?> get props => [productId, name, unit, quantity, revenue];
}

class LowStockProduct extends Equatable {
  const LowStockProduct({
    required this.productId,
    required this.sku,
    required this.name,
    required this.unit,
    required this.minStock,
    required this.quantity,
  });

  final String productId;
  final String sku;
  final String name;
  final String unit;
  final double minStock;
  final double quantity;

  @override
  List<Object?> get props => [productId, sku, name, unit, minStock, quantity];
}

class UnpaidInvoice extends Equatable {
  const UnpaidInvoice({
    required this.invoiceId,
    required this.total,
    required this.paidAmount,
    required this.balance,
    required this.isOverdue,
    this.number,
    this.customerName,
    this.dueDate,
  });

  final String invoiceId;
  final String? number;
  final String? customerName;
  final DateTime? dueDate;
  final double total;
  final double paidAmount;
  final double balance;
  final bool isOverdue;

  @override
  List<Object?> get props => [
    invoiceId, number, customerName, dueDate, total, paidAmount, balance, isOverdue,
  ];
}

class DashboardData extends Equatable {
  const DashboardData({
    required this.summary,
    required this.last7Days,
    required this.topProducts,
    required this.unpaid,
    required this.lowStock,
  });

  final DashboardSummary summary;
  final List<DailySales> last7Days;
  final List<TopProduct> topProducts;
  final List<UnpaidInvoice> unpaid;
  final List<LowStockProduct> lowStock;

  @override
  List<Object?> get props => [summary, last7Days, topProducts, unpaid, lowStock];
}