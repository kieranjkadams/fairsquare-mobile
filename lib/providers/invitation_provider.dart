import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/invitation.dart';
import '../services/invitation_service.dart';
import 'auth_provider.dart';

final invitationServiceProvider = Provider<InvitationService>((ref) => InvitationService());

final pendingInvitationsProvider = FutureProvider<List<Invitation>>((ref) async {
  ref.watch(authStateProvider);
  return ref.watch(invitationServiceProvider).getPendingInvitations();
});
