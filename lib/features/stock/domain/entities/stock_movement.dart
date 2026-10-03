import 'package:equatable/equatable.dart';

class StockMovement extends Equatable {
  const StockMovement({
    required this.id,
    required this.type,
    required this.quantity,
    required this.createdAt,
    required this.warehouseName,
    this.note,
  });

  final String id;

  /// purchase_in, sale_out, adjustment, transfer_in, transfer_out, return_in, return_out
  final String type;

  /// Signed: positive = stock in, negative = stock out.
  final double quantity;
  final DateTime createdAt;
  final String warehouseName;
  final String? note;

  String get label {
    switch (type) {
      case 'purchase_in':
        return 'Purchase';
      case 'sale_out':
        return 'Sale';
      case 'adjustment':
        return 'Adjustment';
      case 'transfer_in':
        return 'Transfer in';
      case 'transfer_out':
        return 'Transfer out';
      case 'return_in':
        return 'Return (in)';
      case 'return_out':
        return 'Return (out)';
      default:
        return type;
    }
  }

  @override
  List<Object?> get props => [id, type, quantity, createdAt, warehouseName, note];
}
