import 'package:equatable/equatable.dart';

class Valuation extends Equatable {
  final String id;
  final String propertyId;
  final double currentValue;
  final DateTime createdAt;

  const Valuation({
    required this.id,
    required this.propertyId,
    required this.currentValue,
    required this.createdAt,
  });

  factory Valuation.fromJson(Map<String, dynamic> json) {
    return Valuation(
      id: json['id'] as String,
      propertyId: json['property_id'] as String,
      currentValue: (json['current_value'] as num).toDouble(),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  @override
  List<Object?> get props => [id, propertyId, currentValue];
}
