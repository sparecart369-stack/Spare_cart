import 'package:country_code_picker/country_code_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:spare_kart/core/theme/app_colors.dart';
import 'package:spare_kart/core/theme/app_typography.dart';

class PhoneNumberField extends StatefulWidget {
  const PhoneNumberField({
    super.key,
    required this.controller,
    this.validator,
    this.enabled = true,
    this.hintText = '98765 43210',
    this.onDialCodeChanged,
    this.onCountryChanged,
    this.initialCountryCode = 'IN',
  });

  final TextEditingController controller;
  final String? Function(String?)? validator;
  final bool enabled;
  final String hintText;
  final ValueChanged<String>? onDialCodeChanged;
  final ValueChanged<CountryCode>? onCountryChanged;
  final String initialCountryCode;

  @override
  State<PhoneNumberField> createState() => PhoneNumberFieldState();
}

class PhoneNumberFieldState extends State<PhoneNumberField> {
  late CountryCode _selectedCountry;

  @override
  void initState() {
    super.initState();
    _selectedCountry = CountryCode.fromCountryCode(widget.initialCountryCode);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onDialCodeChanged?.call(_selectedCountry.dialCode ?? '+91');
      widget.onCountryChanged?.call(_selectedCountry);
    });
  }

  String get dialCode => _selectedCountry.dialCode ?? '+91';

  String get countryCode => _selectedCountry.code ?? widget.initialCountryCode;

  String get fullPhoneNumber {
    final localDigits = widget.controller.text.replaceAll(RegExp(r'\D'), '');
    return '$dialCode$localDigits';
  }

  void _onCountryChanged(CountryCode country) {
    setState(() => _selectedCountry = country);
    widget.onDialCodeChanged?.call(country.dialCode ?? '+91');
    widget.onCountryChanged?.call(country);
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      keyboardType: TextInputType.phone,
      enabled: widget.enabled,
      style: AppTypography.textTheme.bodyLarge,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      validator: widget.validator,
      decoration: InputDecoration(
        hintText: widget.hintText,
        prefixIcon: _PhoneCountryPrefix(
          selectedCountry: _selectedCountry,
          enabled: widget.enabled,
          initialCountryCode: widget.initialCountryCode,
          onChanged: _onCountryChanged,
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 148, minHeight: 48),
      ),
    );
  }
}

class _PhoneCountryPrefix extends StatelessWidget {
  const _PhoneCountryPrefix({
    required this.selectedCountry,
    required this.enabled,
    required this.initialCountryCode,
    required this.onChanged,
  });

  final CountryCode selectedCountry;
  final bool enabled;
  final String initialCountryCode;
  final ValueChanged<CountryCode> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(width: 14),
        const Icon(Icons.phone_rounded, size: 22),
        const SizedBox(width: 6),
        CountryCodePicker(
          onChanged: onChanged,
          initialSelection: initialCountryCode,
          favorite: const ['+91', 'IN'],
          showCountryOnly: false,
          showOnlyCountryWhenClosed: false,
          alignLeft: false,
          enabled: enabled,
          padding: EdgeInsets.zero,
          textStyle: AppTypography.textTheme.bodyLarge,
          dialogTextStyle: AppTypography.textTheme.bodyMedium,
          searchDecoration: const InputDecoration(
            hintText: 'Search country',
            prefixIcon: Icon(Icons.search_rounded),
          ),
          dialogBackgroundColor: AppColors.surface,
          barrierColor: Colors.black54,
          builder: (country) => Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if ((country?.flagUri ?? selectedCountry.flagUri) != null)
                Image.asset(
                  (country?.flagUri ?? selectedCountry.flagUri)!,
                  package: 'country_code_picker',
                  width: 22,
                  height: 16,
                  fit: BoxFit.cover,
                ),
              const SizedBox(width: 6),
              Text(
                country?.dialCode ?? selectedCountry.dialCode ?? '+91',
                style: AppTypography.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 20,
                color: AppColors.textTertiary,
              ),
            ],
          ),
        ),
        Container(
          width: 1,
          height: 24,
          margin: const EdgeInsets.only(left: 6),
          color: AppColors.border,
        ),
      ],
    );
  }
}
