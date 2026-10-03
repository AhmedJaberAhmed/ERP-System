import 'package:equatable/equatable.dart';

class Member extends Equatable {
  const Member({
    required this.userId,
    required this.email,
    required this.roleId,
    required this.roleName,
    required this.isActive,
    this.fullName,
  });

  final String userId;
  final String? fullName;
  final String email;
  final String roleId;
  final String roleName;
  final bool isActive;

  String get displayName =>
      (fullName != null && fullName!.trim().isNotEmpty) ? fullName! : email;

  @override
  List<Object?> get props => [userId, fullName, email, roleId, roleName, isActive];
}
