import 'package:equatable/equatable.dart';

import '../../domain/entities/app_user.dart';

enum AuthStatus { unauthenticated, loading, authenticated, confirmationPending }

class AuthState extends Equatable {
  const AuthState({
    required this.status,
    this.user,
    this.errorMessage,
  });

  final AuthStatus status;
  final AppUser? user;
  final String? errorMessage;

  bool get isLoading => status == AuthStatus.loading;

  @override
  List<Object?> get props => [status, user, errorMessage];
}
