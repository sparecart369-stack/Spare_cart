import 'package:flutter/material.dart';
import 'package:spare_kart/core/theme/app_colors.dart';
import 'package:spare_kart/core/theme/app_decorations.dart';
import 'package:spare_kart/core/theme/app_typography.dart';

class VehiclePickerField extends StatelessWidget {
  const VehiclePickerField({
    super.key,
    required this.hint,
    required this.value,
    required this.items,
    required this.icon,
    required this.onChanged,
    this.compact = false,
    this.showIcon = true,
    this.enabled = true,
  });

  final String hint;
  final String? value;
  final List<String> items;
  final IconData icon;
  final ValueChanged<String?>? onChanged;
  final bool compact;
  final bool showIcon;
  final bool enabled;

  Future<void> _openPicker(BuildContext context) async {
    if (!enabled || onChanged == null || items.isEmpty) return;

    final selected = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: AppColors.overlay,
      builder: (context) => _VehicleSearchSheet(
        title: hint,
        items: items,
        selected: value,
      ),
    );

    if (selected != null) {
      onChanged!(selected);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasValue = value != null;
    final verticalPadding = compact ? 11.0 : 13.0;
    final horizontalPadding = showIcon ? (compact ? 10.0 : 14.0) : 12.0;
    final iconSize = compact ? 18.0 : 20.0;
    final iconBox = compact ? 36.0 : 44.0;
    final textStyle = compact
        ? AppTypography.textTheme.bodySmall
        : AppTypography.textTheme.bodyMedium;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled && onChanged != null ? () => _openPicker(context) : null,
        borderRadius: BorderRadius.circular(AppDecorations.radiusMd),
        child: InputDecorator(
          isFocused: false,
          isEmpty: !hasValue,
          decoration: InputDecoration(
            filled: true,
            fillColor: enabled ? AppColors.surfaceElevated : AppColors.chipBg,
            contentPadding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: verticalPadding),
            prefixIcon: showIcon
                ? Icon(
                    icon,
                    size: iconSize,
                    color: hasValue
                        ? AppColors.primary
                        : enabled
                            ? AppColors.textTertiary
                            : AppColors.textTertiary.withValues(alpha: 0.4),
                  )
                : null,
            prefixIconConstraints: showIcon
                ? BoxConstraints(minWidth: iconBox, minHeight: iconBox)
                : null,
            suffixIcon: Icon(
              showIcon ? Icons.unfold_more_rounded : Icons.keyboard_arrow_down_rounded,
              size: iconSize,
              color: enabled ? AppColors.textTertiary : AppColors.textTertiary.withValues(alpha: 0.4),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDecorations.radiusMd),
              borderSide: BorderSide(
                color: hasValue ? AppColors.primary.withValues(alpha: 0.35) : AppColors.border,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDecorations.radiusMd),
              borderSide: BorderSide(
                color: hasValue ? AppColors.primary.withValues(alpha: 0.35) : AppColors.border,
              ),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDecorations.radiusMd),
              borderSide: BorderSide(color: AppColors.border.withValues(alpha: 0.5)),
            ),
          ),
          child: Text(
            hasValue ? value! : hint,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textStyle?.copyWith(
              color: hasValue
                  ? AppColors.textPrimary
                  : enabled
                      ? AppColors.textTertiary
                      : AppColors.textTertiary.withValues(alpha: 0.45),
              fontWeight: hasValue ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

class _VehicleSearchSheet extends StatefulWidget {
  const _VehicleSearchSheet({
    required this.title,
    required this.items,
    this.selected,
  });

  final String title;
  final List<String> items;
  final String? selected;

  @override
  State<_VehicleSearchSheet> createState() => _VehicleSearchSheetState();
}

class _VehicleSearchSheetState extends State<_VehicleSearchSheet> {
  late List<String> _filtered;
  final _searchController = TextEditingController();
  final _searchFocus = FocusNode();
  final _scrollController = ScrollController();

  bool get _isSearching => _searchController.text.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    _filtered = widget.items;
    WidgetsBinding.instance.addPostFrameCallback((_) => _searchFocus.requestFocus());
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onQueryChanged(String query) {
    final q = query.trim().toLowerCase();
    setState(() {
      if (q.isEmpty) {
        _filtered = widget.items;
      } else {
        _filtered = widget.items.where((item) => item.toLowerCase().contains(q)).toList();
      }
    });
  }

  Map<String, List<String>> _groupedItems() {
    final groups = <String, List<String>>{};
    for (final item in _filtered) {
      final letter = item.isNotEmpty ? item[0].toUpperCase() : '#';
      groups.putIfAbsent(letter, () => []).add(item);
    }
    return groups;
  }

  IconData _iconForTitle() => switch (widget.title.toLowerCase()) {
        'make' => Icons.directions_car_filled_rounded,
        'model' => Icons.apps_rounded,
        _ => Icons.list_rounded,
      };

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final maxHeight = MediaQuery.sizeOf(context).height * 0.88;
    final grouped = _groupedItems();
    final sortedLetters = grouped.keys.toList()..sort();

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        constraints: BoxConstraints(maxHeight: maxHeight),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppDecorations.radiusXl)),
          boxShadow: [
            BoxShadow(
              color: Color(0x260F172A),
              blurRadius: 32,
              offset: Offset(0, -8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            _SheetHeader(
              title: widget.title,
              icon: _iconForTitle(),
              count: _filtered.length,
              onClose: () => Navigator.pop(context),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: _SearchField(
                controller: _searchController,
                focusNode: _searchFocus,
                hint: 'Search ${widget.title.toLowerCase()}...',
                onChanged: _onQueryChanged,
                onClear: () {
                  _searchController.clear();
                  _onQueryChanged('');
                },
              ),
            ),
            Flexible(
              child: _filtered.isEmpty
                  ? _EmptyState(query: _searchController.text.trim())
                  : Scrollbar(
                      controller: _scrollController,
                      thumbVisibility: true,
                      radius: const Radius.circular(99),
                      child: _isSearching
                          ? ListView.builder(
                              controller: _scrollController,
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                              itemCount: _filtered.length,
                              itemBuilder: (context, index) {
                                final item = _filtered[index];
                                return _VehicleOptionTile(
                                  label: item,
                                  query: _searchController.text.trim(),
                                  isSelected: item == widget.selected,
                                  onTap: () => Navigator.pop(context, item),
                                );
                              },
                            )
                          : ListView.builder(
                              controller: _scrollController,
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                              itemCount: sortedLetters.length,
                              itemBuilder: (context, sectionIndex) {
                                final letter = sortedLetters[sectionIndex];
                                final sectionItems = grouped[letter]!;
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _SectionLabel(letter: letter),
                                    ...sectionItems.map(
                                      (item) => _VehicleOptionTile(
                                        label: item,
                                        isSelected: item == widget.selected,
                                        onTap: () => Navigator.pop(context, item),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                    ),
            ),
            SizedBox(height: MediaQuery.paddingOf(context).bottom),
          ],
        ),
      ),
    );
  }
}

class _SheetHeader extends StatelessWidget {
  const _SheetHeader({
    required this.title,
    required this.icon,
    required this.count,
    required this.onClose,
  });

  final String title;
  final IconData icon;
  final int count;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 12, 4),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(AppDecorations.radiusSm),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.28),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(icon, color: AppColors.textOnPrimary, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Select $title',
                  style: AppTypography.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$count options available',
                  style: AppTypography.textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onClose,
              borderRadius: BorderRadius.circular(AppDecorations.radiusSm),
              child: Container(
                width: 40,
                height: 40,
                decoration: AppDecorations.iconButtonBg(),
                child: const Icon(Icons.close_rounded, size: 20, color: AppColors.textSecondary),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.focusNode,
    required this.hint,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String hint;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, _) {
        return TextField(
          controller: controller,
          focusNode: focusNode,
          onChanged: onChanged,
          style: AppTypography.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppTypography.textTheme.bodyMedium?.copyWith(color: AppColors.textTertiary),
            prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary, size: 22),
            suffixIcon: value.text.isNotEmpty
                ? IconButton(
                    onPressed: onClear,
                    icon: const Icon(Icons.cancel_rounded, size: 20, color: AppColors.textTertiary),
                  )
                : null,
            filled: true,
            fillColor: AppColors.background,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(50),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(50),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(50),
              borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
            ),
          ),
        );
      },
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.letter});

  final String letter;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 14, 4, 6),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              letter,
              style: AppTypography.textTheme.labelLarge?.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(height: 1, color: AppColors.divider),
          ),
        ],
      ),
    );
  }
}

