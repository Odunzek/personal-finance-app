import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_client.dart';

abstract class AuthRepository {
  Stream<AuthState> get authStateChanges;
  User? get currentUser;

  Future<void> signIn({required String email, required String password});
  Future<void> signUp({required String email, required String password});
  Future<void> signOut();
}

class SupabaseAuthRepository implements AuthRepository {
  @override
  Stream<AuthState> get authStateChanges => supabase.auth.onAuthStateChange;

  @override
  User? get currentUser => supabase.auth.currentUser;

  @override
  Future<void> signIn({required String email, required String password}) {
    return supabase.auth.signInWithPassword(email: email, password: password);
  }

  @override
  Future<void> signUp({required String email, required String password}) {
    return supabase.auth.signUp(email: email, password: password);
  }

  @override
  Future<void> signOut() {
    return supabase.auth.signOut();
  }
}
