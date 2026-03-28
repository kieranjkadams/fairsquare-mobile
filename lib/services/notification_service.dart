import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'supabase_service.dart';

class NotificationService {
  final _messaging = FirebaseMessaging.instance;

  Future<void> initialize() async {
    // Request permission
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Get and register token
    final token = await _messaging.getToken();
    if (token != null) {
      await _registerToken(token);
    }

    // Listen for token refresh
    _messaging.onTokenRefresh.listen(_registerToken);
  }

  Future<void> _registerToken(String token) async {
    final userId = SupabaseService.currentUserId;
    if (userId == null) return;

    final platform = defaultTargetPlatform == TargetPlatform.iOS
        ? 'ios'
        : 'android';

    try {
      await SupabaseService.client.from('push_tokens').upsert(
        {
          'user_id': userId,
          'token': token,
          'platform': platform,
        },
        onConflict: 'user_id,token',
      );
    } catch (e) {
      debugPrint('Failed to register push token: $e');
    }
  }

  Future<void> removeToken() async {
    final userId = SupabaseService.currentUserId;
    final token = await _messaging.getToken();
    if (userId == null || token == null) return;

    try {
      await SupabaseService.client
          .from('push_tokens')
          .delete()
          .eq('user_id', userId)
          .eq('token', token);
    } catch (e) {
      debugPrint('Failed to remove push token: $e');
    }
  }
}
