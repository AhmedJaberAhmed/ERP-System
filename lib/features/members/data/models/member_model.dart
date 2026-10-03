import '../../domain/entities/member.dart';

class MemberModel extends Member {
  const MemberModel({
    required super.userId,
    required super.email,
    required super.roleId,
    required super.roleName,
    required super.isActive,
    super.fullName,
  });

  /// Row from the `list_company_members` RPC.
  factory MemberModel.fromJson(Map<String, dynamic> json) => MemberModel(
        userId: json['user_id'] as String,
        fullName: json['full_name'] as String?,
        email: (json['email'] as String?) ?? '',
        roleId: json['role_id'] as String,
        roleName: json['role_name'] as String,
        isActive: json['is_active'] as bool,
      );
}
