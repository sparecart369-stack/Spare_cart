import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:spare_kart/bloc/listings/listings_bloc.dart';
import 'package:spare_kart/core/constants/app_assets.dart';
import 'package:spare_kart/core/theme/app_colors.dart';
import 'package:spare_kart/core/theme/app_decorations.dart';
import 'package:spare_kart/core/theme/app_typography.dart';
import 'package:spare_kart/core/utils/responsive.dart';
import 'package:spare_kart/core/widgets/catalog_image_tile.dart';
import 'package:spare_kart/core/widgets/common_widgets.dart';
import 'package:spare_kart/core/widgets/location_multi_select_field.dart';
import 'package:spare_kart/core/widgets/subcategory_picker.dart';
import 'package:spare_kart/core/widgets/vehicle_identifier_fields.dart';
import 'package:spare_kart/core/widgets/vehicle_picker_field.dart';
import 'package:spare_kart/data/dummy_data.dart';
import 'package:spare_kart/data/india_locations.dart';
import 'package:spare_kart/data/models/models.dart';
import 'package:spare_kart/data/parts_catalog.dart';
import 'package:spare_kart/data/vehicle_catalog.dart';

class FiltersRouteArgs {
  const FiltersRouteArgs({
    this.goToSearchOnApply = false,
    this.initialCategory,
  });

  final bool goToSearchOnApply;
  final String? initialCategory;
}

class FiltersScreen extends StatefulWidget {
  const FiltersScreen({super.key});

  @override
  State<FiltersScreen> createState() => _FiltersScreenState();
}

class _FiltersScreenState extends State<FiltersScreen> {
  String? _category;
  String? _subcategoryId;
  String? _make;
  String? _model;
  int? _year;
  PartCondition? _condition;
  SortOption _sort = SortOption.relevance;
  Set<String> _selectedStates = {};
  Set<String> _selectedDistricts = {};
  bool _loadedFromBloc = false;
  final _chassisController = TextEditingController();
  final _partNumberController = TextEditingController();

