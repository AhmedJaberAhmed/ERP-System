import 'package:supabase_flutter/supabase_flutter.dart';

import 'failure.dart';

/// Runs a Supabase call and converts any exception into a [Failure].
Future<T> guardRemote<T>(Future<T> Function() action) async {
  try {
    return await action();
  } on PostgrestException catch (e) {
    throw Failure(e.message);
  } on AuthException catch (e) {
    throw Failure(e.message);
  } on Failure {
    rethrow;
  } catch (_) {
    throw Failure.unknown;
  }
}
