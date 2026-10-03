import 'package:erb3/features/supliers/data/supplier_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/errors/guard_remote.dart';
import '../../../../core/utils/search_filter.dart';
import '../domain/supplier.dart';


abstract class SupplierRemoteDataSource {
  Future<List<Supplier>> search(String companyId, String query);
  Future<void> save(String companyId, Supplier supplier);
  Future<void> delete(String supplierId);
}

class SupplierRemoteDataSourceImpl implements SupplierRemoteDataSource {
  SupplierRemoteDataSourceImpl(this._client);

  final SupabaseClient _client;

  static const _limit = 100;

  @override
  Future<List<Supplier>> search(String companyId, String query) =>
      guardRemote(() async {
        var req = _client.from('suppliers').select().eq('company_id', companyId);
        final q = sanitizeSearch(query);
        if (q.isNotEmpty) {
          req = req.or('name.ilike.%$q%,phone.ilike.%$q%,email.ilike.%$q%');
        }
        final rows = await req.order('name').limit(_limit);
        return rows.map(SupplierModel.fromJson).toList();
      });

  @override
  Future<void> save(String companyId, Supplier supplier) =>
      guardRemote(() async {
        final data = SupplierModel.toJson(supplier);
        if (supplier.isNew) {
          await _client.from('suppliers').insert({...data, 'company_id': companyId});
        } else {
          await _client.from('suppliers').update(data).eq('id', supplier.id);
        }
      });

  @override
  Future<void> delete(String supplierId) => guardRemote(() async {
    try {
      await _client.from('suppliers').delete().eq('id', supplierId);
    } on PostgrestException catch (e) {
      if (e.code == '23503') {
        throw const Failure(
            'This supplier has purchase orders. Deactivate them instead.');
      }
      rethrow;
    }
  });
}