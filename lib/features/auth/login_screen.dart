import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:spare_kart/bloc/auth/auth_bloc.dart';
import 'package:spare_kart/bloc/listings/listings_bloc.dart';
import 'package:spare_kart/bloc/messages/messages_bloc.dart';
import 'package:spare_kart/bloc/orders/orders_bloc.dart';
import 'package:spare_kart/core/router/app_routes.dart';
import 'package:spare_kart/core/theme/app_colors.dart';
import 'package:spare_kart/core/theme/app_decorations.dart';
import 'package:spare_kart/core/theme/app_typography.dart';
import 'package:spare_kart/core/utils/responsive.dart';
import 'package:spare_kart/core/widgets/common_widgets.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _login() {
    context.read<AuthBloc>().add(AuthLoginRequested(
          phone: _phoneController.text,
          password: _passwordController.text,
        ));
    context.read<ListingsBloc>().add(ListingsLoaded());
    context.read<OrdersBloc>().add(OrdersLoaded());
    context.read<MessagesBloc>().add(MessagesLoaded());
    Navigator.pushNamedAndRemoveUntil(context, AppRoutes.main, (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    final r = Responsive(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Login'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.all(r.horizontalPadding()),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(AppDecorations.radiusXl),
                boxShadow: AppDecorations.shadowMd,
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: AppDecorations.glassSurface(),
                    child: const Icon(Icons.lock_open_rounded, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Welcome back!', style: AppTypography.textTheme.titleLarge?.copyWith(color: Colors.white)),
                        const SizedBox(height: 4),
                        Text(
                          'Sign in to continue shopping',
                          style: AppTypography.textTheme.bodySmall?.copyWith(color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Text('Phone Number', style: AppTypography.textTheme.labelMedium),
            const SizedBox(height: 8),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              style: AppTypography.textTheme.bodyLarge,
              decoration: const InputDecoration(
                hintText: '+1 555 000 0000',
                prefixIcon: Icon(Icons.phone_rounded),
              ),
            ),
            const SizedBox(height: 20),
            Text('Password', style: AppTypography.textTheme.labelMedium),
            const SizedBox(height: 8),
            TextField(
              controller: _passwordController,
              obscureText: _obscure,
              style: AppTypography.textTheme.bodyLarge,
              decoration: InputDecoration(
                hintText: 'Enter your password',
                prefixIcon: const Icon(Icons.lock_rounded),
                suffixIcon: IconButton(
                  icon: Icon(_obscure ? Icons.visibility_off_rounded : Icons.visibility_rounded),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
            ),
            const SizedBox(height: 36),
            PrimaryButton(label: 'Login', icon: Icons.login_rounded, onPressed: _login),
            const SizedBox(height: 20),
            Center(
              child: TextButton(
                onPressed: () => Navigator.pushReplacementNamed(context, AppRoutes.signup),
                child: RichText(
                  text: TextSpan(
                    style: AppTypography.textTheme.bodyMedium,
                    children: [
                      const TextSpan(text: "Don't have an account? "),
                      TextSpan(
                        text: 'Sign Up',
                        style: AppTypography.textTheme.labelLarge?.copyWith(color: AppColors.primary),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
