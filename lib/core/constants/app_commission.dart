abstract final class AppCommission {
  static const percent = 5.0;

  static double fee(double price) => price * percent / 100;

  static double sellerEarnings(double price) => price - fee(price);

  static const payoutScheduleMessage =
      'Every Friday night at 7 PM, all amounts will be transferred to your seller account.';
}
