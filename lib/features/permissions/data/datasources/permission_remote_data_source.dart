import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/errors/guard_remote.dart';
import '../models/permission_model.dart';

abstract class PermissionRemoteDataSource {
  Future<Set<String>> fetchMyPermissions(String companyId);
  Future<List<PermissionModel>> fetchAllPermissions();
}

class PermissionRemoteDataSourceImpl implements PermissionRemoteDataSource {
  PermissionRemoteDataSourceImpl(this._client);

  final SupabaseClient _client;

  @override
  Future<Set<String>> fetchMyPermissions(String companyId) => guardRemote(() async {
        final res = await _client.rpc(
          'my_permissions',
          params: {'p_company': companyId},
        );
        return (res as List).map((e) => e as String).toSet();
      });

  @override
  Future<List<PermissionModel>> fetchAllPermissions() => guardRemote(() async {
        final rows =
            await _client.from('permissions').select('key, description').order('key');
        return rows.map(PermissionModel.fromJson).toList();
      });
}
