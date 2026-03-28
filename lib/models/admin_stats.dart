import 'package:equatable/equatable.dart';

class AdminStats extends Equatable {
  final int totalUsers;
  final int totalProperties;
  final int totalInvestors;
  final int totalTransactions;
  final int newUsersThisMonth;
  final int newPropertiesThisMonth;
  final int transactionsThisMonth;

  const AdminStats({required this.totalUsers, required this.totalProperties, required this.totalInvestors, required this.totalTransactions, required this.newUsersThisMonth, required this.newPropertiesThisMonth, required this.transactionsThisMonth});

  factory AdminStats.fromJson(Map<String, dynamic> json) {
    return AdminStats(
      totalUsers: json['total_users'] as int? ?? 0,
      totalProperties: json['total_properties'] as int? ?? 0,
      totalInvestors: json['total_investors'] as int? ?? 0,
      totalTransactions: json['total_transactions'] as int? ?? 0,
      newUsersThisMonth: json['new_users_this_month'] as int? ?? 0,
      newPropertiesThisMonth: json['new_properties_this_month'] as int? ?? 0,
      transactionsThisMonth: json['transactions_this_month'] as int? ?? 0,
    );
  }

  @override
  List<Object?> get props => [totalUsers, totalProperties, totalInvestors, totalTransactions];
}
