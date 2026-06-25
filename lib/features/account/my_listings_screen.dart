import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:spare_kart/bloc/listings/listings_bloc.dart';
import 'package:spare_kart/core/router/app_routes.dart';
import 'package:spare_kart/core/utils/responsive.dart';
import 'package:spare_kart/core/widgets/common_widgets.dart';
import 'package:spare_kart/core/widgets/part_card.dart';

class MyListingsScreen extends StatelessWidget {
  const MyListingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final r = Responsive(context);
    return Scaffold(
      appBar: AppBar(title: const Text('My Listings')),
      body: BlocBuilder<ListingsBloc, ListingsState>(
        builder: (context, state) {
          final listings = state.adminParts;
          if (listings.isEmpty) {
            return EmptyState(
              icon: Icons.inventory_2_outlined,
              title: 'No listings yet',
              subtitle: 'Use the Sell tab to add your first part',
            );
          }
          return ListView.separated(
            padding: EdgeInsets.all(r.horizontalPadding()),
            itemCount: listings.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) => PartCard(
              part: listings[i],
              compact: true,
              onTap: () => Navigator.pushNamed(context, AppRoutes.productDetail, arguments: listings[i]),
            ),
          );
        },
      ),
    );
  }
}