class _VehicleOptionTile extends StatelessWidget {
  const _VehicleOptionTile({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.query = '',
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final String query;

  @override
  Widget build(BuildContext context) {
    final initial = label.isNotEmpty ? label[0].toUpperCase() : '?';

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppDecorations.radiusMd),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primaryLight : AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(AppDecorations.radiusMd),
              border: Border.all(
                color: isSelected ? AppColors.primary.withValues(alpha: 0.35) : AppColors.border,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary.withValues(alpha: 0.12) : AppColors.chipBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    initial,
                    style: AppTypography.textTheme.labelLarge?.copyWith(
                      color: isSelected ? AppColors.primary : AppColors.textSecondary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _HighlightedText(
                    text: label,
                    query: query,
                    isSelected: isSelected,
                  ),
                ),
                if (isSelected)
                  Container(
                    width: 24,
                    height: 24,
                    decoration: const BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check_rounded, size: 15, color: AppColors.textOnPrimary),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HighlightedText extends StatelessWidget {
  const _HighlightedText({
    required this.text,
    required this.query,
    required this.isSelected,
  });

  final String text;
  final String query;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final baseStyle = AppTypography.textTheme.bodyMedium?.copyWith(
      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
      color: isSelected ? AppColors.primaryDark : AppColors.textPrimary,
    );

    if (query.isEmpty) {
      return Text(text, style: baseStyle, maxLines: 2, overflow: TextOverflow.ellipsis);
    }

    final lowerText = text.toLowerCase();
    final lowerQuery = query.toLowerCase();
    final start = lowerText.indexOf(lowerQuery);
    if (start < 0) {
      return Text(text, style: baseStyle, maxLines: 2, overflow: TextOverflow.ellipsis);
    }

    final end = start + query.length;
    return RichText(
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      text: TextSpan(
        style: baseStyle,
        children: [
          TextSpan(text: text.substring(0, start)),
          TextSpan(
            text: text.substring(start, end),
            style: baseStyle?.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w800,
              backgroundColor: AppColors.primaryLight,
            ),
          ),
          TextSpan(text: text.substring(end)),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.query});

  final String query;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.search_off_rounded, size: 34, color: AppColors.primary),
            ),
            const SizedBox(height: 16),
            Text(
              'No matches found',
              style: AppTypography.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              query.isEmpty ? 'Try a different search term' : 'No results for "$query"',
              textAlign: TextAlign.center,
              style: AppTypography.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
