import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:spare_kart/bloc/app_mode/app_mode_bloc.dart';
import 'package:spare_kart/bloc/auth/auth_bloc.dart';
import 'package:spare_kart/bloc/messages/messages_bloc.dart';
import 'package:spare_kart/bloc/listings/listings_bloc.dart';
import 'package:spare_kart/core/constants/app_assets.dart';
import 'package:spare_kart/core/router/app_routes.dart';
import 'package:spare_kart/core/theme/app_colors.dart';
import 'package:spare_kart/core/theme/app_decorations.dart';
import 'package:spare_kart/core/theme/app_typography.dart';
import 'package:spare_kart/core/utils/responsive.dart';
import 'package:spare_kart/core/widgets/common_widgets.dart';
import 'package:spare_kart/core/widgets/part_card.dart';
import 'package:spare_kart/data/dummy_data.dart';
import 'package:spare_kart/features/home/widgets/marketplace_hero_banner.dart';
import 'package:spare_kart/features/main/main_shell.dart';
import 'package:spare_kart/features/search/filters_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? _selectedMake;
  String? _selectedModel;
  int? _selectedYear;

  Future<void> _openFilters({bool goToSearchOnApply = false}) async {
    final goToSearch = await Navigator.pushNamed(
      context,
      AppRoutes.filters,
      arguments: FiltersRouteArgs(goToSearchOnApply: goToSearchOnApply),
    );
    if (!mounted || goToSearch != true) return;
    MainShellTabController.maybeOf(context)?.selectTab(1);
  }

  void _applyFiltersAndGoToSearch(PartFilters filters) {
    context.read<ListingsBloc>().add(ListingFiltersApplied(filters));
    MainShellTabController.maybeOf(context)?.selectTab(1);
  }

  void _applyVehicleFiltersAndGoToSearch({
    required String make,
    required String model,
    required int year,
  }) {
    final current = context.read<ListingsBloc>().state.filters;
    _applyFiltersAndGoToSearch(current.copyWith(make: make, model: model, year: year));
  }

  void _applyCategoryAndGoToSearch(String category) {
    final current = context.read<ListingsBloc>().state.filters;
    _applyFiltersAndGoToSearch(current.copyWith(category: category));
  }

  @override
  Widget build(BuildContext context) {
    final r = Responsive(context);
    final user = context.watch<AuthBloc>().state.user;
    final unreadCount = context.watch<MessagesBloc>().state.threads
        .fold(0, (sum, thread) => sum + thread.unreadCount);
    final firstName = (user?.name ?? 'Guest').split(' ').first;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: BlocBuilder<ListingsBloc, ListingsState>(
        builder: (context, state) {
          final featured = state.allParts.take(6).toList();
          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFFEEF2FF), AppColors.background],
                      stops: [0.0, 0.45],
                    ),
                  ),
                  child: SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(r.horizontalPadding(), 12, r.horizontalPadding(), 0),
                      child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Good day 👋', style: AppTypography.greeting),
                                  const SizedBox(height: 2),
                                  Text(firstName, style: AppTypography.userName),
                                ],
                              ),
                            ),
                            _AdminModeButton(),
                            const SizedBox(width: 8),
                            PremiumIconButton(
                              icon: Icons.notifications_none_rounded,
                              onPressed: () => Navigator.pushNamed(context, AppRoutes.notifications),
                            ),
                            const SizedBox(width: 8),
                            PremiumIconButton(
                              icon: Icons.chat_bubble_outline_rounded,
                              onPressed: () => Navigator.pushNamed(context, AppRoutes.messages),
                              badge: unreadCount > 0 ? '$unreadCount' : null,
                            ),
                          ],
                        ),
                        const SizedBox(height: 22),
                        PremiumSearchBar(
                          onTap: () => _openFilters(goToSearchOnApply: true),
                        ),
                        const SizedBox(height: 22),
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(AppDecorations.radiusXl),
                            boxShadow: AppDecorations.shadowLg,
                          ),
                          child: MarketplaceHeroBanner(
                            onExplore: () => _openFilters(goToSearchOnApply: true),
                          ),
                        ),
                        const SizedBox(height: 28),
                        SectionHeader(
                          title: 'Search by Vehicle',
                          subtitle: 'Find exact-fit parts faster',
                        ),
                        _VehicleDropdowns(
                          make: _selectedMake,
                          model: _selectedModel,
                          year: _selectedYear,
                          onMakeChanged: (v) => setState(() {
                            _selectedMake = v;
                            _selectedModel = null;
                            _selectedYear = null;
                          }),
                          onModelChanged: (v) => setState(() {
                            _selectedModel = v;
                            _selectedYear = null;
                          }),
                          onYearChanged: (v) {
                            setState(() => _selectedYear = v);
                            if (v != null && _selectedMake != null && _selectedModel != null) {
                              _applyVehicleFiltersAndGoToSearch(
                                make: _selectedMake!,
                                model: _selectedModel!,
                                year: v,
                              );
                            }
                          },
                        ),
                        const SizedBox(height: 8),
                        SectionHeader(
                          title: 'Popular Categories',
                          subtitle: 'Browse by part type',
                        ),
                        SizedBox(
                          height: 108,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            itemCount: categories.length,
                            separatorBuilder: (_, _) => const SizedBox(width: 12),
                            itemBuilder: (context, i) {
                              final (name, iconName) = categories[i];
                              return _CategoryChip(
                                name: name,
                                icon: _iconFromName(iconName),
                                imageAsset: switch (name) {
                                  'Engine' => AppAssets.categoryEngine,
                                  'Transmission' => AppAssets.categoryTransmission,
                                  'Body Parts' => AppAssets.categoryBodyParts,
                                  'Lighting' => AppAssets.categoryLighting,
                                  _ => null,
                                },
                                index: i,
                                onTap: () => _applyCategoryAndGoToSearch(name),
                              );
                            },
                          ),
                        ),
                        SectionHeader(
                          title: 'Featured Parts',
                          subtitle: 'Hand-picked quality listings',
                          action: 'See All',
                          onActionTap: () {},
                        ),
                      ],
                    ),
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: EdgeInsets.fromLTRB(r.horizontalPadding(), 0, r.horizontalPadding(), 32),
                sliver: SliverGrid(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: r.gridColumns(mobile: 2, tablet: 3),
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 0.68,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, i) => PartCard(
                      part: featured[i],
                      onTap: () => Navigator.pushNamed(context, AppRoutes.productDetail, arguments: featured[i]),
                    ),
                    childCount: featured.length,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  IconData _iconFromName(String name) {
    return switch (name) {
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
  }
}

