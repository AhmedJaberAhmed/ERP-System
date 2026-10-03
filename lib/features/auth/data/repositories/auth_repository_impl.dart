import '../../domain/entities/app_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_data_source.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._remote);

  final AuthRemoteDataSource _remote;

  @override
  AppUser? get currentUser => _remote.currentUser;

  @override
  Stream<AppUser?> get authStateChanges => _remote.authStateChanges();

  @override
  Future<AppUser> signIn({required String email, required String password}) =>
      _remote.signIn(email: email, password: password);

  @override
  Future<AppUser?> signUp({
    required String fullName,
    required String email,
    required String password,
  }) =>
      _remote.signUp(fullName: fullName, email: email, password: password);

  @override
  Future<void> signOut() => _remote.signOut();
}
