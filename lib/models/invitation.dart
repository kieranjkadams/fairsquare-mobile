import 'package:equatable/equatable.dart';

class Invitation extends Equatable {
  final String investorId;
  final String propertyName;
  final String? propertyAddress;
  final String? invitedByName;
  final double plannedContribution;

  const Invitation({required this.investorId, required this.propertyName, this.propertyAddress, this.invitedByName, required this.plannedContribution});

  factory Invitation.fromJson(Map<String, dynamic> json) {
    return Invitation(
      investorId: json['investor_id'] as String? ?? json['id'] as String,
      propertyName: json['property_name'] as String? ?? json['name'] as String,
      propertyAddress: json['property_address'] as String? ?? json['address'] as String?,
      invitedByName: json['invited_by_name'] as String?,
      plannedContribution: (json['planned_contribution'] as num).toDouble(),
    );
  }

  @override
  List<Object?> get props => [investorId, propertyName];
}
