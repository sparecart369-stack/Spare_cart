import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:spare_kart/bloc/listings/listings_bloc.dart';
import 'package:spare_kart/core/router/app_routes.dart';
import 'package:spare_kart/core/utils/responsive.dart';
import 'package:spare_kart/core/widgets/common_widgets.dart';
import 'package:spare_kart/core/widgets/part_card.dart';

class SavedItemsScreen extends StatelessWidget {
  const SavedItemsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final r = Responsive(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Saved Items')),
      body: BlocBuilder<ListingsBloc, ListingsState>(
        builder: (context, state) {
          final saved = state.allParts.take(4).toList();
          if (saved.isEmpty) {
            return const EmptyState(icon: Icons.favorite_border, title: 'No saved items');
          }
          return ListView.separated(
            padding: EdgeInsets.all(r.horizontalPadding()),
            itemCount: saved.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) => PartCard(
              part: saved[i],
              compact: true,
              onTap: () => Navigator.pushNamed(context, AppRoutes.productDetail, arguments: saved[i]),
            ),
          );
        },
      ),
    );
  }
}
