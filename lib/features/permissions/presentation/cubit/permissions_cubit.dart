import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failure.dart';
import '../../domain/repositories/permission_repository.dart';
import 'permissions_state.dart';

/// Holds the current user's permissions for the active company.
/// Deny-by-default: on failure the set stays empty.
class PermissionsCubit extends Cubit<PermissionsState> {
  PermissionsCubit(this._repository) : super(const PermissionsState());

  final PermissionRepository _repository;
  String? _companyId;

  Future<void> load(String companyId) async {
    _companyId = companyId;
    emit(const PermissionsState(status: PermissionsStatus.loading));
    try {
      final keys = await _repository.getMyPermissions(companyId);
      emit(PermissionsState(status: PermissionsStatus.loaded, permissions: keys));
    } on Failure catch (e) {
      emit(PermissionsState(
        status: PermissionsStatus.failure,
        errorMessage: e.message,
      ));
    }
  }

  Future<void> refresh() async {
    final id = _companyId;
    if (id != null) await load(id);
  }

  void reset() {
    _companyId = null;
    emit(const PermissionsState());
  }
}
