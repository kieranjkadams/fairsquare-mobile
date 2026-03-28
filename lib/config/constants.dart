import 'package:flutter_dotenv/flutter_dotenv.dart';

abstract class AppConstants {
  // Supabase - loaded from .env file
  static String get supabaseUrl => dotenv.env['SUPABASE_URL'] ?? '';
  static String get supabaseAnonKey => dotenv.env['SUPABASE_ANON_KEY'] ?? '';

  // Admin
  static String get adminUserId => dotenv.env['ADMIN_USER_ID'] ?? '';

  // Storage buckets
  static const mortgageStatementsBucket = 'mortgage-statements';
  static const transactionDocumentsBucket = 'transaction-documents';

  // Signed URL TTL
  static const signedUrlTtlSeconds = 300; // 5 minutes

  // Transaction categories
  static const capitalCategories = ['down-payment'];
  static const incomeCategories = ['rental', 'other-income'];
  static const expenseCategories = [
    'property-tax',
    'insurance',
    'strata',
    'utilities',
    'maintenance',
    'closing-costs',
    'renovation',
    'legal',
    'other',
  ];
  static const mortgageCategories = [
    'mortgage',
    'mortgage-principal',
    'mortgage-interest',
    'mortgage-insurance',
    'mortgage-prepayment',
  ];

  // User-creatable categories (no mortgage categories)
  static List<String> get userCategories => [
    ...capitalCategories,
    ...incomeCategories,
    ...expenseCategories,
  ];

  static String categoryLabel(String category) {
    switch (category) {
      case 'down-payment':
        return 'Down Payment';
      case 'rental':
        return 'Rental Income';
      case 'other-income':
        return 'Other Income';
      case 'property-tax':
        return 'Property Tax';
      case 'insurance':
        return 'Insurance';
      case 'strata':
        return 'Strata';
      case 'utilities':
        return 'Utilities';
      case 'maintenance':
        return 'Maintenance';
      case 'closing-costs':
        return 'Closing Costs';
      case 'renovation':
        return 'Renovation';
      case 'legal':
        return 'Legal';
      case 'other':
        return 'Other';
      case 'mortgage':
        return 'Mortgage';
      case 'mortgage-principal':
        return 'Mortgage Principal';
      case 'mortgage-interest':
        return 'Mortgage Interest';
      case 'mortgage-insurance':
        return 'Mortgage Insurance';
      case 'mortgage-prepayment':
        return 'Mortgage Prepayment';
      default:
        return category;
    }
  }

  static String categoryType(String category) {
    if (capitalCategories.contains(category)) return 'capital';
    if (incomeCategories.contains(category)) return 'income';
    if (expenseCategories.contains(category)) return 'expense';
    if (mortgageCategories.contains(category)) return 'mortgage';
    return 'expense';
  }
}
