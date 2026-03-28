import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/transaction.dart';
import '../services/transaction_service.dart';

final transactionServiceProvider = Provider<TransactionService>((ref) => TransactionService());

final transactionsProvider = FutureProvider.family<List<Transaction>, String>((ref, propertyId) async {
  return ref.watch(transactionServiceProvider).getTransactions(propertyId);
});

final allTransactionsProvider = FutureProvider.family<List<Transaction>, String>((ref, propertyId) async {
  return ref.watch(transactionServiceProvider).getAllTransactions(propertyId);
});