class _AdminModeButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.read<AppModeBloc>().add(AppModeSet(AppMode.admin)),
        borderRadius: BorderRadius.circular(AppDecorations.radiusSm),
        child: Ink(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.accentSoft,
                AppColors.accentSoft.withValues(alpha: 0.5),
              ],
            ),
            borderRadius: BorderRadius.circular(AppDecorations.radiusSm),
            border: Border.all(color: AppColors.accent.withValues(alpha: 0.25)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.admin_panel_settings_rounded, size: 16, color: AppColors.accent.withValues(alpha: 0.9)),
              const SizedBox(width: 4),
              Text(
                'Admin',
                style: AppTypography.textTheme.labelSmall?.copyWith(
                  color: AppColors.warning,
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

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.name,
    required this.icon,
    this.imageAsset,
    required this.index,
    required this.onTap,
  });

  final String name;
  final IconData icon;
  final String? imageAsset;
  final int index;
  final VoidCallback onTap;

  static const _gradients = [
    [Color(0xFFEEF2FF), Color(0xFFDBEAFE)],
    [Color(0xFFF0FDF4), Color(0xFFD1FAE5)],
    [Color(0xFFFFF7ED), Color(0xFFFED7AA)],
    [Color(0xFFFDF4FF), Color(0xFFF3E8FF)],
    [Color(0xFFFEF2F2), Color(0xFFFECACA)],
    [Color(0xFFF0F9FF), Color(0xFFBAE6FD)],
    [Color(0xFFF5F3FF), Color(0xFFDDD6FE)],
    [Color(0xFFECFDF5), Color(0xFFA7F3D0)],
  ];

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
    final g = _gradients[index % _gradients.length];
    final c = _iconColors[index % _iconColors.length];
    final hasImage = imageAsset != null;

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 84,
        child: Column(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: g),
                borderRadius: BorderRadius.circular(18),
                boxShadow: AppDecorations.shadowSm,
                border: Border.all(color: Colors.white, width: 1.5),
              ),
              clipBehavior: Clip.antiAlias,
              child: hasImage
                  ? Padding(
                      padding: const EdgeInsets.all(2),
                      child: ColorFiltered(
                        colorFilter: ColorFilter.mode(c, BlendMode.modulate),
                        child: Image.asset(
                          imageAsset!,
                          fit: BoxFit.contain,
                          alignment: Alignment.center,
                        ),
                      ),
                    )
                  : Icon(icon, color: c, size: 28),
            ),
            const SizedBox(height: 8),
            Text(
              name,
              textAlign: TextAlign.center,
              style: AppTypography.textTheme.labelSmall?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 11,
              ),
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }
}

