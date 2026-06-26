import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:spare_kart/bloc/auth/auth_bloc.dart';
import 'package:spare_kart/core/theme/app_colors.dart';
import 'package:spare_kart/core/theme/app_typography.dart';
import 'package:spare_kart/core/utils/operating_countries_helper.dart';
import 'package:spare_kart/core/utils/responsive.dart';
import 'package:spare_kart/core/widgets/common_widgets.dart';
import 'package:spare_kart/core/widgets/operating_countries_selector.dart';
import 'package:spare_kart/data/models/models.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  bool _showCountryValidationError = false;
  bool _pendingSave = false;
  OperatingCountriesSelection? _currentSelection;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<AuthBloc>().add(AuthProfileRefreshRequested());
    });
  }

  void _save() {
    final user = context.read<AuthBloc>().state.user;
    final selection = _currentSelection ??
        user?.operatingCountriesSelection ??
        const OperatingCountriesSelection();

    if (!selection.isValid) {
      setState(() => _showCountryValidationError = true);
      return;
    }

    setState(() => _pendingSave = true);
    context.read<AuthBloc>().add(AuthOperatingCountriesUpdated(selection));
  }

  @override
  Widget build(BuildContext context) {
    final r = Responsive(context);
    final user = context.watch<AuthBloc>().state.user;
    final isLoading = context.watch<AuthBloc>().state.isLoading;
    final initial = user?.operatingCountriesSelection ??
        const OperatingCountriesSelection();

    return BlocListener<AuthBloc, AuthState>(
      listenWhen: (prev, next) => _pendingSave && prev.isLoading && !next.isLoading,
      listener: (context, state) {
        if (!_pendingSave) return;

        setState(() => _pendingSave = false);

        if (state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.errorMessage!)),
          );
          return;
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Operating countries updated')),
        );
        Navigator.pop(context);
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Edit Profile'),
        ),
        body: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.all(r.horizontalPadding()),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(user?.name ?? '', style: AppTypography.textTheme.titleLarge),
              const SizedBox(height: 4),
              Text(
                user?.phone ?? '',
                style: AppTypography.textTheme.bodyMedium?.copyWith(
                  color: AppColors.textTertiary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                OperatingCountriesHelper.formatSummary(
                  operatesGlobally: initial.operatesGlobally,
                  countryCodes: initial.countryCodes,
                ),
                style: AppTypography.textTheme.bodySmall?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Select where you buy, sell, or distribute spares. Choose multiple countries or all countries.',
                style: AppTypography.textTheme.bodySmall?.copyWith(
                  color: AppColors.textTertiary,
                ),
              ),
              const SizedBox(height: 12),
              OperatingCountriesSelector(
                key: ValueKey(
                  '${initial.operatesGlobally}-${initial.countryCodes.join(',')}',
                ),
                initial: initial,
                enabled: !isLoading,
                showValidationError: _showCountryValidationError,
                onSelectionChanged: (selection) =>
                    _currentSelection = selection,
              ),
              const SizedBox(height: 32),
              PrimaryButton(
                label: 'Save Changes',
                icon: Icons.check_rounded,
                isLoading: isLoading,
                onPressed: _save,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
