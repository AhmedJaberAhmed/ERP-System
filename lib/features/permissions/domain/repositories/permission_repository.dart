import '../entities/permission.dart';

abstract class PermissionRepository {
  /// Permission keys the signed-in user has in [companyId].
  Future<Set<String>> getMyPermissions(String companyId);

  /// Full catalog (used by the role editor).
  Future<List<Permission>> getAllPermissions();
}
