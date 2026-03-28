import 'package:equatable/equatable.dart';

class Investor extends Equatable {
  final String id;
  final String propertyId;
  final String? userId;
  final String name;
  final double plannedContribution;
  final double actualContribution;
  final String? invitedEmail;
  final String? invitedByName;
  final String invitationStatus;
  final DateTime createdAt;

  const Investor({
    required this.id,
    required this.propertyId,
    this.userId,
    required this.name,
    required this.plannedContribution,
    required this.actualContribution,
    this.invitedEmail,
    this.invitedByName,
    required this.invitationStatus,
    required this.createdAt,
  });

  bool get isAccepted => invitationStatus == 'accepted';
  bool get isPending => invitationStatus == 'pending';
  bool get isDeclined => invitationStatus == 'declined';

  factory Investor.fromJson(Map<String, dynamic> json) {
    return Investor(
      id: json['id'] as String,
      propertyId: json['property_id'] as String,
      userId: json['user_id'] as String?,
      name: json['name'] as String,
      plannedContribution: (json['planned_contribution'] as num).toDouble(),
      actualContribution: (json['actual_contribution'] as num).toDouble(),
      invitedEmail: json['invited_email'] as String?,
      invitedByName: json['invited_by_name'] as String?,
      invitationStatus: json['invitation_status'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'property_id': propertyId,
    'user_id': userId,
    'name': name,
    'planned_contribution': plannedContribution,
    'actual_contribution': actualContribution,
    'invited_email': invitedEmail,
    'invited_by_name': invitedByName,
    'invitation_status': invitationStatus,
    'created_at': createdAt.toIso8601String(),
  };

  @override
  List<Object?> get props => [id, propertyId, userId, name, invitationStatus];
}
