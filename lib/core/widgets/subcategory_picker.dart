import 'package:flutter/material.dart';
import 'package:spare_kart/core/theme/app_colors.dart';
import 'package:spare_kart/core/theme/app_decorations.dart';
import 'package:spare_kart/core/theme/app_typography.dart';
import 'package:spare_kart/core/widgets/catalog_image_tile.dart';
import 'package:spare_kart/data/parts_catalog.dart';

class SubcategoryPicker extends StatefulWidget {
  const SubcategoryPicker({
    super.key,
    required this.categoryName,
    required this.selectedSubcategoryId,
    required this.onChanged,
    this.compact = false,
    this.required = false,
    this.showSectionLabel = true,
    this.crossAxisCount,
  });

  final String? categoryName;
  final String? selectedSubcategoryId;
  final ValueChanged<String?> onChanged;
  final bool compact;
  final bool required;
  final bool showSectionLabel;
  final int? crossAxisCount;

  @override
  State<SubcategoryPicker> createState() => _SubcategoryPickerState();
}

class _SubcategoryPickerState extends State<SubcategoryPicker> {
  final _searchController = TextEditingController();
  final _expandedGroups = <String>{};
  String _query = '';

  @override
  void initState() {
    super.initState();
    _syncExpandedGroups();
  }

