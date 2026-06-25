import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:spare_kart/bloc/auth/auth_bloc.dart';
import 'package:spare_kart/bloc/listings/listings_bloc.dart';
import 'package:spare_kart/core/theme/app_colors.dart';
import 'package:spare_kart/core/theme/app_decorations.dart';
import 'package:spare_kart/core/theme/app_typography.dart';
import 'package:spare_kart/core/utils/responsive.dart';
import 'package:spare_kart/core/widgets/common_widgets.dart';
import 'package:spare_kart/data/dummy_data.dart';
import 'package:spare_kart/data/models/models.dart';

class SellScreen extends StatefulWidget {
  const SellScreen({super.key});

  @override
  State<SellScreen> createState() => _SellScreenState();
}

class _SellScreenState extends State<SellScreen> {
  int _step = 0;
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  String? _category;
  String? _make;
  String? _model;
  int? _year;
  PartCondition _condition = PartCondition.used;
  final _priceController = TextEditingController();
  final List<int> _photos = [0, 1, 2];

  static const _steps = ['Details', 'Photos', 'Review'];

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  void _next() {
    if (_step < 2) {
      setState(() => _step++);
    } else {
      _publishListing();
    }
  }

  double _shellNavBottomInset(BuildContext context) {
    // MainShell nav: 8 top + 64 bar + 4 bottom + device safe area
    return MediaQuery.paddingOf(context).bottom + 76;
  }

