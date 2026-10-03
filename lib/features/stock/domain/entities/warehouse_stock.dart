import 'package:equatable/equatable.dart';

class WarehouseStock extends Equatable {
  const WarehouseStock({
    required this.warehouseId,
    required this.warehouseName,
    required this.quantity,
  });

  final String warehouseId;
  final String warehouseName;
  final double quantity;

  @override
  List<Object?> get props => [warehouseId, warehouseName, quantity];
}
