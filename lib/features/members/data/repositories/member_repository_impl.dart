import '../../domain/entities/member.dart';
import '../../domain/repositories/member_repository.dart';
import '../datasources/member_remote_data_source.dart';

class MemberRepositoryImpl implements MemberRepository {
  MemberRepositoryImpl(this._remote);

  final MemberRemoteDataSource _remote;

  @override
  Future<List<Member>> getMembers(String companyId) =>
      _remote.fetchMembers(companyId);

  @override
  Future<void> addMember({
    required String companyId,
    required String email,
    required String roleId,
  }) =>
      _remote.addMember(companyId: companyId, email: email, roleId: roleId);

  @override
  Future<void> changeRole({
    required String companyId,
    required String userId,
    required String roleId,
  }) =>
      _remote.changeRole(companyId: companyId, userId: userId, roleId: roleId);

  @override
  Future<void> setActive({
    required String companyId,
    required String userId,
    required bool isActive,
  }) =>
      _remote.setActive(companyId: companyId, userId: userId, isActive: isActive);
}
