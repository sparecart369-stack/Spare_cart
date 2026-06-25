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

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _signup() {
    context.read<AuthBloc>().add(AuthSignupRequested(
          phone: _phoneController.text,
          password: _passwordController.text,
          name: _nameController.text.isEmpty ? 'New User' : _nameController.text,
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
        title: const Text('Sign Up'),
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
            Text('Create Account', style: AppTypography.textTheme.displaySmall),
            const SizedBox(height: 6),
            Text(
              'Join the global auto parts marketplace',
              style: AppTypography.textTheme.bodyMedium,
            ),
            const SizedBox(height: 28),
            _label('Full Name'),
            TextField(
              controller: _nameController,
              style: AppTypography.textTheme.bodyLarge,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                hintText: 'John Driver',
                prefixIcon: Icon(Icons.person_rounded),
              ),
            ),
            const SizedBox(height: 20),
            _label('Phone Number'),
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
            _label('Password'),
            TextField(
              controller: _passwordController,
              obscureText: _obscure,
              style: AppTypography.textTheme.bodyLarge,
              decoration: InputDecoration(
                hintText: 'Create a password',
                prefixIcon: const Icon(Icons.lock_rounded),
                suffixIcon: IconButton(
                  icon: Icon(_obscure ? Icons.visibility_off_rounded : Icons.visibility_rounded),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.accentSoft,
                borderRadius: BorderRadius.circular(AppDecorations.radiusSm),
                border: Border.all(color: AppColors.accent.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  Icon(Icons.verified_user_rounded, size: 18, color: AppColors.accent.withValues(alpha: 0.9)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Your data is secure. Demo mode — no validation required.',
                      style: AppTypography.textTheme.bodySmall?.copyWith(color: AppColors.warning),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            PrimaryButton(label: 'Create Account', icon: Icons.person_add_rounded, onPressed: _signup),
            const SizedBox(height: 20),
            Center(
              child: TextButton(
                onPressed: () => Navigator.pushReplacementNamed(context, AppRoutes.login),
                child: RichText(
                  text: TextSpan(
                    style: AppTypography.textTheme.bodyMedium,
                    children: [
                      const TextSpan(text: 'Already have an account? '),
                      TextSpan(
                        text: 'Login',
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

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text, style: AppTypography.textTheme.labelMedium),
      );
}
