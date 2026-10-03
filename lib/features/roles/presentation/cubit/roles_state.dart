import 'package:equatable/equatable.dart';

import '../../../permissions/domain/entities/permission.dart';
import '../../domain/entities/role.dart';

enum RolesStatus { initial, loading, loaded, failure }

class RolesState extends Equatable {
  const RolesState({
    this.status = RolesStatus.initial,
    this.roles = const [],
    this.allPermissions = const [],
    this.isBusy = false,
    this.errorMessage,
  });

  final RolesStatus status;
  final List<Role> roles;
  final List<Permission> allPermissions;

  /// True while saving/deleting.
  final bool isBusy;
  final String? errorMessage;

  /// errorMessage is cleared on every copy unless passed again.
  RolesState copyWith({
    RolesStatus? status,
    List<Role>? roles,
    List<Permission>? allPermissions,
    bool? isBusy,
    String? errorMessage,
  }) =>
      RolesState(
        status: status ?? this.status,
        roles: roles ?? this.roles,
        allPermissions: allPermissions ?? this.allPermissions,
        isBusy: isBusy ?? this.isBusy,
        errorMessage: errorMessage,
      );

  @override
  List<Object?> get props => [status, roles, allPermissions, isBusy, errorMessage];
}
