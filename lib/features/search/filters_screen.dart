import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:spare_kart/bloc/listings/listings_bloc.dart';
import 'package:spare_kart/core/constants/app_assets.dart';
import 'package:spare_kart/core/theme/app_colors.dart';
import 'package:spare_kart/core/theme/app_decorations.dart';
import 'package:spare_kart/core/theme/app_typography.dart';
import 'package:spare_kart/core/utils/responsive.dart';
import 'package:spare_kart/core/widgets/common_widgets.dart';
import 'package:spare_kart/data/dummy_data.dart';
import 'package:spare_kart/data/models/models.dart';

class FiltersScreen extends StatefulWidget {
  const FiltersScreen({super.key});

  @override
  State<FiltersScreen> createState() => _FiltersScreenState();
}

class _FiltersScreenState extends State<FiltersScreen> {
  String? _category;
  String? _make;
  String? _model;
  int? _year;
  PartCondition? _condition;
  double _minPrice = 0;
  double _maxPrice = 2000;
  SortOption _sort = SortOption.relevance;

  void _reset() {
    setState(() {
      _category = null;
      _make = null;
      _model = null;
      _year = null;
      _condition = null;
      _minPrice = 0;
      _maxPrice = 2000;
      _sort = SortOption.relevance;
    });
  }