  @override
  Widget build(BuildContext context) {
    final r = Responsive(context);
    final pad = r.horizontalPadding();
    final compact = r.height < 740;
    final navInset = _shellNavBottomInset(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _SellHeader(step: _step, compact: compact),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.fromLTRB(pad, compact ? 6 : 10, pad, compact ? 12 : 16),
                child: switch (_step) {
                  0 => _buildDetails(compact),
                  1 => _buildPhotos(compact),
                  _ => _buildReview(compact),
                },
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                boxShadow: AppDecorations.shadowNav,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              padding: EdgeInsets.fromLTRB(
                pad,
                compact ? 10 : 12,
                pad,
                navInset + (compact ? 8 : 10),
              ),
              child: Row(
                children: [
                  if (_step > 0) ...[
                    Expanded(
                      child: SecondaryButton(
                        label: 'Back',
                        onPressed: () => setState(() => _step--),
                      ),
                    ),
                    SizedBox(width: compact ? 10 : 12),
                  ],
                  Expanded(
                    flex: _step > 0 ? 2 : 1,
                    child: PrimaryButton(
                      label: _step < 2 ? 'Next' : 'Publish Listing',
                      height: compact ? 50 : 54,
                      icon: _step < 2 ? Icons.arrow_forward_rounded : Icons.publish_rounded,
                      onPressed: _next,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetails(bool compact) {
    final gap = compact ? 6.0 : 8.0;
    final years = List.generate(15, (i) => 2025 - i);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionLabel('Part Details', compact: compact),
        SizedBox(height: gap),
        _FormField(
          controller: _nameController,
          hint: 'Part Name',
          icon: Icons.inventory_2_outlined,
          compact: compact,
        ),
        SizedBox(height: gap),
        _DropdownField<String>(
          hint: 'Category',
          value: _category,
          items: categories.map((c) => c.$1).toList(),
          icon: Icons.category_outlined,
          compact: compact,
          onChanged: (v) => setState(() => _category = v),
        ),
        SizedBox(height: gap),
        Container(
          padding: EdgeInsets.all(compact ? 10 : 12),
          decoration: AppDecorations.elevatedCard(radius: AppDecorations.radiusMd),
          child: Column(
            children: [
              _DropdownField<String>(
                hint: 'Make',
                value: _make,
                items: makes,
                icon: Icons.directions_car_rounded,
                compact: compact,
                onChanged: (v) => setState(() {
                  _make = v;
                  _model = null;
                  _year = null;
                }),
              ),
              SizedBox(height: gap),
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: _DropdownField<String>(
                      hint: 'Model',
                      value: _model,
                      items: models,
                      icon: Icons.apps_rounded,
                      compact: compact,
                      enabled: _make != null,
                      onChanged: _make == null ? null : (v) => setState(() => _model = v),
                    ),
                  ),
                  SizedBox(width: gap),
                  Expanded(
                    flex: 2,
                    child: _DropdownField<int>(
                      hint: 'Year',
                      value: _year,
                      items: years,
                      icon: Icons.calendar_month_rounded,
                      compact: compact,
                      enabled: _model != null,
                      display: (v) => '$v',
                      onChanged: _model == null ? null : (v) => setState(() => _year = v),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        SizedBox(height: gap),
        _SectionLabel('Condition', compact: compact),
        SizedBox(height: gap),
        SizedBox(
          height: compact ? 34 : 38,
          child: Row(
            children: PartCondition.values.map((c) {
              final selected = _condition == c;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: c != PartCondition.newPart ? 6 : 0),
                  child: _ConditionChip(
                    label: _conditionLabel(c),
                    selected: selected,
                    compact: compact,
                    onTap: () => setState(() => _condition = c),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        SizedBox(height: gap),
        _FormField(
          controller: _priceController,
          hint: 'Price',
          icon: Icons.attach_money_rounded,
          compact: compact,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))],
          prefix: '\$ ',
        ),
        SizedBox(height: gap),
        _FormField(
          controller: _descController,
          hint: 'Description',
          icon: Icons.notes_rounded,
          compact: compact,
          maxLines: compact ? 4 : 5,
        ),
      ],
    );
  }

  Widget _buildPhotos(bool compact) {
    final r = Responsive(context);
    final gap = compact ? 6.0 : 8.0;
    final columns = r.gridColumns(mobile: 3, tablet: 4);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionLabel('Upload Photos', compact: compact),
        SizedBox(height: gap),
        Text(
          'Add up to 6 photos of your part',
          style: AppTypography.textTheme.bodySmall?.copyWith(
            fontSize: compact ? 11 : 12,
            color: AppColors.textSecondary,
          ),
        ),
        SizedBox(height: gap + 2),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: gap,
            mainAxisSpacing: gap,
            childAspectRatio: 1,
          ),
          itemCount: _photos.length < 6 ? _photos.length + 1 : _photos.length,
          itemBuilder: (context, i) {
            if (i == _photos.length && _photos.length < 6) {
              return _PhotoAddTile(compact: compact, onTap: () => setState(() => _photos.add(_photos.length)));
            }
            return _PhotoTile(index: i, compact: compact);
          },
        ),
      ],
    );
  }

  Widget _buildReview(bool compact) {
    final gap = compact ? 8.0 : 10.0;
    final price = _priceController.text.isEmpty ? '0' : _priceController.text;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionLabel('Review Listing', compact: compact),
        SizedBox(height: gap),
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(compact ? 14 : 18),
          decoration: AppDecorations.elevatedCard(radius: AppDecorations.radiusLg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: compact ? 64 : 72,
                    height: compact ? 64 : 72,
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(AppDecorations.radiusSm),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: const Icon(Icons.image_rounded, color: AppColors.primary, size: 32),
                  ),
                  SizedBox(width: gap + 2),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _nameController.text.isEmpty ? 'Part Name' : _nameController.text,
                          style: AppTypography.textTheme.titleMedium?.copyWith(
                            fontSize: compact ? 15 : 16,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: compact ? 4 : 6),
                        Text(
                          '${_make ?? 'Make'} · ${_model ?? 'Model'} · ${_year ?? 'Year'}',
                          style: AppTypography.textTheme.bodySmall?.copyWith(fontSize: compact ? 11 : 12),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: compact ? 4 : 6),
                        ConditionChip(label: _conditionLabel(_condition)),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: gap + 4),
              Text('\$$price', style: AppTypography.price.copyWith(fontSize: compact ? 22 : 26)),
              SizedBox(height: gap),
              if (_category != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    _category!.toUpperCase(),
                    style: AppTypography.overline.copyWith(
                      fontSize: compact ? 9 : 10,
                      color: AppColors.primary.withValues(alpha: 0.7),
                    ),
                  ),
                ),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(compact ? 10 : 12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(AppDecorations.radiusSm),
                  border: Border.all(color: AppColors.border),
                ),
                child: Text(
                  _descController.text.isEmpty ? 'No description provided' : _descController.text,
                  style: AppTypography.textTheme.bodySmall?.copyWith(
                    fontSize: compact ? 12 : 13,
                    color: _descController.text.isEmpty ? AppColors.textTertiary : AppColors.textSecondary,
                    height: 1.45,
                  ),
                ),
              ),
              SizedBox(height: gap),
              Row(
                children: [
                  Icon(Icons.photo_library_outlined, size: compact ? 14 : 16, color: AppColors.textTertiary),
                  const SizedBox(width: 6),
                  Text(
                    '${_photos.length} photo${_photos.length == 1 ? '' : 's'} attached',
                    style: AppTypography.textTheme.labelSmall?.copyWith(fontSize: compact ? 10 : 11),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _publishListing() {
    final user = context.read<AuthBloc>().state.user;
    final id = 'admin-${DateTime.now().millisecondsSinceEpoch}';
    final part = Part(
      id: id,
      name: _nameController.text.isEmpty ? 'My Part' : _nameController.text,
      category: _category ?? 'Engine',
      make: _make ?? 'Toyota',
      model: _model ?? 'Corolla',
      year: _year ?? 2020,
      condition: _condition,
      price: double.tryParse(_priceController.text) ?? 99.99,
      location: 'Your Location',
      sellerId: 'admin',
      sellerName: user?.name ?? 'You',
      sellerRating: 5.0,
      imageUrl: 'https://picsum.photos/seed/$id/400/300',
      description: _descController.text.isEmpty ? 'Listed part' : _descController.text,
      isAdminListing: true,
    );
    context.read<ListingsBloc>().add(ListingAdded(part));
    setState(() {
      _step = 0;
      _nameController.clear();
      _descController.clear();
      _priceController.clear();
      _category = null;
      _make = null;
      _model = null;
      _year = null;
      _condition = PartCondition.used;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Listing published! Switch to Admin mode to view.')),
    );
  }

  String _conditionLabel(PartCondition c) => switch (c) {
        PartCondition.used => 'Used',
        PartCondition.refurbished => 'Refurbished',
        PartCondition.newPart => 'New',
      };
}

class _SellHeader extends StatelessWidget {
  const _SellHeader({required this.step, required this.compact});

  final int step;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(16, compact ? 8 : 12, 16, compact ? 10 : 14),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('Sell Your Part', style: AppTypography.textTheme.titleLarge),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: compact ? 8 : 10, vertical: compact ? 4 : 5),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border),
                  boxShadow: AppDecorations.shadowSm,
                ),
                child: Text(
                  'Step ${step + 1}/3',
                  style: AppTypography.textTheme.labelSmall?.copyWith(
                    fontSize: compact ? 10 : 11,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: compact ? 10 : 14),
          Row(
            children: List.generate(_SellScreenState._steps.length, (i) {
              final active = i == step;
              final done = i < step;
              return Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            height: compact ? 3 : 4,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(4),
                              gradient: active || done ? AppColors.primaryGradient : null,
                              color: active || done ? null : AppColors.divider,
                            ),
                          ),
                          SizedBox(height: compact ? 6 : 8),
                          Text(
                            _SellScreenState._steps[i],
                            textAlign: TextAlign.center,
                            style: AppTypography.textTheme.labelSmall?.copyWith(
                              fontSize: compact ? 9 : 10,
                              fontWeight: active ? FontWeight.w700 : FontWeight.w600,
                              color: active
                                  ? AppColors.primary
                                  : done
                                      ? AppColors.textPrimary
                                      : AppColors.textTertiary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (i < _SellScreenState._steps.length - 1) SizedBox(width: compact ? 6 : 8),
                  ],
                ),
              );
            }),
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

class _FormField extends StatelessWidget {
  const _FormField({
    required this.controller,
    required this.hint,
    required this.icon,
    required this.compact,
    this.keyboardType,
    this.inputFormatters,
    this.prefix,
    this.maxLines = 1,
  });

  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool compact;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final String? prefix;
  final int? maxLines;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      maxLines: maxLines,
      textAlignVertical: (maxLines ?? 1) > 1 ? TextAlignVertical.top : TextAlignVertical.center,
      style: AppTypography.textTheme.bodySmall?.copyWith(
        color: AppColors.textPrimary,
        fontWeight: FontWeight.w600,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: AppTypography.textTheme.bodySmall?.copyWith(
          color: AppColors.textTertiary,
          fontWeight: FontWeight.w500,
        ),
        prefixText: prefix,
        prefixStyle: AppTypography.textTheme.bodySmall?.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.w700,
        ),
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: EdgeInsets.symmetric(
          horizontal: compact ? 12 : 14,
          vertical: compact ? 10 : 12,
        ),
        prefixIcon: Icon(icon, size: compact ? 18 : 20, color: AppColors.textTertiary),
        prefixIconConstraints: BoxConstraints(minWidth: compact ? 40 : 44, minHeight: compact ? 40 : 44),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDecorations.radiusSm),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDecorations.radiusSm),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDecorations.radiusSm),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
    );
  }
}

