import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:spare_kart/bloc/app_mode/app_mode_bloc.dart';
import 'package:spare_kart/bloc/auth/auth_bloc.dart';
import 'package:spare_kart/bloc/cart/cart_bloc.dart';
import 'package:spare_kart/bloc/listings/listings_bloc.dart';
import 'package:spare_kart/bloc/messages/messages_bloc.dart';
import 'package:spare_kart/bloc/orders/orders_bloc.dart';
import 'package:spare_kart/core/router/app_routes.dart';
import 'package:spare_kart/core/theme/app_theme.dart';
import 'package:spare_kart/data/models/models.dart';
import 'package:spare_kart/features/account/addresses_screen.dart';
import 'package:spare_kart/features/account/my_listings_screen.dart';
import 'package:spare_kart/features/account/my_orders_screen.dart';
import 'package:spare_kart/features/account/payment_methods_screen.dart';
import 'package:spare_kart/features/account/saved_items_screen.dart';
import 'package:spare_kart/features/account/settings_screen.dart';
import 'package:spare_kart/features/auth/login_screen.dart';
import 'package:spare_kart/features/auth/signup_screen.dart';
import 'package:spare_kart/features/cart/cart_screen.dart';
import 'package:spare_kart/features/cart/checkout_screen.dart';
import 'package:spare_kart/features/main/main_shell.dart';
import 'package:spare_kart/features/messages/chat_detail_screen.dart';
import 'package:spare_kart/features/messages/messages_screen.dart';
import 'package:spare_kart/features/notifications/notifications_screen.dart';
import 'package:spare_kart/features/onboarding/welcome_screen.dart';
import 'package:spare_kart/features/product/product_detail_screen.dart';
import 'package:spare_kart/features/product/seller_profile_screen.dart';
import 'package:spare_kart/features/search/ai_part_finder_screen.dart';
import 'package:spare_kart/features/search/filters_screen.dart';
import 'package:spare_kart/features/splash/splash_screen.dart';

class SpareKartApp extends StatelessWidget {
  const SpareKartApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => AuthBloc()..add(AuthSessionChecked())),
        BlocProvider(create: (_) => AppModeBloc()),
        BlocProvider(create: (_) => CartBloc()),
        BlocProvider(create: (_) => ListingsBloc()),
        BlocProvider(create: (_) => OrdersBloc()),
        BlocProvider(create: (_) => MessagesBloc()),
      ],
      child: MaterialApp(
        title: 'SpareKart',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        initialRoute: AppRoutes.splash,
        onGenerateRoute: _onGenerateRoute,
      ),
    );
  }

  Route<dynamic>? _onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.splash:
        return _page(const SplashScreen(), settings);
      case AppRoutes.welcome:
        return _page(const WelcomeScreen(), settings);
      case AppRoutes.login:
        return _page(const LoginScreen(), settings);
      case AppRoutes.signup:
        return _page(const SignupScreen(), settings);
      case AppRoutes.main:
        return _page(const MainShell(), settings);
      case AppRoutes.filters:
        return _page(const FiltersScreen(), settings);
      case AppRoutes.aiFinder:
        return _page(const AiPartFinderScreen(), settings);
      case AppRoutes.productDetail:
        final part = settings.arguments as Part;
        return _page(ProductDetailScreen(part: part), settings);
      case AppRoutes.sellerProfile:
        final part = settings.arguments as Part;
        return _page(SellerProfileScreen(part: part), settings);
      case AppRoutes.cart:
        return _page(const CartScreen(), settings);
      case AppRoutes.checkout:
        return _page(const CheckoutScreen(), settings);
      case AppRoutes.myOrders:
        return _page(const MyOrdersScreen(), settings);
      case AppRoutes.myListings:
        return _page(const MyListingsScreen(), settings);
      case AppRoutes.savedItems:
        return _page(const SavedItemsScreen(), settings);
      case AppRoutes.addresses:
        return _page(const AddressesScreen(), settings);
      case AppRoutes.paymentMethods:
        return _page(const PaymentMethodsScreen(), settings);
      case AppRoutes.settings:
        return _page(const SettingsScreen(), settings);
      case AppRoutes.messages:
        return _page(const MessagesScreen(), settings);
      case AppRoutes.chatDetail:
        final args = settings.arguments;
        final chatArgs = args is ChatArgs
            ? args
            : ChatArgs(thread: args is MessageThread ? args : null);
        return _page(ChatDetailScreen(args: chatArgs), settings);
      case AppRoutes.notifications:
        return _page(const NotificationsScreen(), settings);
      default:
        return _page(const SplashScreen(), settings);
    }
  }

  MaterialPageRoute<dynamic> _page(Widget child, RouteSettings settings) {
    return MaterialPageRoute(settings: settings, builder: (_) => child);
  }
}
