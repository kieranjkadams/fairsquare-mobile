import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/constants.dart';

class SupabaseService {
  static SupabaseClient get client => Supabase.instance.client;

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: AppConstants.supabaseUrl,
      anonKey: AppConstants.supabaseAnonKey,
    );
  }

  static GoTrueClient get auth => client.auth;
  static SupabaseStorageClient get storage => client.storage;

  static User? get currentUser => auth.currentUser;
  static String? get currentUserId => currentUser?.id;
  static String? get currentUserEmail => currentUser?.email;
}
