import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failure.dart';
import '../../../roles/domain/repositories/role_repository.dart';
import '../../domain/repositories/member_repository.dart';
import 'members_state.dart';

/// ViewModel for member management.
class MembersCubit extends Cubit<MembersState> {
  MembersCubit(
    this._members,
    this._roles,
    this._companyId,
    this.currentUserId,
  ) : super(const MembersState());

  final MemberRepository _members;
  final RoleRepository _roles;
  final String _companyId;

  /// Used by the UI to hide actions on yourself.
  final String currentUserId;

  Future<void> load({bool silent = false}) async {
    if (!silent) emit(state.copyWith(status: MembersStatus.loading));
    try {
      final members = await _members.getMembers(_companyId);
      final roles = await _roles.getRoles(_companyId);
      emit(MembersState(
        status: MembersStatus.loaded,
        members: members,
        roles: roles,
      ));
    } on Failure catch (e) {
      final keepList = silent && state.status == MembersStatus.loaded;
      emit(state.copyWith(
        status: keepList ? MembersStatus.loaded : MembersStatus.failure,
        errorMessage: e.message,
      ));
    }
  }

  Future<bool> addMember({required String email, required String roleId}) =>
      _run(() => _members.addMember(
            companyId: _companyId,
            email: email,
            roleId: roleId,
          ));

  Future<bool> changeRole({required String userId, required String roleId}) =>
      _run(() => _members.changeRole(
            companyId: _companyId,
            userId: userId,
            roleId: roleId,
          ));

  Future<bool> setActive({required String userId, required bool isActive}) =>
      _run(() => _members.setActive(
            companyId: _companyId,
            userId: userId,
            isActive: isActive,
          ));

  Future<bool> _run(Future<void> Function() action) async {
    emit(state.copyWith(isBusy: true));
    try {
      await action();
      final members = await _members.getMembers(_companyId);
      emit(state.copyWith(isBusy: false, members: members));
      return true;
    } on Failure catch (e) {
      emit(state.copyWith(isBusy: false, errorMessage: e.message));
      return false;
    }
  }
}
