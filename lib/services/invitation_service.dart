import 'supabase_service.dart';
import '../models/invitation.dart';

class InvitationService {
  final _client = SupabaseService.client;

  Future<List<Invitation>> getPendingInvitations() async {
    final email = SupabaseService.currentUserEmail;
    if (email == null) return [];

    final response = await _client.rpc(
      'get_pending_invitations',
      params: {'user_email': email},
    );

    if (response is List) {
      return response
          .map((e) => Invitation.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  Future<void> acceptInvitation(String investorId) async {
    await _client.rpc(
      'accept_invitation',
      params: {'investor_id': investorId},
    );
  }

  Future<void> declineInvitation(String investorId) async {
    await _client.rpc(
      'decline_invitation',
      params: {'investor_id': investorId},
    );
  }
}
