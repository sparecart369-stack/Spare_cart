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
import 'package:spare_kart/core/validation/form_validators.dart';
import 'package:spare_kart/core/widgets/common_widgets.dart';
import 'package:spare_kart/core/widgets/phone_number_field.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneFieldKey = GlobalKey<PhoneNumberFieldState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscure = true;
  bool _obscureConfirm = true;
  String _dialCode = '+91';

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _signup() {
    if (!_formKey.currentState!.validate()) return;

    context.read<AuthBloc>().add(AuthSignupRequested(
          phone: _phoneFieldKey.currentState?.fullPhoneNumber ?? '$_dialCode${_phoneController.text}',
          password: _passwordController.text,
          name: _nameController.text.trim(),
        ));
  }

  void _onAuthStateChanged(BuildContext context, AuthState state) {
    if (state.isLoading) return;

    if (state.status == AuthStatus.authenticated && state.user != null) {
      context.read<ListingsBloc>().add(ListingsLoaded());
      context.read<OrdersBloc>().add(OrdersLoaded());
      context.read<MessagesBloc>().add(MessagesLoaded());
      Navigator.pushNamedAndRemoveUntil(context, AppRoutes.main, (_) => false);
    } else if (state.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(state.errorMessage!)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = Responsive(context);
    final isLoading = context.watch<AuthBloc>().state.isLoading;

    return BlocListener<AuthBloc, AuthState>(
      listener: _onAuthStateChanged,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Sign Up'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            onPressed: isLoading ? null : () => Navigator.pop(context),
          ),
        ),
        body: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.all(r.horizontalPadding()),
          child: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
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
                TextFormField(
                  controller: _nameController,
                  enabled: !isLoading,
                  style: AppTypography.textTheme.bodyLarge,
                  textCapitalization: TextCapitalization.words,
                  validator: FormValidators.name,
                  decoration: const InputDecoration(
                    hintText: 'John Driver',
                    prefixIcon: Icon(Icons.person_rounded),
                  ),
                ),
                const SizedBox(height: 20),
                _label('Phone Number'),
                PhoneNumberField(
                  key: _phoneFieldKey,
                  controller: _phoneController,
                  enabled: !isLoading,
                  onDialCodeChanged: (code) => _dialCode = code,
                  validator: (v) => FormValidators.phoneLocal(v, dialCode: _dialCode),
                ),
                const SizedBox(height: 20),
                _label('Password'),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscure,
                  enabled: !isLoading,
                  style: AppTypography.textTheme.bodyLarge,
                  validator: (v) => FormValidators.password(v, isSignup: true),
                  decoration: InputDecoration(
                    hintText: 'Min. 8 chars, upper, lower & number',
                    prefixIcon: const Icon(Icons.lock_rounded),
                    suffixIcon: IconButton(
                      icon: Icon(_obscure ? Icons.visibility_off_rounded : Icons.visibility_rounded),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                _label('Confirm Password'),
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirm,
                  enabled: !isLoading,
                  style: AppTypography.textTheme.bodyLarge,
                  validator: (v) => FormValidators.confirmPassword(v, _passwordController.text),
                  decoration: InputDecoration(
                    hintText: 'Re-enter your password',
                    prefixIcon: const Icon(Icons.lock_outline_rounded),
                    suffixIcon: IconButton(
                      icon: Icon(_obscureConfirm ? Icons.visibility_off_rounded : Icons.visibility_rounded),
                      onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                PrimaryButton(
                  label: 'Create Account',
                  icon: Icons.person_add_rounded,
                  isLoading: isLoading,
                  onPressed: _signup,
                ),
                const SizedBox(height: 20),
                Center(
                  child: TextButton(
                    onPressed: isLoading ? null : () => Navigator.pushReplacementNamed(context, AppRoutes.login),
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
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text, style: AppTypography.textTheme.labelMedium),
      );
}