  @override
  void dispose() {
    _chassisController.dispose();
    _partNumberController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loadedFromBloc) return;
    _loadedFromBloc = true;
    final args = ModalRoute.of(context)?.settings.arguments;
    final initialCategory =
        args is FiltersRouteArgs ? args.initialCategory : null;
    final filters = context.read<ListingsBloc>().state.filters;
    _category = initialCategory ?? filters.category;
    _subcategoryId = PartsCatalog.instance
        .categoryForName(_category)
        ?.subcategoryByName(filters.subcategory)
        ?.id;
    _make = filters.make;
    _model = filters.model;
    _year = filters.year;
    _condition = filters.condition;
    _sort = filters.sortBy;
    _selectedStates = filters.states.toSet();
    _selectedDistricts = filters.districts.toSet();
    _chassisController.text = filters.chassisNumber ?? '';
    _partNumberController.text = filters.partNumber ?? '';
  }

  String? _trimmedOrNull(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  void _reset() {
    setState(() {
      _category = null;
      _subcategoryId = null;
      _make = null;
      _model = null;
      _year = null;
      _condition = null;
      _sort = SortOption.relevance;
      _selectedStates = {};
      _selectedDistricts = {};
      _chassisController.clear();
      _partNumberController.clear();
    });
  }

  bool get _goToSearchOnApply {
    final args = ModalRoute.of(context)?.settings.arguments;
    return args is FiltersRouteArgs && args.goToSearchOnApply;
  }

  void _apply() {
    context.read<ListingsBloc>().add(ListingFiltersApplied(PartFilters(
          category: _category,
          subcategory: PartsCatalog.instance
              .categoryForName(_category)
              ?.subcategoryById(_subcategoryId)
              ?.name,
          make: _make,
          model: _model,
          year: _year,
          chassisNumber: _trimmedOrNull(_chassisController.text),
          partNumber: _trimmedOrNull(_partNumberController.text),
          condition: _condition,
          states: _selectedStates.toList()..sort(),
          districts: _selectedDistricts.toList()..sort(),
          sortBy: _sort,
        )));
    Navigator.pop(context, _goToSearchOnApply);
  }

  @override
  Widget build(BuildContext context) {
    final r = Responsive(context);
    final pad = r.horizontalPadding();
    final compact = r.height < 720;
    final gap = compact ? 6.0 : 10.0;
    final sectionGap = compact ? 8.0 : 12.0;
    final catColumns = r.width < 360 ? 3 : 4;
    final locations = IndiaLocations.instance;
    final districtOptions = locations.districtsForStates(_selectedStates);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _Header(onReset: _reset),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.fromLTRB(pad, compact ? 4 : 8, pad, compact ? 12 : 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SectionLabel('Category', compact: compact),
                    SizedBox(height: gap),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final aspectRatio = r.width < 360 ? 1.05 : 1.15;
                        final cellWidth =
                            (constraints.maxWidth - (catColumns - 1) * gap) / catColumns;
                        final cellHeight = cellWidth / aspectRatio;
                        final rowCount = (categories.length / catColumns).ceil();
                        final gridHeight = rowCount * cellHeight + (rowCount - 1) * gap + 6;

                        return SizedBox(
                          height: gridHeight,
                          child: GridView.builder(
                            physics: const NeverScrollableScrollPhysics(),
                            clipBehavior: Clip.none,
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: catColumns,
                              mainAxisSpacing: gap,
                              crossAxisSpacing: gap,
                              childAspectRatio: aspectRatio,
                            ),
                            itemCount: categories.length,
                            itemBuilder: (context, i) {
                              final c = categories[i];
                              final selected = _category == c.$1;
                              return _CategoryTile(
                                label: c.$1,
                                icon: _categoryIcon(c.$2),
                                imageAsset: AppAssets.categoryImageFor(c.$1),
                                index: i,
                                selected: selected,
                                compact: compact,
                                onTap: () => setState(() {
                                  _category = selected ? null : c.$1;
                                  _subcategoryId = null;
                                }),
                              );
                            },
                          ),
                        );
                      },
                    ),
                    if (_category != null &&
                        PartsCatalog.instance
                            .subcategoriesForCategory(_category)
                            .isNotEmpty) ...[
                      SizedBox(height: sectionGap),
                      SubcategoryPicker(
                        categoryName: _category,
                        selectedSubcategoryId: _subcategoryId,
                        compact: compact,
                        onChanged: (v) => setState(() => _subcategoryId = v),
                      ),
                    ],
                    SizedBox(height: sectionGap),
                    _SectionLabel('Vehicle', compact: compact),
                    SizedBox(height: gap),
                    SizedBox(
                      child: _VehicleCard(
                        make: _make,
                        model: _model,
                        year: _year,
                        compact: compact,
                        chassisController: _chassisController,
                        partNumberController: _partNumberController,
                        onMakeChanged: (v) => setState(() {
                          _make = v;
                          _model = VehicleCatalog.instance.defaultModelFor(v);
                          _year = null;
                        }),
                        onModelChanged: (v) => setState(() => _model = v),
                        onYearChanged: (v) => setState(() => _year = v),
                      ),
                    ),
                    SizedBox(height: sectionGap),
                    _SectionLabel('Location', compact: compact),
                    SizedBox(height: gap),
                    Container(
                      padding: EdgeInsets.all(compact ? 10 : 12),
                      decoration: AppDecorations.elevatedCard(radius: AppDecorations.radiusMd),
                      child: Column(
                        children: [
                          LocationMultiSelectField(
                            label: 'State / Union Territory',
                            hint: 'Select states',
                            icon: Icons.map_outlined,
                            options: locations.states,
                            selected: _selectedStates,
                            compact: compact,
                            onChanged: (values) => setState(() {
                              _selectedStates = values;
                              final availableDistricts = locations.districtsForStates(values).toSet();
                              _selectedDistricts = _selectedDistricts
                                  .where(availableDistricts.contains)
                                  .toSet();
                            }),
                          ),
                          SizedBox(height: gap),
                          LocationMultiSelectField(
                            label: 'District',
                            hint: _selectedStates.isEmpty
                                ? 'Select districts'
                                : 'Select districts in chosen states',
                            icon: Icons.location_city_outlined,
                            options: districtOptions,
                            selected: _selectedDistricts,
                            compact: compact,
                            onChanged: (values) => setState(() => _selectedDistricts = values),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: sectionGap),
                    _SectionLabel('Condition', compact: compact),
                    SizedBox(height: gap),
                    SizedBox(
                      height: compact ? 34 : 38,
                      child: Row(
                        children: [
                          _ConditionChip(
                            label: 'All',
                            selected: _condition == null,
                            compact: compact,
                            onTap: () => setState(() => _condition = null),
                          ),
                          const SizedBox(width: 6),
                          _ConditionChip(
                            label: 'Used',
                            selected: _condition == PartCondition.used,
                            compact: compact,
                            onTap: () => setState(() => _condition = PartCondition.used),
                          ),
                          const SizedBox(width: 6),
                          _ConditionChip(
                            label: 'Refurbished',
                            selected: _condition == PartCondition.refurbished,
                            compact: compact,
                            onTap: () => setState(() => _condition = PartCondition.refurbished),
                          ),
                          const SizedBox(width: 6),
                          _ConditionChip(
                            label: 'New',
                            selected: _condition == PartCondition.newPart,
                            compact: compact,
                            onTap: () => setState(() => _condition = PartCondition.newPart),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: sectionGap),
                    _SectionLabel('Sort By', compact: compact),
                    SizedBox(height: gap),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final aspectRatio = compact ? 3.8 : 4.2;
                        const sortColumns = 2;
                        final cellWidth =
                            (constraints.maxWidth - (sortColumns - 1) * gap) / sortColumns;
                        final cellHeight = cellWidth / aspectRatio;
                        final rowCount = (SortOption.values.length / sortColumns).ceil();
                        final gridHeight = rowCount * cellHeight + (rowCount - 1) * gap;

                        return SizedBox(
                          height: gridHeight,
                          child: GridView.count(
                            physics: const NeverScrollableScrollPhysics(),
                            crossAxisCount: sortColumns,
                            mainAxisSpacing: gap,
                            crossAxisSpacing: gap,
                            childAspectRatio: aspectRatio,
                            children: SortOption.values.map((s) {
                              final selected = _sort == s;
                              return _SortTile(
                                label: _sortLabel(s),
                                selected: selected,
                                compact: compact,
                                onTap: () => setState(() => _sort = s),
                              );
                            }).toList(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(pad, compact ? 8 : 12, pad, compact ? 10 : 14),
              child: PrimaryButton(
                label: 'Apply Filters',
                height: compact ? 50 : 54,
                icon: Icons.tune_rounded,
                onPressed: _apply,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _categoryIcon(String name) => switch (name) {
        'engineering' => Icons.engineering_rounded,
        'settings' => Icons.settings_rounded,
        'ac_unit' => Icons.ac_unit_rounded,
        'directions_car' => Icons.directions_car_rounded,
        'height' => Icons.height_rounded,
        'stop_circle' => Icons.stop_circle_rounded,
        'bolt' => Icons.bolt_rounded,
        'star' => Icons.star_rounded,
        'memory' => Icons.memory_rounded,
        'event_seat' => Icons.event_seat_rounded,
        'tire_repair' => Icons.tire_repair_rounded,
        'lightbulb' => Icons.lightbulb_rounded,
        'album' => Icons.album_rounded,
        'local_gas_station' => Icons.local_gas_station_rounded,
        _ => Icons.category_rounded,
      };

  String _sortLabel(SortOption s) => switch (s) {
        SortOption.relevance => 'Relevance',
        SortOption.newest => 'Newest',
      };
}

class _Header extends StatelessWidget {
  const _Header({required this.onReset});

  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(4, 4, 8, 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.primaryLight,
            AppColors.background.withValues(alpha: 0),
          ],
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            style: IconButton.styleFrom(
              backgroundColor: AppColors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDecorations.radiusSm),
              ),
            ),
          ),
          Expanded(
            child: Text(
              'Filters',
              textAlign: TextAlign.center,
              style: AppTypography.textTheme.titleLarge,
            ),
          ),
          TextButton.icon(
            onPressed: onReset,
            icon: const Icon(Icons.restart_alt_rounded, size: 16),
            label: const Text('Reset'),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              textStyle: AppTypography.textTheme.labelMedium,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.title, {required this.compact});

  final String title;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Text(
      title.toUpperCase(),
      style: AppTypography.overline.copyWith(
        fontSize: compact ? 10 : 11,
        color: AppColors.primary.withValues(alpha: 0.75),
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    required this.label,
    required this.icon,
    this.imageAsset,
    required this.index,
    required this.selected,
    required this.compact,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final String? imageAsset;
  final int index;
  final bool selected;
  final bool compact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return CatalogImageTile(
      label: label,
      imageAsset: imageAsset,
      fallbackIcon: icon,
      colorIndex: index,
      selected: selected,
      compact: compact,
      onTap: onTap,
    );
  }
}

class _VehicleCard extends StatelessWidget {
  const _VehicleCard({
    required this.make,
    required this.model,
    required this.year,
    required this.compact,
    required this.chassisController,
    required this.partNumberController,
    required this.onMakeChanged,
    required this.onModelChanged,
    required this.onYearChanged,
  });

  final String? make;
  final String? model;
  final int? year;
  final bool compact;
  final TextEditingController chassisController;
  final TextEditingController partNumberController;
  final ValueChanged<String?> onMakeChanged;
  final ValueChanged<String?> onModelChanged;
  final ValueChanged<int?> onYearChanged;

  @override
  Widget build(BuildContext context) {
    final years = VehicleCatalog.vehicleYears;
    final innerGap = compact ? 6.0 : 8.0;
    final catalog = VehicleCatalog.instance;
    final modelOptions = catalog.modelPickerItems(make);
    final modelLabel = catalog.modelDisplayLabel(make: make, model: model);

    return Container(
      padding: EdgeInsets.all(compact ? 10 : 12),
      decoration: AppDecorations.elevatedCard(radius: AppDecorations.radiusMd),
      child: Column(
        children: [
          VehiclePickerField(
            hint: 'Make',
            value: make,
            items: catalog.makes,
            icon: Icons.directions_car_rounded,
            compact: compact,
            onChanged: onMakeChanged,
          ),
          SizedBox(height: innerGap),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: VehiclePickerField(
                  hint: 'Model',
                  value: modelLabel,
                  items: modelOptions,
                  icon: Icons.apps_rounded,
                  enabled: make != null,
                  compact: compact,
                  onChanged: make == null
                      ? null
                      : (v) {
                          if (v == null) return;
                          onModelChanged(
                            catalog.modelValueFromPicker(make: make!, pickerLabel: v),
                          );
                        },
                ),
              ),
              SizedBox(width: innerGap),
              Expanded(
                flex: 2,
                child: _dropdown<int>(
                  hint: 'Year',
                  value: year,
                  items: years,
                  onChanged: model == null ? null : onYearChanged,
                  icon: Icons.calendar_month_rounded,
                  enabled: model != null,
                  display: (v) => '$v',
                  compact: compact,
                ),
              ),
            ],
          ),
          SizedBox(height: innerGap),
          VehicleIdentifierFields(
            chassisController: chassisController,
            partNumberController: partNumberController,
            compact: compact,
          ),
        ],
      ),
    );
  }

  Widget _dropdown<T>({
    required String hint,
    required T? value,
    required List<T> items,
    required ValueChanged<T?>? onChanged,
    required IconData icon,
    required bool compact,
    String Function(T)? display,
    bool enabled = true,
  }) {
    final hasValue = value != null;
    return DropdownButtonFormField<T>(
      key: ValueKey('$hint-$value-${enabled ? 'on' : 'off'}'),
      initialValue: value,
      isExpanded: true,
      isDense: true,
      hint: Text(
        hint,
        style: AppTypography.textTheme.bodySmall?.copyWith(
          color: enabled ? AppColors.textTertiary : AppColors.textTertiary.withValues(alpha: 0.45),
          fontWeight: FontWeight.w500,
        ),
        overflow: TextOverflow.ellipsis,
      ),
      style: AppTypography.textTheme.bodySmall?.copyWith(
        color: AppColors.textPrimary,
        fontWeight: FontWeight.w600,
      ),
      icon: Icon(
        Icons.keyboard_arrow_down_rounded,
        size: compact ? 18 : 20,
        color: enabled ? AppColors.textTertiary : AppColors.textTertiary.withValues(alpha: 0.4),
      ),
      dropdownColor: AppColors.surface,
      borderRadius: BorderRadius.circular(AppDecorations.radiusSm),
      decoration: InputDecoration(
        filled: true,
        fillColor: enabled ? AppColors.surfaceElevated : AppColors.chipBg,
        contentPadding: EdgeInsets.symmetric(horizontal: compact ? 10 : 12, vertical: compact ? 8 : 10),
        prefixIcon: Icon(
          icon,
          size: compact ? 16 : 18,
          color: hasValue
              ? AppColors.primary
              : enabled
                  ? AppColors.textTertiary
                  : AppColors.textTertiary.withValues(alpha: 0.4),
        ),
        prefixIconConstraints: BoxConstraints(minWidth: compact ? 36 : 40, minHeight: compact ? 36 : 40),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDecorations.radiusSm),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDecorations.radiusSm),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDecorations.radiusSm),
          borderSide: BorderSide(color: AppColors.border.withValues(alpha: 0.5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDecorations.radiusSm),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
      items: items
          .map(
            (v) => DropdownMenuItem(
              value: v,
              child: Text(
                display != null ? display(v) : '$v',
                overflow: TextOverflow.ellipsis,
                style: AppTypography.textTheme.bodySmall,
              ),
            ),
          )
          .toList(),
      onChanged: onChanged,
    );
  }
}

class _ConditionChip extends StatelessWidget {
  const _ConditionChip({
    required this.label,
    required this.selected,
    required this.compact,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final bool compact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(compact ? 8 : 10),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            alignment: Alignment.center,
            padding: EdgeInsets.symmetric(horizontal: compact ? 4 : 6),
            decoration: BoxDecoration(
              gradient: selected ? AppColors.primaryGradient : null,
              color: selected ? null : AppColors.surface,
              borderRadius: BorderRadius.circular(compact ? 8 : 10),
              border: Border.all(
                color: selected ? Colors.transparent : AppColors.border,
              ),
              boxShadow: selected ? AppDecorations.shadowSm : null,
            ),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.textTheme.labelSmall?.copyWith(
                fontSize: compact ? 10 : 11,
                fontWeight: FontWeight.w700,
                color: selected ? Colors.white : AppColors.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SortTile extends StatelessWidget {
  const _SortTile({
    required this.label,
    required this.selected,
    required this.compact,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final bool compact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDecorations.radiusSm),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: EdgeInsets.symmetric(horizontal: compact ? 8 : 10),
          decoration: BoxDecoration(
            color: selected ? AppColors.primaryLight : AppColors.surface,
            borderRadius: BorderRadius.circular(AppDecorations.radiusSm),
            border: Border.all(
              color: selected ? AppColors.primary.withValues(alpha: 0.35) : AppColors.border,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: compact ? 14 : 16,
                height: compact ? 14 : 16,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selected ? AppColors.primary : AppColors.textTertiary,
                    width: 1.5,
                  ),
                  color: selected ? AppColors.primary : Colors.transparent,
                ),
                child: selected
                    ? Icon(Icons.check_rounded, size: compact ? 9 : 10, color: Colors.white)
                    : null,
              ),
              SizedBox(width: compact ? 6 : 8),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.textTheme.labelSmall?.copyWith(
                    fontSize: compact ? 11 : 12,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                    color: selected ? AppColors.primary : AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
