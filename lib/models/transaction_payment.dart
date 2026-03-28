import 'package:equatable/equatable.dart';

class TransactionPayment extends Equatable {
  final String id;
  final String transactionId;
  final String investorId;
  final double amount;
  final DateTime paymentDate;
  final String? description;
  final String? documentUrl;
  final String? documentName;
  final DateTime createdAt;

  const TransactionPayment({
    required this.id,
    required this.transactionId,
    required this.investorId,
    required this.amount,
    required this.paymentDate,
    this.description,
    this.documentUrl,
    this.documentName,
    required this.createdAt,
  });

  factory TransactionPayment.fromJson(Map<String, dynamic> json) {
    return TransactionPayment(
      id: json['id'] as String,
      transactionId: json['transaction_id'] as String,
      investorId: json['investor_id'] as String,
      amount: (json['amount'] as num).toDouble(),
      paymentDate: DateTime.parse(json['payment_date'] as String),
      description: json['description'] as String?,
      documentUrl: json['document_url'] as String?,
      documentName: json['document_name'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'transaction_id': transactionId,
    'investor_id': investorId,
    'amount': amount,
    'payment_date': paymentDate.toIso8601String().split('T')[0],
    'description': description,
    'document_url': documentUrl,
    'document_name': documentName,
    'created_at': createdAt.toIso8601String(),
  };

  @override
  List<Object?> get props => [id, transactionId, investorId, amount];
}
