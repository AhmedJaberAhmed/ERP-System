

import 'package:erb3/features/supliers/data/supplier_remote_data_source.dart';

import '../domain/supplier.dart';
import '../domain/supplier_repository.dart';

class SupplierRepositoryImpl implements SupplierRepository {
  SupplierRepositoryImpl(this._remote);

  final SupplierRemoteDataSource _remote;

  @override
  Future<List<Supplier>> search(String companyId, {String query = ''}) =>
      _remote.search(companyId, query);

  @override
  Future<void> save(String companyId, Supplier supplier) =>
      _remote.save(companyId, supplier);

  @override
  Future<void> delete(String supplierId) => _remote.delete(supplierId);
}