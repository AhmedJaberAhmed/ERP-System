import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/errors/guard_remote.dart';
import '../../../../core/utils/search_filter.dart';
import '../../domain/entities/customer.dart';
import '../models/customer_model.dart';

abstract class CustomerRemoteDataSource {
  Future<List<Customer>> search(String companyId, String query);
  Future<void> save(String companyId, Customer customer);
  Future<void> delete(String customerId);
}

class CustomerRemoteDataSourceImpl implements CustomerRemoteDataSource {
  CustomerRemoteDataSourceImpl(this._client);

  final SupabaseClient _client;

  static const _limit = 100;

  @override
  Future<List<Customer>> search(String companyId, String query) =>
      guardRemote(() async {
        var req = _client.from('customers').select().eq('company_id', companyId);
        final q = sanitizeSearch(query);
        if (q.isNotEmpty) {
          req = req.or('name.ilike.%$q%,phone.ilike.%$q%,email.ilike.%$q%');
        }
        final rows = await req.order('name').limit(_limit);
        return rows.map(CustomerModel.fromJson).toList();
      });

  @override
  Future<void> save(String companyId, Customer customer) =>
      guardRemote(() async {
        final data = CustomerModel.toJson(customer);
        if (customer.isNew) {
          await _client.from('customers').insert({...data, 'company_id': companyId});
        } else {
          await _client.from('customers').update(data).eq('id', customer.id);
        }
      });

  @override
  Future<void> delete(String customerId) => guardRemote(() async {
        try {
          await _client.from('customers').delete().eq('id', customerId);
        } on PostgrestException catch (e) {
          if (e.code == '23503') {
            throw const Failure(
                'This customer has invoices. Deactivate them instead.');
          }
          rethrow;
        }
      });
}
