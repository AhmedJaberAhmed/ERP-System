import '../../domain/entities/warehouse.dart';
import '../../domain/repositories/warehouse_repository.dart';
import '../datasources/warehouse_remote_data_source.dart';

class WarehouseRepositoryImpl implements WarehouseRepository {
  WarehouseRepositoryImpl(this._remote);

  final WarehouseRemoteDataSource _remote;

  @override
  Future<List<Warehouse>> getWarehouses(String companyId, {bool activeOnly = false}) =>
      _remote.fetch(companyId, activeOnly);

  @override
  Future<void> save(String companyId, Warehouse warehouse) =>
      _remote.save(companyId, warehouse);

  @override
  Future<void> setDefault(String companyId, String warehouseId) =>
      _remote.setDefault(companyId, warehouseId);

  @override
  Future<void> delete(String warehouseId) => _remote.delete(warehouseId);
}
