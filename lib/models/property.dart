import 'package:equatable/equatable.dart';

class Property extends Equatable {
  final String id;
  final String userId;
  final String name;
  final String? address;
  final double purchasePrice;
  final double downPaymentPercent;
  final String currency;
  final DateTime createdAt;

  const Property({
    required this.id,
    required this.userId,
    required this.name,
    this.address,
    required this.purchasePrice,
    this.downPaymentPercent = 20,
    this.currency = 'CAD',
    required this.createdAt,
  });

  factory Property.fromJson(Map<String, dynamic> json) {
    return Property(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      name: json['name'] as String,
      address: json['address'] as String?,
      purchasePrice: (json['purchase_price'] as num).toDouble(),
      downPaymentPercent: (json['down_payment_percent'] as num?)?.toDouble() ?? 20,
      currency: json['currency'] as String? ?? 'CAD',
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    'name': name,
    'address': address,
    'purchase_price': purchasePrice,
    'down_payment_percent': downPaymentPercent,
    'currency': currency,
    'created_at': createdAt.toIso8601String(),
  };

  @override
  List<Object?> get props => [id, userId, name, address, purchasePrice, currency];
}
