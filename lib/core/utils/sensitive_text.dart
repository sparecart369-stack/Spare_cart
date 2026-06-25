abstract final class SensitiveText {
  static String mask(String value, {required bool visible, int trailingVisible = 4}) {
    if (visible || value.isEmpty) return value;
    if (value.length <= trailingVisible) {
      return '•' * value.length;
    }
    return '${'•' * (value.length - trailingVisible)}${value.substring(value.length - trailingVisible)}';
  }

  static String maskUpi(String upi, bool visible) {
    if (visible || upi.isEmpty) return upi;
    final at = upi.indexOf('@');
    if (at <= 0) return mask(upi, visible: false, trailingVisible: 3);
    final hidden = '•' * (at > 1 ? at - 1 : 1);
    return '${upi[0]}$hidden${upi.substring(at)}';
  }

  static String maskIfsc(String ifsc, bool visible) {
    if (visible || ifsc.isEmpty) return ifsc;
    if (ifsc.length <= 4) return '•' * ifsc.length;
    return '${ifsc.substring(0, 4)}${'•' * (ifsc.length - 4)}';
  }
}
