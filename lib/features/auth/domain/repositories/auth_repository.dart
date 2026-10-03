import '../entities/app_user.dart';

abstract class AuthRepository {
  AppUser? get currentUser;

  /// Emits the user on sign in / refresh and null on sign out.
  Stream<AppUser?> get authStateChanges;

  Future<AppUser> signIn({required String email, required String password});

  /// Returns null when email confirmation is required (no session yet).
  Future<AppUser?> signUp({
    required String fullName,
    required String email,
    required String password,
  });

  Future<void> signOut();
}