class _VehicleDropdowns extends StatelessWidget {
  const _VehicleDropdowns({
    required this.make,
    required this.model,
    required this.year,
    required this.onMakeChanged,
    required this.onModelChanged,
    required this.onYearChanged,
  });

  final String? make;
  final String? model;
  final int? year;
  final ValueChanged<String?> onMakeChanged;
  final ValueChanged<String?> onModelChanged;
  final ValueChanged<int?> onYearChanged;

  @override
  Widget build(BuildContext context) {
    final years = List.generate(15, (i) => 2025 - i);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: AppDecorations.elevatedCard(radius: AppDecorations.radiusLg),
      child: Column(
        children: [
          _dropdown<String>(
            hint: 'Make',
            value: make,
            items: makes,
            onChanged: onMakeChanged,
            icon: Icons.directions_car_rounded,
          ),
          const SizedBox(height: 10),
          Row(
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
                ),
              ),
              const SizedBox(width: 10),
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
                ),
              ),
            ],
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
    String Function(T)? display,
    bool enabled = true,
  }) {
    final hasValue = value != null;
    return DropdownButtonFormField<T>(
      key: ValueKey('$hint-$value-${enabled ? 'on' : 'off'}'),
      initialValue: value,
      isExpanded: true,
      hint: Text(
        hint,
        style: AppTypography.textTheme.bodyMedium?.copyWith(
          color: enabled ? AppColors.textTertiary : AppColors.textTertiary.withValues(alpha: 0.45),
          fontWeight: FontWeight.w500,
        ),
        overflow: TextOverflow.ellipsis,
      ),
      style: AppTypography.textTheme.bodyMedium?.copyWith(
        color: AppColors.textPrimary,
        fontWeight: FontWeight.w600,
      ),
      icon: Icon(
        Icons.keyboard_arrow_down_rounded,
        size: 22,
        color: enabled ? AppColors.textTertiary : AppColors.textTertiary.withValues(alpha: 0.4),
      ),
      dropdownColor: AppColors.surface,
      borderRadius: BorderRadius.circular(AppDecorations.radiusMd),
      decoration: InputDecoration(
        filled: true,
        fillColor: enabled ? AppColors.surfaceElevated : AppColors.chipBg,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        prefixIcon: Icon(
          icon,
          size: 20,
          color: hasValue
              ? AppColors.primary
              : enabled
                  ? AppColors.textTertiary
                  : AppColors.textTertiary.withValues(alpha: 0.4),
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 44, minHeight: 44),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDecorations.radiusMd),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDecorations.radiusMd),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDecorations.radiusMd),
          borderSide: BorderSide(color: AppColors.border.withValues(alpha: 0.5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDecorations.radiusMd),
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
              ),
            ),
          )
          .toList(),
      onChanged: onChanged,
    );
  }
}
