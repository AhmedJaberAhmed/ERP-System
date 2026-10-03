import 'package:equatable/equatable.dart';

enum PermissionsStatus { initial, loading, loaded, failure }

class PermissionsState extends Equatable {
  const PermissionsState({
    this.status = PermissionsStatus.initial,
    this.permissions = const <String>{},
    this.errorMessage,
  });

  final PermissionsStatus status;
  final Set<String> permissions;
  final String? errorMessage;

  bool can(String key) => permissions.contains(key);

  @override
  List<Object?> get props => [status, permissions, errorMessage];
}