  void _apply() {
    context.read<ListingsBloc>().add(ListingFiltersApplied(PartFilters(
          category: _category,
          make: _make,
          model: _model,
          year: _year,
          condition: _condition,
          minPrice: _minPrice,
          maxPrice: _maxPrice,
          sortBy: _sort,
        )));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final r = Responsive(context);
    final pad = r.horizontalPadding();
    final compact = r.height < 720;
    final gap = compact ? 6.0 : 10.0;
    final sectionGap = compact ? 8.0 : 12.0;
    final catColumns = r.width < 360 ? 3 : 4;

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
                                imageAsset: _categoryImageAsset(c.$1),
                                index: i,
                                selected: selected,
                                compact: compact,
                                onTap: () => setState(() => _category = selected ? null : c.$1),
                              );
                            },
                          ),
                        );
                      },
                    ),
                    SizedBox(height: sectionGap),
                    _SectionLabel('Vehicle', compact: compact),
                    SizedBox(height: gap),
                    SizedBox(
                      height: compact ? 108 : 120,
                      child: _VehicleCard(
                        make: _make,
                        model: _model,
                        year: _year,
                        compact: compact,
                        onMakeChanged: (v) => setState(() {
                          _make = v;
                          _model = null;
                          _year = null;
                        }),
                        onModelChanged: (v) => setState(() => _model = v),
                        onYearChanged: (v) => setState(() => _year = v),
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
                    _SectionLabel('Price Range', compact: compact),
                    SizedBox(height: gap),
                    SizedBox(
                      height: compact ? 72 : 84,
                      child: _PriceRangeCard(
                        minPrice: _minPrice,
                        maxPrice: _maxPrice,
                        compact: compact,
                        onChanged: (min, max) => setState(() {
                          _minPrice = min;
                          _maxPrice = max;
                        }),
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
        'directions_car' => Icons.directions_car_rounded,
        'lightbulb' => Icons.lightbulb_rounded,
        'tire_repair' => Icons.tire_repair_rounded,
        'stop_circle' => Icons.stop_circle_rounded,
        'height' => Icons.height_rounded,
        'bolt' => Icons.bolt_rounded,
        _ => Icons.category_rounded,
      };

  String? _categoryImageAsset(String name) => switch (name) {
        'Engine' => AppAssets.categoryEngine,
        'Transmission' => AppAssets.categoryTransmission,
        'Body Parts' => AppAssets.categoryBodyParts,
        'Lighting' => AppAssets.categoryLighting,
        _ => null,
      };

  String _sortLabel(SortOption s) => switch (s) {
        SortOption.relevance => 'Relevance',
        SortOption.priceLow => 'Price ↑',
        SortOption.priceHigh => 'Price ↓',
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

  static const _iconColors = [
    Color(0xFF2563EB),
    Color(0xFF059669),
    Color(0xFFD97706),
    Color(0xFF9333EA),
    Color(0xFFDC2626),
    Color(0xFF0284C7),
    Color(0xFF7C3AED),
    Color(0xFF10B981),
  ];

  @override
  Widget build(BuildContext context) {
    final iconSize = compact ? 28.0 : 32.0;
    final iconColor = _iconColors[index % _iconColors.length];

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDecorations.radiusSm),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: const Color(0xFF141414),
            borderRadius: BorderRadius.circular(AppDecorations.radiusSm),
            border: Border.all(
              color: selected ? AppColors.primary : Colors.transparent,
              width: selected ? 2 : 0,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : AppDecorations.shadowSm,
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (imageAsset != null)
                Image.asset(
                  imageAsset!,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                )
              else
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        iconColor.withValues(alpha: 0.35),
                        const Color(0xFF141414),
                      ],
                    ),
                  ),
                  child: Align(
                    alignment: const Alignment(0, -0.15),
                    child: Icon(icon, size: iconSize, color: iconColor.withValues(alpha: 0.85)),
                  ),
                ),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.55),
                      Colors.black.withValues(alpha: 0.92),
                    ],
                    stops: const [0.35, 0.72, 1.0],
                  ),
                ),
              ),
              if (selected)
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.18),
                  ),
                ),
              Positioned(
                left: compact ? 6 : 8,
                right: compact ? 6 : 8,
                bottom: compact ? 6 : 8,
                child: Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.textTheme.labelSmall?.copyWith(
                    fontSize: compact ? 9 : 10,
                    fontWeight: FontWeight.w700,
                    height: 1.15,
                    color: Colors.white,
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

class _VehicleCard extends StatelessWidget {
  const _VehicleCard({
    required this.make,
    required this.model,
    required this.year,
    required this.compact,
    required this.onMakeChanged,
    required this.onModelChanged,
    required this.onYearChanged,
  });

  final String? make;
  final String? model;
  final int? year;
  final bool compact;
  final ValueChanged<String?> onMakeChanged;
  final ValueChanged<String?> onModelChanged;
  final ValueChanged<int?> onYearChanged;

  @override
  Widget build(BuildContext context) {
    final years = List.generate(15, (i) => 2025 - i);
    final innerGap = compact ? 6.0 : 8.0;

    return Container(
      padding: EdgeInsets.all(compact ? 10 : 12),
      decoration: AppDecorations.elevatedCard(radius: AppDecorations.radiusMd),
      child: Column(
        children: [
          Expanded(
            child: _dropdown<String>(
              hint: 'Make',
              value: make,
              items: makes,
              onChanged: onMakeChanged,
              icon: Icons.directions_car_rounded,
              compact: compact,
            ),
          ),
          SizedBox(height: innerGap),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: _dropdown<String>(
                    hint: 'Model',
                    value: model,
                    items: models,
                    onChanged: make == null ? null : onModelChanged,
                    icon: Icons.apps_rounded,
                    enabled: make != null,
                    compact: compact,
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

class _PriceRangeCard extends StatelessWidget {
  const _PriceRangeCard({
    required this.minPrice,
    required this.maxPrice,
    required this.compact,
    required this.onChanged,
  });

  final double minPrice;
  final double maxPrice;
  final bool compact;
  final void Function(double min, double max) onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: compact ? 10 : 12, vertical: compact ? 6 : 8),
      decoration: AppDecorations.card(radius: AppDecorations.radiusMd),
      child: Column(
        children: [
          Row(
            children: [
              _PriceBadge(label: '\$${minPrice.toInt()}', compact: compact),
              Expanded(
                child: Text(
                  'to',
                  textAlign: TextAlign.center,
                  style: AppTypography.textTheme.labelSmall?.copyWith(
                    fontSize: compact ? 10 : 11,
                    color: AppColors.textTertiary,
                  ),
                ),
              ),
              _PriceBadge(label: '\$${maxPrice.toInt()}', compact: compact, accent: true),
            ],
          ),
          Expanded(
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: compact ? 3 : 4,
                activeTrackColor: AppColors.primary,
                inactiveTrackColor: AppColors.primaryLight,
                thumbColor: AppColors.surface,
                overlayColor: AppColors.primary.withValues(alpha: 0.12),
                rangeThumbShape: RoundRangeSliderThumbShape(
                  enabledThumbRadius: compact ? 7 : 8,
                  elevation: 2,
                ),
                rangeTrackShape: const RoundedRectRangeSliderTrackShape(),
              ),
              child: RangeSlider(
                values: RangeValues(minPrice, maxPrice),
                min: 0,
                max: 2000,
                divisions: 40,
                onChanged: (v) => onChanged(v.start, v.end),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PriceBadge extends StatelessWidget {
  const _PriceBadge({required this.label, required this.compact, this.accent = false});

  final String label;
  final bool compact;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: compact ? 10 : 12, vertical: compact ? 4 : 6),
      decoration: BoxDecoration(
        color: accent ? AppColors.primaryLight : AppColors.chipBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: accent ? AppColors.primary.withValues(alpha: 0.2) : AppColors.border,
        ),
      ),
      child: Text(
        label,
        style: AppTypography.textTheme.labelMedium?.copyWith(
          fontSize: compact ? 12 : 13,
          color: accent ? AppColors.primary : AppColors.textPrimary,
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
