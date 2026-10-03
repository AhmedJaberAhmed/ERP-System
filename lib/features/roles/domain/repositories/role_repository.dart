import '../entities/role.dart';

abstract class RoleRepository {
  Future<List<Role>> getRoles(String companyId);

  /// Returns the new role id.
  Future<String> createRole({
    required String companyId,
    required String name,
    required Set<String> permissionKeys,
  });

  Future<void> updateRole({
    required String roleId,
    required String name,
    required Set<String> permissionKeys,
  });

  Future<void> deleteRole(String roleId);
}
