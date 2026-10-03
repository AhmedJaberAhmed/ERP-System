import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/errors/guard_remote.dart';
import '../models/member_model.dart';

abstract class MemberRemoteDataSource {
  Future<List<MemberModel>> fetchMembers(String companyId);
  Future<void> addMember({
    required String companyId,
    required String email,
    required String roleId,
  });
  Future<void> changeRole({
    required String companyId,
    required String userId,
    required String roleId,
  });
  Future<void> setActive({
    required String companyId,
    required String userId,
    required bool isActive,
  });
}

class MemberRemoteDataSourceImpl implements MemberRemoteDataSource {
  MemberRemoteDataSourceImpl(this._client);

  final SupabaseClient _client;

  @override
  Future<List<MemberModel>> fetchMembers(String companyId) => guardRemote(() async {
        final rows = await _client.rpc(
          'list_company_members',
          params: {'p_company': companyId},
        );
        return (rows as List)
            .map((e) => MemberModel.fromJson(e as Map<String, dynamic>))
            .toList();
      });

  @override
  Future<void> addMember({
    required String companyId,
    required String email,
    required String roleId,
  }) =>
      guardRemote(() async {
        await _client.rpc('add_member_by_email', params: {
          'p_company': companyId,
          'p_email': email,
          'p_role_id': roleId,
        });
      });

  @override
  Future<void> changeRole({
    required String companyId,
    required String userId,
    required String roleId,
  }) =>
      guardRemote(() async {
        await _client.rpc('set_member_role', params: {
          'p_company': companyId,
          'p_user': userId,
          'p_role_id': roleId,
        });
      });

  @override
  Future<void> setActive({
    required String companyId,
    required String userId,
    required bool isActive,
  }) =>
      guardRemote(() async {
        await _client.rpc('set_member_active', params: {
          'p_company': companyId,
          'p_user': userId,
          'p_active': isActive,
        });
      });
}
