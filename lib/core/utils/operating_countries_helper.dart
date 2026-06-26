import 'package:country_code_picker/country_code_picker.dart';

/// Helpers for user operating-country preferences (buy / sell / distribute).
class OperatingCountriesHelper {
  OperatingCountriesHelper._();

  static final List<CountryCode> _allCountries = codes
      .map(CountryCode.fromJson)
      .where((c) => c.code != null && c.code!.length == 2)
      .toList()
    ..sort((a, b) => (a.name ?? '').compareTo(b.name ?? ''));

  static List<CountryCode> get allCountries => _allCountries;

  static CountryCode? countryForCode(String code) {
    final upper = code.toUpperCase();
    for (final country in _allCountries) {
      if (country.code?.toUpperCase() == upper) return country;
    }
    return null;
  }

  static String countryName(String code) =>
      countryForCode(code)?.name ?? code.toUpperCase();

  static String formatSummary({
    required bool operatesGlobally,
    required List<String> countryCodes,
  }) {
    if (operatesGlobally) return 'All countries';
    if (countryCodes.isEmpty) return 'No countries selected';

    final names = countryCodes.map(countryName).toList()..sort();
    if (names.length <= 3) return names.join(', ');
    return '${names.length} countries';
  }

  static List<String> normalizeCodes(Iterable<String> codes) {
    final normalized = codes
        .map((c) => c.trim().toUpperCase())
        .where((c) => c.length == 2)
        .toSet()
        .toList()
      ..sort();
    return normalized;
  }

  /// Infers ISO country code from an E.164 phone number (e.g. +91… → IN).
  static String? countryCodeFromPhone(String phone) {
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return null;

    final byDialLength = allCountries.toList()
      ..sort((a, b) {
        final aLen = a.dialCode?.replaceAll(RegExp(r'\D'), '').length ?? 0;
        final bLen = b.dialCode?.replaceAll(RegExp(r'\D'), '').length ?? 0;
        return bLen.compareTo(aLen);
      });

    for (final country in byDialLength) {
      final dialDigits = country.dialCode?.replaceAll(RegExp(r'\D'), '') ?? '';
      if (dialDigits.isNotEmpty && digits.startsWith(dialDigits)) {
        return country.code?.toUpperCase();
      }
    }
    return null;
  }
}
