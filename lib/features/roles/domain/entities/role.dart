import 'package:equatable/equatable.dart';

class Role extends Equatable {
  const Role({
    required this.id,
    required this.name,
    required this.isSystem,
    required this.permissionKeys,
  });

  final String id;
  final String name;

  /// System roles (Owner) cannot be edited or deleted.
  final bool isSystem;
  final Set<String> permissionKeys;

  @override
  List<Object?> get props => [id, name, isSystem, permissionKeys];
}
