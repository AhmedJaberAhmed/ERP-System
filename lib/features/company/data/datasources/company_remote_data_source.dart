import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/errors/failure.dart';
import '../models/company_model.dart';

abstract class CompanyRemoteDataSource {
  Future<List<CompanyModel>> fetchMyCompanies();
  Future<String> createCompany({required String name, required String currency});
}

class CompanyRemoteDataSourceImpl implements CompanyRemoteDataSource {
  CompanyRemoteDataSourceImpl(this._client);

  final SupabaseClient _client;

  @override
  Future<List<CompanyModel>> fetchMyCompanies() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw const Failure('You are not logged in.');
    try {
      final rows = await _client
          .from('company_members')
          .select('roles(name), companies(id, name, currency)')
          .eq('user_id', userId)
          .eq('is_active', true);
      return rows.map(CompanyModel.fromMemberRow).toList();
    } on PostgrestException catch (e) {
      throw Failure(e.message);
    } catch (_) {
      throw Failure.unknown;
    }
  }

  @override
  Future<String> createCompany({
    required String name,
    required String currency,
  }) async {
    try {
      final id = await _client.rpc(
        'create_company',
        params: {'p_name': name, 'p_currency': currency},
      );
      return id as String;
    } on PostgrestException catch (e) {
      throw Failure(e.message);
    } catch (_) {
      throw Failure.unknown;
    }
  }
}
