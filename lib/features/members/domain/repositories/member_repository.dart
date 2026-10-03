import '../entities/member.dart';

abstract class MemberRepository {
  Future<List<Member>> getMembers(String companyId);

  /// The user must already have an account.
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
