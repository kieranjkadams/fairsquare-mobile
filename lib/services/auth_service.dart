import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';
import '../models/profile.dart';

class AuthService {
  final _client = SupabaseService.client;
  final _auth = SupabaseService.auth;

  Stream<AuthState> get authStateChanges => _auth.onAuthStateChange;

  User? get currentUser => _auth.currentUser;

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await _auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<AuthResponse> signUp({
    required String email,
    required String password,
    String? fullName,
  }) async {
    return await _auth.signUp(
      email: email,
      password: password,
      data: fullName != null ? {'full_name': fullName} : null,
    );
  }

  Future<void> resetPassword(String email) async {
    await _auth.resetPasswordForEmail(email);
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<Profile?> getProfile() async {
    final userId = currentUser?.id;
    if (userId == null) return null;

    final response = await _client
        .from('profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();

    if (response == null) return null;
    return Profile.fromJson(response);
  }

  Future<Profile> updateProfile({String? fullName}) async {
    final userId = currentUser!.id;
    final data = <String, dynamic>{};
    if (fullName != null) data['full_name'] = fullName;

    final response = await _client
        .from('profiles')
        .update(data)
        .eq('id', userId)
        .select()
        .single();

    return Profile.fromJson(response);
  }
}
