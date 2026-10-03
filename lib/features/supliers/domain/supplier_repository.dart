
import 'package:erb3/features/supliers/domain/supplier.dart';

abstract class SupplierRepository {
  /// Matches name, phone or email (case-insensitive, partial).
  Future<List<Supplier>> search(String companyId, {String query = ''});

  /// Inserts when [supplier].isNew, otherwise updates.
  Future<void> save(String companyId, Supplier supplier);

  Future<void> delete(String supplierId);
}