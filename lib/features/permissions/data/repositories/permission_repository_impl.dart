import '../../domain/entities/permission.dart';
import '../../domain/repositories/permission_repository.dart';
import '../datasources/permission_remote_data_source.dart';

class PermissionRepositoryImpl implements PermissionRepository {
  PermissionRepositoryImpl(this._remote);

  final PermissionRemoteDataSource _remote;

  @override
  Future<Set<String>> getMyPermissions(String companyId) =>
      _remote.fetchMyPermissions(companyId);

  @override
  Future<List<Permission>> getAllPermissions() => _remote.fetchAllPermissions();
}
