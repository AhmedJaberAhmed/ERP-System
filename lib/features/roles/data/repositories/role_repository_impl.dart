import '../../domain/entities/role.dart';
import '../../domain/repositories/role_repository.dart';
import '../datasources/role_remote_data_source.dart';

class RoleRepositoryImpl implements RoleRepository {
  RoleRepositoryImpl(this._remote);

  final RoleRemoteDataSource _remote;

  @override
  Future<List<Role>> getRoles(String companyId) => _remote.fetchRoles(companyId);

  @override
  Future<String> createRole({
    required String companyId,
    required String name,
    required Set<String> permissionKeys,
  }) =>
      _remote.createRole(
        companyId: companyId,
        name: name,
        permissionKeys: permissionKeys.toList(),
      );

  @override
  Future<void> updateRole({
    required String roleId,
    required String name,
    required Set<String> permissionKeys,
  }) =>
      _remote.updateRole(
        roleId: roleId,
        name: name,
        permissionKeys: permissionKeys.toList(),
      );

  @override
  Future<void> deleteRole(String roleId) => _remote.deleteRole(roleId);
}