class _DropdownField<T> extends StatelessWidget {
  const _DropdownField({
    required this.hint,
    required this.value,
    required this.items,
    required this.icon,
    required this.compact,
    required this.onChanged,
    this.display,
    this.enabled = true,
  });

  final String hint;
  final T? value;
  final List<T> items;
  final IconData icon;
  final bool compact;
  final ValueChanged<T?>? onChanged;
  final String Function(T)? display;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
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
                display != null ? display!(v) : '$v',
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
    return Material(
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
            border: Border.all(color: selected ? Colors.transparent : AppColors.border),
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
    );
  }
}

class _PhotoTile extends StatelessWidget {
  const _PhotoTile({required this.index, required this.compact});

  final int index;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(AppDecorations.radiusMd),
        border: Border.all(color: AppColors.border),
        boxShadow: AppDecorations.shadowSm,
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          const Icon(Icons.image_rounded, color: AppColors.primary, size: 36),
          Positioned(
            top: 6,
            right: 6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.surface.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '${index + 1}',
                style: AppTypography.textTheme.labelSmall?.copyWith(fontSize: 9, fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PhotoAddTile extends StatelessWidget {
  const _PhotoAddTile({required this.compact, required this.onTap});

  final bool compact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDecorations.radiusMd),
        child: Ink(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppDecorations.radiusMd),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.4), width: 1.5),
            boxShadow: AppDecorations.shadowSm,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(compact ? 8 : 10),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.add_a_photo_rounded, color: AppColors.primary, size: compact ? 20 : 24),
              ),
              SizedBox(height: compact ? 4 : 6),
              Text(
                'Add',
                style: AppTypography.textTheme.labelSmall?.copyWith(
                  fontSize: compact ? 10 : 11,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
