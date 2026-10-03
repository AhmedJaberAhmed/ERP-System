import '../entities/warehouse.dart';

abstract class WarehouseRepository {
  Future<List<Warehouse>> getWarehouses(String companyId, {bool activeOnly = false});

  /// Inserts when [warehouse].isNew, otherwise updates.
  Future<void> save(String companyId, Warehouse warehouse);

  /// Makes this the only default warehouse.
  Future<void> setDefault(String companyId, String warehouseId);

  Future<void> delete(String warehouseId);
}