  @override
  void didUpdateWidget(covariant SubcategoryPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.categoryName != widget.categoryName ||
        oldWidget.selectedSubcategoryId != widget.selectedSubcategoryId) {
      _searchController.clear();
      _query = '';
      _syncExpandedGroups();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _syncExpandedGroups() {
    _expandedGroups.clear();
    final catalog = PartsCatalog.instance.categoryForName(widget.categoryName);
    if (catalog == null) return;

    final selected = catalog.subcategoryById(widget.selectedSubcategoryId);
    if (selected != null) {
      _expandedGroups.add(selected.group);
      return;
    }

    final groups = catalog.groups;
    if (groups.isNotEmpty) _expandedGroups.add(groups.first);
  }

  int _columnsForWidth(double width) {
    if (widget.crossAxisCount != null) return widget.crossAxisCount!;
    if (width < 360) return 3;
    if (width < 520) return 4;
    return 5;
  }

  double _aspectRatio(bool compact, int columns) {
    if (columns >= 5) return compact ? 0.82 : 0.88;
    if (columns == 4) return compact ? 0.88 : 0.94;
    return compact ? 0.92 : 1.0;
  }

  List<PartSubcategory> _filteredItems(PartCategoryCatalog catalog) {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return catalog.subcategories;
    return catalog.subcategories
        .where(
          (sub) =>
              sub.name.toLowerCase().contains(q) ||
              sub.group.toLowerCase().contains(q),
        )
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.categoryName == null) return const SizedBox.shrink();

    final catalog = PartsCatalog.instance.categoryForName(widget.categoryName);
    if (catalog == null || catalog.subcategories.isEmpty) {
      return const SizedBox.shrink();
    }

    final gap = widget.compact ? 6.0 : 8.0;
    final sectionGap = widget.compact ? 8.0 : 10.0;
    final filtered = _filteredItems(catalog);
    final searching = _query.trim().isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.showSectionLabel) ...[
          Row(
            children: [
              Text(
                'SUBCATEGORY',
                style: AppTypography.overline.copyWith(
                  fontSize: widget.compact ? 10 : 11,
                  color: AppColors.primary.withValues(alpha: 0.75),
                ),
              ),
              if (widget.required) ...[
                const SizedBox(width: 4),
                Text(
                  '*',
                  style: AppTypography.overline.copyWith(
                    color: AppColors.error,
                    fontSize: widget.compact ? 10 : 11,
                  ),
                ),
              ],
              const Spacer(),
              Text(
                '${catalog.subcategories.length} parts',
                style: AppTypography.textTheme.labelSmall?.copyWith(
                  fontSize: widget.compact ? 10 : 11,
                  color: AppColors.textTertiary,
                ),
              ),
            ],
          ),
          SizedBox(height: gap),
        ],
        _SearchField(
          controller: _searchController,
          compact: widget.compact,
          onChanged: (value) => setState(() => _query = value),
          onClear: () {
            _searchController.clear();
            setState(() => _query = '');
          },
        ),
        SizedBox(height: sectionGap),
        if (searching)
          _buildSearchResults(
            catalog: catalog,
            items: filtered,
            gap: gap,
          )
        else
          _buildGroupedSections(
            catalog: catalog,
            gap: gap,
            sectionGap: sectionGap,
          ),
      ],
    );
  }

  Widget _buildSearchResults({
    required PartCategoryCatalog catalog,
    required List<PartSubcategory> items,
    required double gap,
  }) {
    if (items.isEmpty) {
      return _EmptyResults(compact: widget.compact);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = _columnsForWidth(constraints.maxWidth);
        final aspectRatio = _aspectRatio(widget.compact, columns);
        final cellWidth = (constraints.maxWidth - (columns - 1) * gap) / columns;
        final cellHeight = cellWidth / aspectRatio;
        final rows = (items.length / columns).ceil();
        final height = rows * cellHeight + (rows - 1) * gap;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${items.length} result${items.length == 1 ? '' : 's'}',
              style: AppTypography.textTheme.labelSmall?.copyWith(
                fontSize: widget.compact ? 10 : 11,
                color: AppColors.textSecondary,
              ),
            ),
            SizedBox(height: gap),
            SizedBox(
              height: height,
              child: GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  mainAxisSpacing: gap,
                  crossAxisSpacing: gap,
                  childAspectRatio: aspectRatio,
                ),
                itemCount: items.length,
                itemBuilder: (context, index) => _buildTile(
                  catalog: catalog,
                  sub: items[index],
                  index: index,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildGroupedSections({
    required PartCategoryCatalog catalog,
    required double gap,
    required double sectionGap,
  }) {
    return Column(
      children: catalog.groups.map((group) {
        final items = catalog.subcategoriesForGroup(group);
        final expanded = _expandedGroups.contains(group);
        final selectedInGroup =
            items.any((sub) => sub.id == widget.selectedSubcategoryId);

        return Padding(
          padding: EdgeInsets.only(bottom: sectionGap),
          child: _GroupSection(
            title: group,
            count: items.length,
            expanded: expanded,
            hasSelection: selectedInGroup,
            compact: widget.compact,
            onToggle: () => setState(() {
              if (expanded) {
                _expandedGroups.remove(group);
              } else {
                _expandedGroups.add(group);
              }
            }),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final columns = _columnsForWidth(constraints.maxWidth);
                final aspectRatio = _aspectRatio(widget.compact, columns);
                final cellWidth =
                    (constraints.maxWidth - (columns - 1) * gap) / columns;
                final cellHeight = cellWidth / aspectRatio;
                final rows = (items.length / columns).ceil();
                final height = rows * cellHeight + (rows - 1) * gap;

                return SizedBox(
                  height: height,
                  child: GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: columns,
                      mainAxisSpacing: gap,
                      crossAxisSpacing: gap,
                      childAspectRatio: aspectRatio,
                    ),
                    itemCount: items.length,
                    itemBuilder: (context, index) => _buildTile(
                      catalog: catalog,
                      sub: items[index],
                      index: index,
                    ),
                  ),
                );
              },
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTile({
    required PartCategoryCatalog catalog,
    required PartSubcategory sub,
    required int index,
  }) {
    final selected = widget.selectedSubcategoryId == sub.id;
    return CatalogImageTile(
      label: sub.name,
      imageAsset: PartsCatalog.instance.resolveSubcategoryImage(
        category: catalog,
        subcategory: sub,
      ),
      fallbackIcon: _iconForGroup(sub.group),
      colorIndex: index,
      selected: selected,
      compact: widget.compact,
      onTap: () => widget.onChanged(selected ? null : sub.id),
    );
  }

  IconData _iconForGroup(String group) {
    final key = group.toLowerCase();
    if (key.contains('engine block') || key.contains('crank')) {
      return Icons.precision_manufacturing_rounded;
    }
    if (key.contains('valve') || key.contains('timing')) {
      return Icons.settings_rounded;
    }
    if (key.contains('fuel') || key.contains('ignition')) {
      return Icons.local_gas_station_rounded;
    }
    if (key.contains('turbo') || key.contains('intake') || key.contains('air')) {
      return Icons.speed_rounded;
    }
    if (key.contains('cool') || key.contains('lubric') || key.contains('a/c')) {
      return Icons.ac_unit_rounded;
    }
    if (key.contains('hybrid') || key.contains('electric') || key.contains('ev')) {
      return Icons.electric_bolt_rounded;
    }
    if (key.contains('transmission') || key.contains('clutch') || key.contains('gear')) {
      return Icons.settings_input_component_rounded;
    }
    if (key.contains('body') || key.contains('door') || key.contains('bumper')) {
      return Icons.directions_car_rounded;
    }
    if (key.contains('glass') || key.contains('mirror')) {
      return Icons.visibility_rounded;
    }
    if (key.contains('brake')) return Icons.stop_circle_rounded;
    if (key.contains('suspension') || key.contains('steering')) {
      return Icons.height_rounded;
    }
    if (key.contains('electrical') || key.contains('sensor') || key.contains('module')) {
      return Icons.memory_rounded;
    }
    if (key.contains('light')) return Icons.lightbulb_rounded;
    if (key.contains('wheel') || key.contains('tyre')) return Icons.tire_repair_rounded;
    if (key.contains('bearing')) return Icons.album_rounded;
    if (key.contains('interior') || key.contains('seat')) return Icons.event_seat_rounded;
    if (key.contains('accessories')) return Icons.star_rounded;
    return Icons.inventory_2_outlined;
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.compact,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final bool compact;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      style: AppTypography.textTheme.bodySmall?.copyWith(
        fontSize: compact ? 12 : 13,
      ),
      decoration: InputDecoration(
        hintText: 'Search subcategory...',
        hintStyle: AppTypography.textTheme.bodySmall?.copyWith(
          fontSize: compact ? 12 : 13,
          color: AppColors.textTertiary,
        ),
        prefixIcon: Icon(
          Icons.search_rounded,
          size: compact ? 20 : 22,
          color: AppColors.textTertiary,
        ),
        suffixIcon: controller.text.isEmpty
            ? null
            : IconButton(
                onPressed: onClear,
                icon: Icon(
                  Icons.close_rounded,
                  size: compact ? 18 : 20,
                  color: AppColors.textTertiary,
                ),
              ),
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: EdgeInsets.symmetric(
          horizontal: compact ? 12 : 14,
          vertical: compact ? 10 : 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDecorations.radiusSm),
          borderSide: BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDecorations.radiusSm),
          borderSide: BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDecorations.radiusSm),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
    );
  }
}

class _GroupSection extends StatelessWidget {
  const _GroupSection({
    required this.title,
    required this.count,
    required this.expanded,
    required this.hasSelection,
    required this.compact,
    required this.onToggle,
    required this.child,
  });

  final String title;
  final int count;
  final bool expanded;
  final bool hasSelection;
  final bool compact;
  final VoidCallback onToggle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppDecorations.elevatedCard(radius: AppDecorations.radiusMd),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Material(
            color: hasSelection
                ? AppColors.primaryLight.withValues(alpha: 0.45)
                : AppColors.surface,
            child: InkWell(
              onTap: onToggle,
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: compact ? 10 : 12,
                  vertical: compact ? 10 : 12,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: AppTypography.textTheme.labelMedium?.copyWith(
                              fontSize: compact ? 12 : 13,
                              fontWeight: FontWeight.w600,
                              color: hasSelection
                                  ? AppColors.primary
                                  : AppColors.textPrimary,
                            ),
                          ),
                          SizedBox(height: compact ? 2 : 3),
                          Text(
                            '$count items',
                            style: AppTypography.textTheme.labelSmall?.copyWith(
                              fontSize: compact ? 10 : 11,
                              color: AppColors.textTertiary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (hasSelection)
                      Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          'Selected',
                          style: AppTypography.textTheme.labelSmall?.copyWith(
                            fontSize: compact ? 9 : 10,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    AnimatedRotation(
                      turns: expanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: hasSelection
                            ? AppColors.primary
                            : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: expanded
                ? Padding(
                    padding: EdgeInsets.fromLTRB(
                      compact ? 10 : 12,
                      0,
                      compact ? 10 : 12,
                      compact ? 10 : 12,
                    ),
                    child: child,
                  )
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }
}

class _EmptyResults extends StatelessWidget {
  const _EmptyResults({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(compact ? 16 : 20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDecorations.radiusSm),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Icon(
            Icons.search_off_rounded,
            size: compact ? 28 : 32,
            color: AppColors.textTertiary,
          ),
          SizedBox(height: compact ? 6 : 8),
          Text(
            'No matching subcategories',
            style: AppTypography.textTheme.labelMedium?.copyWith(
              fontSize: compact ? 12 : 13,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
