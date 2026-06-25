import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:spare_kart/bloc/app_mode/app_mode_bloc.dart';
import 'package:spare_kart/bloc/auth/auth_bloc.dart';
import 'package:spare_kart/core/router/app_routes.dart';
import 'package:spare_kart/core/theme/app_colors.dart';
import 'package:spare_kart/core/theme/app_decorations.dart';
import 'package:spare_kart/core/theme/app_typography.dart';
import 'package:spare_kart/core/utils/responsive.dart';
import 'package:spare_kart/core/utils/sensitive_text.dart';
import 'package:spare_kart/data/models/models.dart';

class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthBloc>().state.user;
    final r = Responsive(context);
    final initial = (user?.name ?? 'U')[0].toUpperCase();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _ProfileHeader(
            initial: initial,
            name: user?.name ?? 'Guest',
            phone: user?.phone ?? '',
            horizontalPadding: r.horizontalPadding(),
          ),
          Expanded(
            child: ListView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.fromLTRB(
                r.horizontalPadding(),
                8,
                r.horizontalPadding(),
                r.bottomNavPadding(),
              ),
              children: [
                _MenuSection(
                  title: 'Shopping',
                  items: [
                    _MenuData(Icons.inventory_2_rounded, 'My Listings', AppColors.primary, () => Navigator.pushNamed(context, AppRoutes.myListings)),
                    _MenuData(Icons.receipt_long_rounded, 'My Orders', AppColors.primaryMid, () => Navigator.pushNamed(context, AppRoutes.myOrders)),
                    _MenuData(Icons.favorite_rounded, 'Saved Items', AppColors.error, () => Navigator.pushNamed(context, AppRoutes.savedItems)),
                  ],
                ),
                const SizedBox(height: 16),
                _AccountSection(
                  items: [
                    _MenuData(Icons.location_on_rounded, 'My Addresses', AppColors.success, () => Navigator.pushNamed(context, AppRoutes.addresses)),
                    _MenuData(Icons.admin_panel_settings_rounded, 'Admin Dashboard', AppColors.warning, () {
                      context.read<AppModeBloc>().add(AppModeSet(AppMode.admin));
                    }),
                    _MenuData(Icons.settings_rounded, 'Settings', AppColors.textSecondary, () => Navigator.pushNamed(context, AppRoutes.settings)),
                  ],
                ),
                const SizedBox(height: 16),
                _LogoutButton(onTap: () {
                  context.read<AuthBloc>().add(AuthLogoutRequested());
                  Navigator.pushNamedAndRemoveUntil(context, AppRoutes.welcome, (_) => false);
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.initial,
    required this.name,
    required this.phone,
    required this.horizontalPadding,
  });

  final String initial;
  final String name;
  final String phone;
  final double horizontalPadding;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFEEF2FF), AppColors.background],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(horizontalPadding, 16, horizontalPadding, 20),
          child: Row(
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  shape: BoxShape.circle,
                  boxShadow: AppDecorations.shadowMd,
                  border: Border.all(color: Colors.white, width: 3),
                ),
                child: Center(
                  child: Text(
                    initial,
                    style: AppTypography.textTheme.displaySmall?.copyWith(color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: AppTypography.textTheme.titleLarge),
                    const SizedBox(height: 4),
                    Text(phone, style: AppTypography.textTheme.bodyMedium),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.successSoft,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Verified Member',
                        style: AppTypography.textTheme.labelSmall?.copyWith(
                          color: AppColors.success,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () {},
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: AppDecorations.iconButtonBg(),
                  child: const Icon(Icons.edit_rounded, size: 18),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuData {
  const _MenuData(this.icon, this.title, this.color, this.onTap);
  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback onTap;
}

class _MenuSection extends StatelessWidget {
  const _MenuSection({required this.title, required this.items});

  final String title;
  final List<_MenuData> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 10),
          child: Text(title.toUpperCase(), style: AppTypography.overline),
        ),
        Container(
          decoration: AppDecorations.card(radius: AppDecorations.radiusLg),
          child: Column(
            children: List.generate(items.length, (i) {
              final item = items[i];
              return Column(
                children: [
                  _MenuTile(item: item),
                  if (i < items.length - 1)
                    Divider(height: 1, indent: 56, color: AppColors.divider.withValues(alpha: 0.6)),
                ],
              );
            }),
          ),
        ),
      ],
    );
  }
}

