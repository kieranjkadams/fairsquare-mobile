import 'dart:io';
import 'package:uuid/uuid.dart';
import 'supabase_service.dart';
import '../config/constants.dart';
import '../models/transaction.dart';
import '../models/transaction_payment.dart';

class TransactionService {
  final _client = SupabaseService.client;
  final _uuid = const Uuid();

  Future<List<Transaction>> getTransactions(String propertyId) async {
    final response = await _client
        .from('transactions')
        .select()
        .eq('property_id', propertyId)
        .eq('is_auto_generated', false)
        .order('transaction_date', ascending: false);

    return response.map<Transaction>((e) => Transaction.fromJson(e)).toList();
  }

  Future<List<Transaction>> getAllTransactions(String propertyId) async {
    final response = await _client
        .from('transactions')
        .select()
        .eq('property_id', propertyId)
        .order('transaction_date', ascending: false);

    return response.map<Transaction>((e) => Transaction.fromJson(e)).toList();
  }

  Future<List<TransactionPayment>> getTransactionPayments(String transactionId) async {
    final response = await _client
        .from('transaction_payments')
        .select()
        .eq('transaction_id', transactionId)
        .order('payment_date');

    return response.map<TransactionPayment>((e) => TransactionPayment.fromJson(e)).toList();
  }

  Future<Transaction> createTransaction({
    required String propertyId,
    required String category,
    required double amount,
    required DateTime transactionDate,
    String? description,
    String? paidBy,
    File? document,
    String? documentName,
  }) async {
    final userId = SupabaseService.currentUserId!;
    final type = AppConstants.categoryType(category);

    String? docUrl;
    String? docFileName;
    bool hasDoc = false;

    if (document != null) {
      final txId = _uuid.v4();
      final ext = documentName?.split('.').last ?? 'jpg';
      final path = '$propertyId/$txId/${documentName ?? 'document.$ext'}';

      await SupabaseService.storage
          .from(AppConstants.transactionDocumentsBucket)
          .upload(path, document);

      docUrl = path;
      docFileName = documentName ?? 'document.$ext';
      hasDoc = true;
    }

    final response = await _client
        .from('transactions')
        .insert({
          'property_id': propertyId,
          'type': type,
          'category': category,
          'amount': amount,
          'paid_by': paidBy,
          'transaction_date': transactionDate.toIso8601String().split('T')[0],
          'description': description,
          'has_document': hasDoc,
          'document_url': docUrl,
          'document_name': docFileName,
          'created_by': userId,
        })
        .select()
        .single();

    return Transaction.fromJson(response);
  }

  Future<String> getSignedUrl(String path) async {
    return await SupabaseService.storage
        .from(AppConstants.transactionDocumentsBucket)
        .createSignedUrl(path, AppConstants.signedUrlTtlSeconds);
  }
}
