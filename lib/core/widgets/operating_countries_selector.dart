import 'package:country_code_picker/country_code_picker.dart';
import 'package:flutter/material.dart';
import 'package:spare_kart/core/theme/app_colors.dart';
import 'package:spare_kart/core/theme/app_typography.dart';
import 'package:spare_kart/core/utils/operating_countries_helper.dart';
import 'package:spare_kart/data/models/models.dart';

class OperatingCountriesSelector extends StatefulWidget {
  const OperatingCountriesSelector({
    super.key,
    this.initial = const OperatingCountriesSelection(),
    this.enabled = true,
    this.showValidationError = false,
    this.onSelectionChanged,
  });

  final OperatingCountriesSelection initial;
  final bool enabled;
  final bool showValidationError;
  final ValueChanged<OperatingCountriesSelection>? onSelectionChanged;

  @override
  State<OperatingCountriesSelector> createState() =>
      OperatingCountriesSelectorState();
}

class OperatingCountriesSelectorState extends State<OperatingCountriesSelector> {
  late bool _operatesGlobally;
  late Set<String> _selectedCodes;
  String? _linkedPhoneCountryCode;

  @override
  void initState() {
    super.initState();
    _operatesGlobally = false;
    _selectedCodes = _resolveInitialCodes(widget.initial);
    if (_selectedCodes.length == 1) {
      _linkedPhoneCountryCode = _selectedCodes.first;
    }
  }

  Set<String> _resolveInitialCodes(OperatingCountriesSelection initial) {
    final codes = initial.countryCodes.map((c) => c.toUpperCase()).toSet();
    if (codes.isEmpty) {
      return {OperatingCountriesHelper.defaultCountryCode};
    }
    return codes;
  }

  @override
  void didUpdateWidget(covariant OperatingCountriesSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initial != widget.initial) {
      _operatesGlobally = false;
      _selectedCodes = _resolveInitialCodes(widget.initial);
      if (_selectedCodes.length == 1) {
        _linkedPhoneCountryCode = _selectedCodes.first;
      }
    }
  }

  /// Keeps operating countries in sync with the phone country picker.
  void applyPhoneCountry(String countryCode) {
    final upper = countryCode.toUpperCase();
    if (_operatesGlobally) {
      _linkedPhoneCountryCode = upper;
      return;
    }

    setState(() {
      if (_linkedPhoneCountryCode != null) {
        _selectedCodes.remove(_linkedPhoneCountryCode);
      }
      _linkedPhoneCountryCode = upper;
      _selectedCodes.add(upper);
    });
    _notifySelectionChanged();
  }

  OperatingCountriesSelection get selection => OperatingCountriesSelection(
        operatesGlobally: _operatesGlobally,
        countryCodes: OperatingCountriesHelper.normalizeCodes(_selectedCodes),
      );

  void _notifySelectionChanged() {
    widget.onSelectionChanged?.call(selection);
  }

  String? validate() {
    if (selection.isValid) return null;
    return 'Select at least one country';
  }

  // Future<void> _openCountryPicker() async {
  //   if (!widget.enabled || _operatesGlobally) return;
  //
  //   final picked = await showModalBottomSheet<Set<String>>(
  //     context: context,
  //     isScrollControlled: true,
  //     backgroundColor: Colors.transparent,
  //     builder: (context) => _CountryMultiSelectSheet(
  //       initialSelection: _selectedCodes,
  //       countries: OperatingCountriesHelper.allCountries,
  //     ),
  //   );
  //
  //   if (picked != null) {
  //     setState(() {
  //       _selectedCodes = picked;
  //     });
  //     _notifySelectionChanged();
  //   }
  // }
  //
  // void _removeCountry(String code) {
  //   if (!widget.enabled || _operatesGlobally) return;
  //   setState(() {
  //     final upper = code.toUpperCase();
  //     _selectedCodes.remove(upper);
  //     if (_linkedPhoneCountryCode == upper) {
  //       _linkedPhoneCountryCode = null;
  //     }
  //   });
  //   _notifySelectionChanged();
  // }

  @override
  Widget build(BuildContext context) {
    // Hidden while all users default to India.
    return const SizedBox.shrink();

    // final hasError = widget.showValidationError && validate() != null;
    //
    // return Column(
    //   crossAxisAlignment: CrossAxisAlignment.start,
    //   children: [
        // Material(
        //   color: AppColors.surface,
        //   elevation: 0,
        //   shape: RoundedRectangleBorder(
        //     borderRadius: BorderRadius.circular(AppDecorations.radiusMd),
        //     side: BorderSide(color: AppColors.border.withValues(alpha: 0.6)),
        //   ),
        //   clipBehavior: Clip.antiAlias,
        //   child: SwitchListTile(
        //     contentPadding: const EdgeInsets.fromLTRB(16, 4, 12, 4),
        //     value: _operatesGlobally,
        //     onChanged: widget.enabled
        //         ? (value) {
        //             setState(() {
        //               if (value) {
        //                 _cachedCountryCodes = Set<String>.from(_selectedCodes);
        //                 _operatesGlobally = true;
        //               } else {
        //                 _operatesGlobally = false;
        //                 _selectedCodes = _cachedCountryCodes.isNotEmpty
        //                     ? Set<String>.from(_cachedCountryCodes)
        //                     : (_linkedPhoneCountryCode != null
        //                         ? {_linkedPhoneCountryCode!}
        //                         : <String>{});
        //               }
        //             });
        //             _notifySelectionChanged();
        //           }
        //         : null,
        //     title: Text('All countries', style: AppTypography.textTheme.titleSmall),
        //     subtitle: Text(
        //       'Buy, sell, and distribute spares worldwide',
        //       style: AppTypography.textTheme.bodySmall?.copyWith(
        //         color: AppColors.textTertiary,
        //       ),
        //     ),
        //     activeThumbColor: AppColors.primary,
        //     tileColor: Colors.transparent,
        //   ),
        // ),
        // Text(
        //   'Selected countries',
        //   style: AppTypography.textTheme.labelMedium,
        // ),
        // const SizedBox(height: 8),
        // if (_selectedCodes.isEmpty)
        //   Text(
        //     'Choose where you buy, sell, or distribute spares',
        //     style: AppTypography.textTheme.bodySmall?.copyWith(
        //       color: AppColors.textTertiary,
        //     ),
        //   )
        // else
        //   Wrap(
        //     spacing: 8,
        //     runSpacing: 8,
        //     children: _selectedCodes.map((code) {
        //       final country = OperatingCountriesHelper.countryForCode(code);
        //       return InputChip(
        //         label: Text(country?.name ?? code),
        //         avatar: country?.flagUri != null
        //             ? ClipRRect(
        //                 borderRadius: BorderRadius.circular(2),
        //                 child: Image.asset(
        //                   country!.flagUri!,
        //                   package: 'country_code_picker',
        //                   width: 20,
        //                   height: 14,
        //                   fit: BoxFit.cover,
        //                 ),
        //               )
        //             : null,
        //         onDeleted: widget.enabled ? () => _removeCountry(code) : null,
        //         deleteIconColor: AppColors.textTertiary,
        //         backgroundColor: AppColors.primary.withValues(alpha: 0.08),
        //         side: BorderSide(color: AppColors.primary.withValues(alpha: 0.2)),
        //       );
        //     }).toList(),
        //   ),
        // const SizedBox(height: 12),
        // OutlinedButton.icon(
        //   onPressed: widget.enabled ? _openCountryPicker : null,
        //   icon: const Icon(Icons.add_location_alt_outlined, size: 18),
        //   label: Text(_selectedCodes.isEmpty ? 'Add countries' : 'Add more countries'),
        //   style: OutlinedButton.styleFrom(
        //     foregroundColor: AppColors.primary,
        //     side: BorderSide(color: AppColors.primary.withValues(alpha: 0.35)),
        //     padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        //   ),
        // ),
        // if (hasError) ...[
        //   const SizedBox(height: 8),
        //   Text(
        //     validate()!,
        //     style: AppTypography.textTheme.bodySmall?.copyWith(color: AppColors.error),
        //   ),
        // ],
    //   ],
    // );
  }
}

