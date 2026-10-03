import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/errors/guard_remote.dart';
import '../models/role_model.dart';

abstract class RoleRemoteDataSource {
  Future<List<RoleModel>> fetchRoles(String companyId);
  Future<String> createRole({
    required String companyId,
    required String name,
    required List<String> permissionKeys,
  });
  Future<void> updateRole({
    required String roleId,
    required String name,
    required List<String> permissionKeys,
  });
  Future<void> deleteRole(String roleId);
}

class RoleRemoteDataSourceImpl implements RoleRemoteDataSource {
  RoleRemoteDataSourceImpl(this._client);

  final SupabaseClient _client;

  @override
  Future<List<RoleModel>> fetchRoles(String companyId) => guardRemote(() async {
        final rows = await _client
            .from('roles')
            .select('id, name, is_system, role_permissions(permission_key)')
            .eq('company_id', companyId)
            .order('name');
        return rows.map(RoleModel.fromJson).toList();
      });

  @override
  Future<String> createRole({
    required String companyId,
    required String name,
    required List<String> permissionKeys,
  }) =>
      guardRemote(() async {
        final id = await _client.rpc('create_role', params: {
          'p_company': companyId,
          'p_name': name,
          'p_permissions': permissionKeys,
        });
        return id as String;
      });

  @override
  Future<void> updateRole({
    required String roleId,
    required String name,
    required List<String> permissionKeys,
  }) =>
      guardRemote(() async {
        await _client.rpc('update_role', params: {
          'p_role_id': roleId,
          'p_name': name,
          'p_permissions': permissionKeys,
        });
      });

  @override
  Future<void> deleteRole(String roleId) => guardRemote(() async {
        await _client.rpc('delete_role', params: {'p_role_id': roleId});
      });
}
