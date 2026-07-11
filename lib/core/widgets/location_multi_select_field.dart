import 'package:flutter/material.dart';
import 'package:spare_kart/core/theme/app_colors.dart';
import 'package:spare_kart/core/theme/app_decorations.dart';
import 'package:spare_kart/core/theme/app_typography.dart';

class LocationMultiSelectField extends StatelessWidget {
  const LocationMultiSelectField({
    super.key,
    required this.label,
    required this.hint,
    required this.icon,
    required this.options,
    required this.selected,
    required this.onChanged,
    this.compact = false,
    this.enabled = true,
  });

  final String label;
  final String hint;
  final IconData icon;
  final List<String> options;
  final Set<String> selected;
  final ValueChanged<Set<String>> onChanged;
  final bool compact;
  final bool enabled;

  Future<void> _openPicker(BuildContext context) async {
    if (!enabled || options.isEmpty) return;

    final picked = await showModalBottomSheet<Set<String>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _LocationMultiSelectSheet(
        title: label,
        options: options,
        initialSelection: selected,
      ),
    );

    if (picked != null) {
      onChanged(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasSelection = selected.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: enabled ? () => _openPicker(context) : null,
            borderRadius: BorderRadius.circular(AppDecorations.radiusSm),
            child: Ink(
              decoration: BoxDecoration(
                color: enabled ? AppColors.surfaceElevated : AppColors.chipBg,
                borderRadius: BorderRadius.circular(AppDecorations.radiusSm),
                border: Border.all(color: AppColors.border),
              ),
              padding: EdgeInsets.symmetric(
                horizontal: compact ? 10 : 12,
                vertical: compact ? 10 : 12,
              ),
              child: Row(
                children: [
                  Icon(
                    icon,
                    size: compact ? 16 : 18,
                    color: hasSelection
                        ? AppColors.primary
                        : enabled
                            ? AppColors.textTertiary
                            : AppColors.textTertiary.withValues(alpha: 0.4),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      hasSelection ? '${selected.length} selected' : hint,
                      style: AppTypography.textTheme.bodySmall?.copyWith(
                        color: hasSelection ? AppColors.textPrimary : AppColors.textTertiary,
                        fontWeight: hasSelection ? FontWeight.w600 : FontWeight.w500,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: compact ? 18 : 20,
                    color: enabled ? AppColors.textTertiary : AppColors.textTertiary.withValues(alpha: 0.4),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (hasSelection) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: selected.map((value) {
              return InputChip(
                label: Text(
                  value,
                  style: AppTypography.textTheme.labelSmall?.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                backgroundColor: AppColors.chipBg,
                side: const BorderSide(color: AppColors.border),
                deleteIcon: const Icon(Icons.close_rounded, size: 16),
                onDeleted: enabled
                    ? () {
                        final updated = Set<String>.from(selected)..remove(value);
                        onChanged(updated);
                      }
                    : null,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              );
            }).toList(),
          ),
        ],
      ],
    );
  }
}

class _LocationMultiSelectSheet extends StatefulWidget {
  const _LocationMultiSelectSheet({
    required this.title,
    required this.options,
    required this.initialSelection,
  });

  final String title;
  final List<String> options;
  final Set<String> initialSelection;

  @override
  State<_LocationMultiSelectSheet> createState() => _LocationMultiSelectSheetState();
}

class _LocationMultiSelectSheetState extends State<_LocationMultiSelectSheet> {
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

  List<String> get _filtered {
    if (_query.isEmpty) return widget.options;
    return widget.options
        .where((option) => option.toLowerCase().contains(_query))
        .toList();
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
                      widget.title,
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
                decoration: InputDecoration(
                  hintText: 'Search ${widget.title.toLowerCase()}',
                  prefixIcon: const Icon(Icons.search_rounded),
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
            Expanded(
              child: ListView.builder(
                itemCount: _filtered.length,
                itemBuilder: (context, index) {
                  final option = _filtered[index];
                  final isSelected = _selection.contains(option);

                  return CheckboxListTile(
                    value: isSelected,
                    onChanged: (value) {
                      setState(() {
                        if (value == true) {
                          _selection.add(option);
                        } else {
                          _selection.remove(option);
                        }
                      });
                    },
                    title: Text(option),
                    controlAffinity: ListTileControlAffinity.leading,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
