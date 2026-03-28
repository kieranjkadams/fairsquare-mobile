import 'package:equatable/equatable.dart';

class Mortgage extends Equatable {
  final String id;
  final String propertyId;
  final double balance;
  final DateTime balanceDate;
  final double rate;
  final double payment;
  final String frequency;
  final DateTime nextPayment;
  final double? pmiAmount;
  final String? lender;
  final DateTime? renewalDate;
  final String rateType;
  final String? paidBy;
  final DateTime? originationDate;
  final double? originalBalance;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Mortgage({
    required this.id, required this.propertyId, required this.balance,
    required this.balanceDate, required this.rate, required this.payment,
    required this.frequency, required this.nextPayment, this.pmiAmount,
    this.lender, this.renewalDate, required this.rateType, this.paidBy,
    this.originationDate, this.originalBalance, required this.createdAt,
    required this.updatedAt,
  });

  factory Mortgage.fromJson(Map<String, dynamic> json) {
    return Mortgage(
      id: json['id'] as String, propertyId: json['property_id'] as String,
      balance: (json['balance'] as num).toDouble(),
      balanceDate: DateTime.parse(json['balance_date'] as String),
      rate: (json['rate'] as num).toDouble(),
      payment: (json['payment'] as num).toDouble(),
      frequency: json['frequency'] as String,
      nextPayment: DateTime.parse(json['next_payment'] as String),
      pmiAmount: (json['pmi_amount'] as num?)?.toDouble(),
      lender: json['lender'] as String?,
      renewalDate: json['renewal_date'] != null ? DateTime.parse(json['renewal_date'] as String) : null,
      rateType: json['rate_type'] as String,
      paidBy: json['paid_by'] as String?,
      originationDate: json['origination_date'] != null ? DateTime.parse(json['origination_date'] as String) : null,
      originalBalance: (json['original_balance'] as num?)?.toDouble(),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  @override
  List<Object?> get props => [id, propertyId, balance, rate];
}
