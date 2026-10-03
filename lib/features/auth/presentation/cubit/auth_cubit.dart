import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failure.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/repositories/auth_repository.dart';
import 'auth_state.dart';

/// ViewModel for authentication.
class AuthCubit extends Cubit<AuthState> {
  AuthCubit(this._repository)
      : super(
          _repository.currentUser == null
              ? const AuthState(status: AuthStatus.unauthenticated)
              : AuthState(
                  status: AuthStatus.authenticated,
                  user: _repository.currentUser,
                ),
        ) {
    _subscription = _repository.authStateChanges.listen(_onUserChanged);
  }

  final AuthRepository _repository;
  late final StreamSubscription<AppUser?> _subscription;

  void _onUserChanged(AppUser? user) {
    if (user != null) {
      emit(AuthState(status: AuthStatus.authenticated, user: user));
    } else if (state.status == AuthStatus.authenticated) {
      // Signed out or session expired.
      emit(const AuthState(status: AuthStatus.unauthenticated));
    }
  }

  Future<void> signIn({required String email, required String password}) async {
    emit(const AuthState(status: AuthStatus.loading));
    try {
      final user = await _repository.signIn(email: email, password: password);
      emit(AuthState(status: AuthStatus.authenticated, user: user));
    } on Failure catch (e) {
      emit(AuthState(status: AuthStatus.unauthenticated, errorMessage: e.message));
    }
  }

  Future<void> signUp({
    required String fullName,
    required String email,
    required String password,
  }) async {
    emit(const AuthState(status: AuthStatus.loading));
    try {
      final user = await _repository.signUp(
        fullName: fullName,
        email: email,
        password: password,
      );
      if (user == null) {
        emit(const AuthState(status: AuthStatus.confirmationPending));
      } else {
        emit(AuthState(status: AuthStatus.authenticated, user: user));
      }
    } on Failure catch (e) {
      emit(AuthState(status: AuthStatus.unauthenticated, errorMessage: e.message));
    }
  }

  Future<void> signOut() async {
    try {
      await _repository.signOut();
      emit(const AuthState(status: AuthStatus.unauthenticated));
    } on Failure catch (e) {
      emit(AuthState(
        status: AuthStatus.authenticated,
        user: state.user,
        errorMessage: e.message,
      ));
    }
  }

  @override
  Future<void> close() {
    _subscription.cancel();
    return super.close();
  }
}
