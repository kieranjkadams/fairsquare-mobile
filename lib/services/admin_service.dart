import 'supabase_service.dart';
import '../models/admin_stats.dart';

class AdminService {
  final _client = SupabaseService.client;

  Future<AdminStats> getAdminStats() async {
    final response = await _client.rpc('get_admin_stats');
    return AdminStats.fromJson(response as Map<String, dynamic>);
  }
}
