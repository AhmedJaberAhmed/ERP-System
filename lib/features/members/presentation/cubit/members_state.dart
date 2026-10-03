import 'package:equatable/equatable.dart';

import '../../../roles/domain/entities/role.dart';
import '../../domain/entities/member.dart';

enum MembersStatus { initial, loading, loaded, failure }

class MembersState extends Equatable {
  const MembersState({
    this.status = MembersStatus.initial,
    this.members = const [],
    this.roles = const [],
    this.isBusy = false,
    this.errorMessage,
  });

  final MembersStatus status;
  final List<Member> members;
  final List<Role> roles;
  final bool isBusy;
  final String? errorMessage;

  /// errorMessage is cleared on every copy unless passed again.
  MembersState copyWith({
    MembersStatus? status,
    List<Member>? members,
    List<Role>? roles,
    bool? isBusy,
    String? errorMessage,
  }) =>
      MembersState(
        status: status ?? this.status,
        members: members ?? this.members,
        roles: roles ?? this.roles,
        isBusy: isBusy ?? this.isBusy,
        errorMessage: errorMessage,
      );

  @override
  List<Object?> get props => [status, members, roles, isBusy, errorMessage];
}
