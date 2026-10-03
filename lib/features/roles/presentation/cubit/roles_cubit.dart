import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failure.dart';
import '../../../permissions/domain/repositories/permission_repository.dart';
import '../../domain/entities/role.dart';
import '../../domain/repositories/role_repository.dart';
import 'roles_state.dart';

/// ViewModel for the roles list and role editor.
class RolesCubit extends Cubit<RolesState> {
  RolesCubit(this._roles, this._permissions, this._companyId)
      : super(const RolesState());

  final RoleRepository _roles;
  final PermissionRepository _permissions;
  final String _companyId;

  Future<void> load({bool silent = false}) async {
    if (!silent) emit(state.copyWith(status: RolesStatus.loading));
    try {
      final roles = await _roles.getRoles(_companyId);
      final catalog = await _permissions.getAllPermissions();
      emit(RolesState(
        status: RolesStatus.loaded,
        roles: _sorted(roles),
        allPermissions: catalog,
      ));
    } on Failure catch (e) {
      final keepList = silent && state.status == RolesStatus.loaded;
      emit(state.copyWith(
        status: keepList ? RolesStatus.loaded : RolesStatus.failure,
        errorMessage: e.message,
      ));
    }
  }

  /// Creates a role when [existing] is null, otherwise updates it.
  Future<bool> saveRole({
    Role? existing,
    required String name,
    required Set<String> permissionKeys,
  }) {
    return _run(() async {
      if (existing == null) {
        await _roles.createRole(
          companyId: _companyId,
          name: name,
          permissionKeys: permissionKeys,
        );
      } else {
        await _roles.updateRole(
          roleId: existing.id,
          name: name,
          permissionKeys: permissionKeys,
        );
      }
    });
  }

  Future<bool> deleteRole(Role role) => _run(() => _roles.deleteRole(role.id));

  Future<bool> _run(Future<void> Function() action) async {
    emit(state.copyWith(isBusy: true));
    try {
      await action();
      final roles = await _roles.getRoles(_companyId);
      emit(state.copyWith(isBusy: false, roles: _sorted(roles)));
      return true;
    } on Failure catch (e) {
      emit(state.copyWith(isBusy: false, errorMessage: e.message));
      return false;
    }
  }

  List<Role> _sorted(List<Role> roles) {
    final list = [...roles];
    list.sort((a, b) {
      if (a.isSystem != b.isSystem) return a.isSystem ? -1 : 1;
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
    return list;
  }
}
