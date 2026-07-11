import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:spare_kart/bloc/auth/auth_bloc.dart';
import 'package:spare_kart/bloc/favourites/favourites_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;

/// Loads saved favourites when the user signs in and clears them on sign out.
class FavouritesSyncHost extends StatefulWidget {
  const FavouritesSyncHost({super.key, required this.child});

  final Widget child;

  @override
  State<FavouritesSyncHost> createState() => _FavouritesSyncHostState();
}

class _FavouritesSyncHostState extends State<FavouritesSyncHost> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncFavourites());
  }

  void _syncFavourites() {
    if (!mounted) return;
    final auth = context.read<AuthBloc>().state;
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (auth.status == AuthStatus.authenticated && userId != null) {
      context.read<FavouritesBloc>().add(FavouritesLoadRequested(userId));
    } else {
      context.read<FavouritesBloc>().add(FavouritesCleared());
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) => _syncFavourites(),
      child: widget.child,
    );
  }
}
