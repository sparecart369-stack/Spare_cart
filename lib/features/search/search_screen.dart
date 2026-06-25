import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:spare_kart/bloc/listings/listings_bloc.dart';
import 'package:spare_kart/core/router/app_routes.dart';
import 'package:spare_kart/core/theme/app_colors.dart';
import 'package:spare_kart/core/theme/app_typography.dart';
import 'package:spare_kart/core/utils/responsive.dart';
import 'package:spare_kart/core/widgets/common_widgets.dart';
import 'package:spare_kart/core/widgets/part_card.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final r = Responsive(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Search', style: AppTypography.textTheme.titleLarge),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: PremiumIconButton(
              icon: Icons.tune_rounded,
              onPressed: () => Navigator.pushNamed(context, AppRoutes.filters),
            ),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          BlocBuilder<ListingsBloc, ListingsState>(
            builder: (context, state) {
              final chips = state.filters.activeChips;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      r.horizontalPadding(),
                      0,
                      r.horizontalPadding(),
                      chips.isEmpty ? 16 : 10,
                    ),
                    child: TextField(
                      controller: _controller,
                      onChanged: (q) => context.read<ListingsBloc>().add(ListingSearchChanged(q)),
                      style: AppTypography.textTheme.bodyLarge,
                      decoration: InputDecoration(
                        hintText: 'Search by name, brand, location...',
                        prefixIcon: const Icon(Icons.search_rounded),
                        suffixIcon: IconButton(
                          icon: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppColors.accentSoft,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.camera_alt_rounded, color: AppColors.accent, size: 18),
                          ),
                          onPressed: () => Navigator.pushNamed(context, AppRoutes.aiFinder),
                        ),
                      ),
                    ),
                  ),
                  if (chips.isNotEmpty)
                    Padding(
                      padding: EdgeInsets.fromLTRB(r.horizontalPadding(), 0, r.horizontalPadding(), 10),
                      child: ActiveFilterChips(
                        chips: chips,
                        onClear: (field) => context.read<ListingsBloc>().add(ListingFilterCleared(field)),
                      ),
                    ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: r.horizontalPadding()),
                    child: Text(
                      '${state.filteredParts.length} parts found',
                      style: AppTypography.textTheme.labelMedium?.copyWith(color: AppColors.textTertiary),
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 12),
          Expanded(
            child: BlocBuilder<ListingsBloc, ListingsState>(
              builder: (context, state) {
                final parts = state.filteredParts;
                if (parts.isEmpty) {
                  return const EmptyState(
                    icon: Icons.search_off_rounded,
                    title: 'No parts found',
                    subtitle: 'Try adjusting your search or filters',
                  );
                }
                return ListView.separated(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(r.horizontalPadding(), 0, r.horizontalPadding(), 100),
                  itemCount: parts.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, i) => PartCard(
                    part: parts[i],
                    compact: true,
                    onTap: () => Navigator.pushNamed(context, AppRoutes.productDetail, arguments: parts[i]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
