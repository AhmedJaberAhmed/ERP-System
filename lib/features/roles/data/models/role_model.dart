import '../../domain/entities/role.dart';

class RoleModel extends Role {
  const RoleModel({
    required super.id,
    required super.name,
    required super.isSystem,
    required super.permissionKeys,
  });

  /// Row from: roles.select('id, name, is_system, role_permissions(permission_key)')
  factory RoleModel.fromJson(Map<String, dynamic> json) {
    final perms = (json['role_permissions'] as List? ?? const [])
        .map((e) => (e as Map<String, dynamic>)['permission_key'] as String)
        .toSet();
    return RoleModel(
      id: json['id'] as String,
      name: json['name'] as String,
      isSystem: json['is_system'] as bool,
      permissionKeys: perms,
    );
  }
}
