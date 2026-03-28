import 'package:flutter/material.dart';

import '../config/theme.dart';
import '../models/invitation.dart';
import '../services/invitation_service.dart';

class InvitationDialog extends StatefulWidget {
  final List<Invitation> invitations;
  final InvitationService invitationService;

  const InvitationDialog({
    super.key,
    required this.invitations,
    required this.invitationService,
  });

  static Future<void> show(
    BuildContext context, {
    required List<Invitation> invitations,
    required InvitationService invitationService,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => InvitationDialog(
        invitations: invitations,
        invitationService: invitationService,
      ),
    );
  }

  @override
  State<InvitationDialog> createState() => _InvitationDialogState();
}

class _InvitationDialogState extends State<InvitationDialog> {
  final _processed = <String>{};
  bool _loading = false;

  Future<void> _accept(Invitation invitation) async {
    setState(() => _loading = true);
    try {
      await widget.invitationService.acceptInvitation(invitation.investorId);
      setState(() {
        _processed.add(invitation.investorId);
        _loading = false;
      });
      _checkDone();
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to accept: $e')),
        );
      }
    }
  }

  Future<void> _decline(Invitation invitation) async {
    setState(() => _loading = true);
    try {
      await widget.invitationService.declineInvitation(invitation.investorId);
      setState(() {
        _processed.add(invitation.investorId);
        _loading = false;
      });
      _checkDone();
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to decline: $e')),
        );
      }
    }
  }

  void _checkDone() {
    if (_processed.length == widget.invitations.length && mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final pending = widget.invitations
        .where((i) => !_processed.contains(i.investorId))
        .toList();

    return AlertDialog(
      title: const Text('Pending Invitations'),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.separated(
          shrinkWrap: true,
          itemCount: pending.length,
          separatorBuilder: (_, __) => const Divider(),
          itemBuilder: (context, index) {
            final inv = pending[index];
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(inv.propertyName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                  if (inv.propertyAddress != null)
                    Text(inv.propertyAddress!, style: TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
                  const SizedBox(height: 4),
                  Text(
                    'Invited by ${inv.invitedByName ?? 'the owner'} (${inv.plannedContribution.toStringAsFixed(1)}% share)',
                    style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(child: OutlinedButton(onPressed: _loading ? null : () => _decline(inv), child: const Text('Decline'))),
                      const SizedBox(width: 12),
                      Expanded(child: ElevatedButton(onPressed: _loading ? null : () => _accept(inv), child: const Text('Accept'))),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
