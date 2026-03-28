import '../models/investor.dart';
import '../models/transaction.dart';
import '../models/transaction_payment.dart';
import '../config/constants.dart';

class InvestorBalance {
  final Investor investor;
  final double ownershipPercent;
  final double expenseBalance;
  final double downPaymentContributed;

  const InvestorBalance({
    required this.investor,
    required this.ownershipPercent,
    required this.expenseBalance,
    required this.downPaymentContributed,
  });

  bool get owes => expenseBalance > 0.005;
  bool get isOwed => expenseBalance < -0.005;
  bool get isSettled => !owes && !isOwed;
}

class BalanceCalculator {
  static Map<String, double> calculateOwnership({
    required List<Investor> investors,
    required List<Transaction> allTransactions,
    required Map<String, List<TransactionPayment>> paymentsByTransaction,
  }) {
    final downPaymentTxns = allTransactions.where((t) => t.category == 'down-payment').toList();

    if (downPaymentTxns.isEmpty) {
      return {for (final inv in investors) inv.id: inv.plannedContribution};
    }

    final netContributions = <String, double>{};
    for (final inv in investors) {
      netContributions[inv.id] = 0;
    }

    for (final txn in downPaymentTxns) {
      if (txn.paidBy != null && netContributions.containsKey(txn.paidBy)) {
        netContributions[txn.paidBy!] = netContributions[txn.paidBy!]! + txn.amount;
      }

      final payments = paymentsByTransaction[txn.id] ?? [];
      for (final payment in payments) {
        if (netContributions.containsKey(payment.investorId)) {
          netContributions[payment.investorId] = netContributions[payment.investorId]! + payment.amount;
          if (txn.paidBy != null) {
            netContributions[txn.paidBy!] = netContributions[txn.paidBy!]! - payment.amount;
          }
        }
      }
    }

    final total = netContributions.values.fold(0.0, (s, v) => s + v);
    if (total <= 0) {
      return {for (final inv in investors) inv.id: inv.plannedContribution};
    }

    return {for (final entry in netContributions.entries) entry.key: (entry.value / total) * 100};
  }

  static List<InvestorBalance> calculateBalances({
    required List<Investor> investors,
    required List<Transaction> allTransactions,
    required Map<String, List<TransactionPayment>> paymentsByTransaction,
  }) {
    final ownership = calculateOwnership(
      investors: investors,
      allTransactions: allTransactions,
      paymentsByTransaction: paymentsByTransaction,
    );

    final expenseTxns = allTransactions.where((t) =>
        AppConstants.expenseCategories.contains(t.category) ||
        AppConstants.mortgageCategories.contains(t.category));

    final incomeTxns = allTransactions.where((t) =>
        AppConstants.incomeCategories.contains(t.category));

    final totalExpenses = expenseTxns.fold(0.0, (sum, t) => sum + t.amount);
    final totalMortgage = allTransactions
        .where((t) => AppConstants.mortgageCategories.contains(t.category))
        .fold(0.0, (sum, t) => sum + t.amount);
    final totalIncome = incomeTxns.fold(0.0, (sum, t) => sum + t.amount);

    final incomeAppliedToMortgage = totalIncome < totalMortgage ? totalIncome : totalMortgage;
    final surplusIncome = totalIncome - incomeAppliedToMortgage;
    final netExpenses = totalExpenses - surplusIncome;

    final expenseContributions = <String, double>{};
    for (final inv in investors) {
      expenseContributions[inv.id] = 0;
    }

    final relevantTxns = allTransactions.where((t) =>
        AppConstants.expenseCategories.contains(t.category) ||
        AppConstants.mortgageCategories.contains(t.category));

    for (final txn in relevantTxns) {
      if (txn.paidBy != null && expenseContributions.containsKey(txn.paidBy)) {
        expenseContributions[txn.paidBy!] = expenseContributions[txn.paidBy!]! + txn.amount;
      }

      final payments = paymentsByTransaction[txn.id] ?? [];
      for (final payment in payments) {
        if (expenseContributions.containsKey(payment.investorId)) {
          expenseContributions[payment.investorId] = expenseContributions[payment.investorId]! + payment.amount;
          if (txn.paidBy != null) {
            expenseContributions[txn.paidBy!] = expenseContributions[txn.paidBy!]! - payment.amount;
          }
        }
      }
    }

    return investors.map((inv) {
      final share = netExpenses * (inv.plannedContribution / 100);
      final contributed = expenseContributions[inv.id] ?? 0;
      final balance = share - contributed;

      final downPaymentTxns = allTransactions
          .where((t) => t.category == 'down-payment' && t.paidBy == inv.id);
      final downPayment = downPaymentTxns.fold(0.0, (sum, t) => sum + t.amount);

      return InvestorBalance(
        investor: inv,
        ownershipPercent: ownership[inv.id] ?? inv.plannedContribution,
        expenseBalance: balance,
        downPaymentContributed: downPayment,
      );
    }).toList();
  }
}
