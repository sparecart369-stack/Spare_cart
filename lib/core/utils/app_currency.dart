import 'package:intl/intl.dart';

abstract final class AppCurrency {
  static const symbol = '₹';
  static const maxFilterPrice = 50000.0;

  static const standardShipping = 99.0;
  static const expressShipping = 199.0;

  static final NumberFormat _formatter = NumberFormat.currency(
    locale: 'en_IN',
    symbol: symbol,
  );

  static String format(num amount) => _formatter.format(amount);
}
