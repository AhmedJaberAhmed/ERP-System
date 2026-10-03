import '../../domain/entities/warehouse.dart';

class WarehouseModel {
  WarehouseModel._();

  static Warehouse fromJson(Map<String, dynamic> j) => Warehouse(
        id: j['id'] as String,
        name: j['name'] as String,
        address: j['address'] as String?,
        isDefault: (j['is_default'] as bool?) ?? false,
        isActive: (j['is_active'] as bool?) ?? true,
      );

  static Map<String, dynamic> toJson(Warehouse w) => {
        'name': w.name,
        'address': w.address,
        'is_active': w.isActive,
      };
}