class _CountryMultiSelectSheet extends StatefulWidget {
  const _CountryMultiSelectSheet({
    required this.initialSelection,
    required this.countries,
  });

  final Set<String> initialSelection;
  final List<CountryCode> countries;

  @override
  State<_CountryMultiSelectSheet> createState() =>
      _CountryMultiSelectSheetState();
}

class _CountryMultiSelectSheetState extends State<_CountryMultiSelectSheet> {
  late Set<String> _selection;
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _selection = Set<String>.from(widget.initialSelection);
    _searchController.addListener(() {
      setState(() => _query = _searchController.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<CountryCode> get _filtered {
    if (_query.isEmpty) return widget.countries;
    return widget.countries.where((country) {
      final name = (country.name ?? '').toLowerCase();
      final code = (country.code ?? '').toLowerCase();
      return name.contains(_query) || code.contains(_query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.85,
        ),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Select countries',
                      style: AppTypography.textTheme.titleMedium,
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, _selection),
                    child: const Text('Done'),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  hintText: 'Search country',
                  prefixIcon: Icon(Icons.search_rounded),
                ),
              ),
            ),
            if (_selection.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '${_selection.length} selected',
                    style: AppTypography.textTheme.labelSmall?.copyWith(
                      color: AppColors.textTertiary,
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 8),
            Flexible(
              child: ListTileTheme(
                data: ListTileThemeData(
                  tileColor: Colors.transparent,
                  selectedTileColor: AppColors.primary.withValues(alpha: 0.08),
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _filtered.length,
                  itemBuilder: (context, index) {
                    final country = _filtered[index];
                    final code = country.code!.toUpperCase();
                    final selected = _selection.contains(code);

                    return CheckboxListTile(
                      value: selected,
                      onChanged: (value) {
                        setState(() {
                          if (value == true) {
                            _selection.add(code);
                          } else {
                            _selection.remove(code);
                          }
                        });
                      },
                      secondary: Image.asset(
                        country.flagUri!,
                        package: 'country_code_picker',
                        width: 28,
                      ),
                      title: Text(country.name ?? code),
                      subtitle: Text(code, style: AppTypography.textTheme.bodySmall),
                      activeColor: AppColors.primary,
                      tileColor: Colors.transparent,
                      selectedTileColor:
                          AppColors.primary.withValues(alpha: 0.08),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
