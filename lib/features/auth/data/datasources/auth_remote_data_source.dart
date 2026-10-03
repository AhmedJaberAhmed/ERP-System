import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/errors/failure.dart';
import '../models/app_user_model.dart';

abstract class AuthRemoteDataSource {
  AppUserModel? get currentUser;
  Stream<AppUserModel?> authStateChanges();
  Future<AppUserModel> signIn({required String email, required String password});
  Future<AppUserModel?> signUp({
    required String fullName,
    required String email,
    required String password,
  });
  Future<void> signOut();
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  AuthRemoteDataSourceImpl(this._client);

  final SupabaseClient _client;

  GoTrueClient get _auth => _client.auth;

  @override
  AppUserModel? get currentUser {
    final user = _auth.currentUser;
    return user == null ? null : AppUserModel.fromSupabase(user);
  }

  @override
  Stream<AppUserModel?> authStateChanges() {
    return _auth.onAuthStateChange.map((event) {
      final user = event.session?.user;
      return user == null ? null : AppUserModel.fromSupabase(user);
    });
  }

  @override
  Future<AppUserModel> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final res = await _auth.signInWithPassword(email: email, password: password);
      final user = res.user;
      if (user == null) throw const Failure('Login failed. Please try again.');
      return AppUserModel.fromSupabase(user);
    } on AuthException catch (e) {
      throw Failure(e.message);
    } on Failure {
      rethrow;
    } catch (_) {
      throw Failure.unknown;
    }
  }

  @override
  Future<AppUserModel?> signUp({
    required String fullName,
    required String email,
    required String password,
  }) async {
    try {
      final res = await _auth.signUp(
        email: email,
        password: password,
        data: {'full_name': fullName}, // read by the handle_new_user trigger
      );
      if (res.session == null || res.user == null) return null;
      return AppUserModel.fromSupabase(res.user!);
    } on AuthException catch (e) {
      throw Failure(e.message);
    } catch (_) {
      throw Failure.unknown;
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } on AuthException catch (e) {
      throw Failure(e.message);
    } catch (_) {
      throw Failure.unknown;
    }
  }
}
