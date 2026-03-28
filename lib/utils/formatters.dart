import 'package:intl/intl.dart';

class Formatters {
  static String currency(double amount, {String currency = 'CAD'}) {
    final format = NumberFormat.currency(symbol: _currencySymbol(currency), decimalDigits: 2);
    return format.format(amount);
  }

  static String compactCurrency(double amount, {String currency = 'CAD'}) {
    final format = NumberFormat.compactCurrency(symbol: _currencySymbol(currency), decimalDigits: 0);
    return format.format(amount);
  }

  static String percentage(double value) => '${value.toStringAsFixed(1)}%';

  static String date(DateTime date) => DateFormat('MMM d, yyyy').format(date);

  static String shortDate(DateTime date) => DateFormat('MMM d').format(date);

  static String _currencySymbol(String currency) {
    switch (currency.toUpperCase()) {
      case 'CAD': case 'USD': return '\$';
      case 'EUR': return '\u20AC';
      case 'GBP': return '\u00A3';
      default: return '\$';
    }
  }
}
