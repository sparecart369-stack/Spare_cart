abstract final class AppCommission {
  static const percent = 5.0;

  static double fee(double price) => price * percent / 100;

  static double sellerEarnings(double price) => price - fee(price);
}