class _AccountSection extends StatelessWidget {
  const _AccountSection({required this.items});

  final List<_MenuData> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 10),
          child: Text('ACCOUNT', style: AppTypography.overline),
        ),
        Container(
          decoration: AppDecorations.card(radius: AppDecorations.radiusLg),
          child: Column(
            children: [
              if (items.isNotEmpty) ...[
                _MenuTile(item: items.first),
                Divider(height: 1, indent: 56, color: AppColors.divider.withValues(alpha: 0.6)),
              ],
              const _PaymentMethodsTile(),
              for (var i = 1; i < items.length; i++) ...[
                Divider(height: 1, indent: 56, color: AppColors.divider.withValues(alpha: 0.6)),
                _MenuTile(item: items[i]),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _PaymentMethodsTile extends StatefulWidget {
  const _PaymentMethodsTile();

  @override
  State<_PaymentMethodsTile> createState() => _PaymentMethodsTileState();
}

class _PaymentMethodsTileState extends State<_PaymentMethodsTile> {
  bool _showDetails = false;

  @override
  Widget build(BuildContext context) {
    final bank = context.watch<AuthBloc>().state.user?.bankAccount;
    final hasBank = bank?.isComplete ?? false;

    return Material(
      color: Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => Navigator.pushNamed(context, AppRoutes.paymentMethods),
                    borderRadius: BorderRadius.circular(AppDecorations.radiusMd),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.accent.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.credit_card_rounded, color: AppColors.accent, size: 20),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text('Payment Methods', style: AppTypography.textTheme.titleSmall),
                        ),
                        Icon(Icons.chevron_right_rounded, color: AppColors.textTertiary, size: 22),
                      ],
                    ),
                  ),
                ),
                if (hasBank)
                  IconButton(
                    onPressed: () => setState(() => _showDetails = !_showDetails),
                    icon: Icon(
                      _showDetails ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                      color: AppColors.textTertiary,
                      size: 20,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                  ),
              ],
            ),
            if (hasBank) ...[
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.only(left: 54),
                child: _InlineBankDetails(bank: bank!, showDetails: _showDetails),
              ),
            ] else
              Padding(
                padding: const EdgeInsets.only(left: 54, top: 4),
                child: InkWell(
                  onTap: () => Navigator.pushNamed(context, AppRoutes.paymentMethods),
                  child: Text(
                    'Add bank details for payouts',
                    style: AppTypography.textTheme.bodySmall?.copyWith(color: AppColors.textTertiary),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _InlineBankDetails extends StatelessWidget {
  const _InlineBankDetails({required this.bank, required this.showDetails});

  final SellerBankAccount bank;
  final bool showDetails;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _InlineDetailRow(label: 'UPI', value: SensitiveText.maskUpi(bank.upiId, showDetails)),
        _InlineDetailRow(label: 'Bank', value: bank.bankName),
        _InlineDetailRow(label: 'Account', value: SensitiveText.mask(bank.accountNumber, visible: showDetails)),
        _InlineDetailRow(label: 'Name', value: bank.accountName),
        _InlineDetailRow(label: 'IFSC', value: SensitiveText.maskIfsc(bank.ifscCode, showDetails)),
      ],
    );
  }
}

class _InlineDetailRow extends StatelessWidget {
  const _InlineDetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 58,
            child: Text(
              label,
              style: AppTypography.textTheme.labelSmall?.copyWith(
                color: AppColors.textTertiary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTypography.textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({required this.item});

  final _MenuData item;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: item.onTap,
        borderRadius: BorderRadius.circular(AppDecorations.radiusLg),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: item.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(item.icon, color: item.color, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(item.title, style: AppTypography.textTheme.titleSmall),
              ),
              Icon(Icons.chevron_right_rounded, color: AppColors.textTertiary, size: 22),
            ],
          ),
        ),
      ),
    );
  }
}

class _LogoutButton extends StatelessWidget {
  const _LogoutButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDecorations.radiusLg),
        child: Ink(
          decoration: BoxDecoration(
            color: AppColors.errorSoft,
            borderRadius: BorderRadius.circular(AppDecorations.radiusLg),
            border: Border.all(color: AppColors.error.withValues(alpha: 0.15)),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.logout_rounded, color: AppColors.error, size: 20),
              const SizedBox(width: 8),
              Text(
                'Logout',
                style: AppTypography.textTheme.labelLarge?.copyWith(color: AppColors.error),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
