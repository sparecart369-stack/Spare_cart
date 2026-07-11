import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:spare_kart/bloc/auth/auth_bloc.dart';
import 'package:spare_kart/core/navigation/app_navigator.dart';
import 'package:spare_kart/core/services/push_notification_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;

/// Starts FCM token sync on auth changes and routes notification taps.
class PushNotificationHost extends StatefulWidget {
  const PushNotificationHost({super.key, required this.child});

  final Widget child;

  @override
  State<PushNotificationHost> createState() => _PushNotificationHostState();
}

class _PushNotificationHostState extends State<PushNotificationHost> {
  @override
  void initState() {
    super.initState();
    PushNotificationService.instance.setNavigateHandler(_handleNavigate);
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  @override
  void dispose() {
    PushNotificationService.instance.setNavigateHandler(null);
    PushNotificationService.instance.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    await PushNotificationService.instance.bootstrap();
    if (!mounted) return;
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId != null) {
      await PushNotificationService.instance.startForUser(userId);
    }
  }

  void _handleNavigate(String route, {String? threadId}) {
    final context = AppNavigator.rootKey.currentContext;
    if (context == null) return;
    PushNotificationService.instance.navigateFromHandler(
      context,
      route: route,
      threadId: threadId,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) async {
        if (state.status == AuthStatus.authenticated) {
          final userId = Supabase.instance.client.auth.currentUser?.id;
          if (userId != null) {
            await PushNotificationService.instance.startForUser(userId);
          }
        } else if (state.status == AuthStatus.unauthenticated) {
          await PushNotificationService.instance.stopForUser();
        }
      },
      child: widget.child,
    );
  }
}
