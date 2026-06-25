import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:spare_kart/bloc/auth/auth_bloc.dart';
import 'package:spare_kart/core/theme/app_colors.dart';
import 'package:spare_kart/core/theme/app_decorations.dart';
import 'package:spare_kart/core/theme/app_typography.dart';
import 'package:spare_kart/core/utils/responsive.dart';
import 'package:spare_kart/core/utils/sensitive_text.dart';
import 'package:spare_kart/data/models/models.dart';

class PaymentMethodsScreen extends StatefulWidget {
  const PaymentMethodsScreen({super.key});

  @override
  State<PaymentMethodsScreen> createState() => _PaymentMethodsScreenState();
}

class _PaymentMethodsScreenState extends State<PaymentMethodsScreen> {
  final _upiController = TextEditingController();
  final _bankNameController = TextEditingController();
  final _accountNumberController = TextEditingController();
  final _accountNameController = TextEditingController();
  final _ifscController = TextEditingController();
  bool _editing = false;
  bool _showDetails = false;
  bool _loaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_loaded) {
      _loadFromProfile();
      _loaded = true;
    }
  }

  void _loadFromProfile() {
    final bank = context.read<AuthBloc>().state.user?.bankAccount;
    if (bank == null) {
      _editing = true;
      return;
    }
    _upiController.text = bank.upiId;
    _bankNameController.text = bank.bankName;
    _accountNumberController.text = bank.accountNumber;
    _accountNameController.text = bank.accountName;
    _ifscController.text = bank.ifscCode;
  }

  @override
  void dispose() {
    _upiController.dispose();
    _bankNameController.dispose();
    _accountNumberController.dispose();
    _accountNameController.dispose();
    _ifscController.dispose();
    super.dispose();
  }

  void _save() {
    final fields = [
      (_upiController, 'UPI ID'),
      (_bankNameController, 'bank name'),
      (_accountNumberController, 'account number'),
      (_accountNameController, 'account holder name'),
      (_ifscController, 'IFSC code'),
    ];
    for (final (controller, label) in fields) {
      if (controller.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please enter your $label')),
        );
        return;
      }
    }

    context.read<AuthBloc>().add(
          AuthBankAccountUpdated(
            SellerBankAccount(
              upiId: _upiController.text.trim(),
              bankName: _bankNameController.text.trim(),
              accountNumber: _accountNumberController.text.trim(),
              accountName: _accountNameController.text.trim(),
              ifscCode: _ifscController.text.trim().toUpperCase(),
            ),
          ),
        );
    setState(() => _editing = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Payout account saved')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final r = Responsive(context);
    final bank = context.watch<AuthBloc>().state.user?.bankAccount;
    final hasBank = bank?.isComplete ?? false;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Payment Methods'),
        actions: [
          if (hasBank && !_editing)
            IconButton(
              onPressed: () => setState(() => _showDetails = !_showDetails),
              icon: Icon(_showDetails ? Icons.visibility_off_rounded : Icons.visibility_rounded),
            ),
          if (hasBank && !_editing)
            IconButton(
              onPressed: () => setState(() => _editing = true),
              icon: const Icon(Icons.edit_outlined),
            ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          r.horizontalPadding(),
          12,
          r.horizontalPadding(),
          r.bottomNavPadding(),
        ),
        children: [
          Text(
            'PAYOUT ACCOUNT',
            style: AppTypography.overline.copyWith(color: AppColors.primary.withValues(alpha: 0.75)),
          ),
          const SizedBox(height: 10),
          if (_editing)
            _buildForm()
          else if (hasBank)
            _buildDetails(bank!)
          else
            _buildEmpty(),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'No payout account added yet',
          style: AppTypography.textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: () => setState(() => _editing = true),
          icon: const Icon(Icons.add_rounded),
          label: const Text('Add Bank Details'),
        ),
      ],
    );
  }

  Widget _buildDetails(SellerBankAccount bank) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _DetailLine(
          label: 'UPI ID',
          value: SensitiveText.maskUpi(bank.upiId, _showDetails),
        ),
        _DetailLine(
          label: 'Bank Name',
          value: bank.bankName,
        ),
        _DetailLine(
          label: 'Account Number',
          value: SensitiveText.mask(bank.accountNumber, visible: _showDetails),
        ),
        _DetailLine(
          label: 'Account Name',
          value: bank.accountName,
        ),
        _DetailLine(
          label: 'IFSC Code',
          value: SensitiveText.maskIfsc(bank.ifscCode, _showDetails),
        ),
      ],
    );
  }

  Widget _buildForm() {
    const gap = 8.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FormField(controller: _upiController, hint: 'UPI ID', icon: Icons.account_balance_wallet_outlined),
        const SizedBox(height: gap),
        _FormField(controller: _bankNameController, hint: 'Bank Name', icon: Icons.account_balance_outlined),
        const SizedBox(height: gap),
        _FormField(
          controller: _accountNumberController,
          hint: 'Account Number',
          icon: Icons.numbers_rounded,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        ),
        const SizedBox(height: gap),
        _FormField(controller: _accountNameController, hint: 'Account Holder Name', icon: Icons.person_outline_rounded),
        const SizedBox(height: gap),
        _FormField(
          controller: _ifscController,
          hint: 'IFSC Code',
          icon: Icons.qr_code_2_rounded,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
            TextInputFormatter.withFunction((old, next) => next.copyWith(text: next.text.toUpperCase())),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            if (context.read<AuthBloc>().state.user?.bankAccount?.isComplete ?? false)
              Expanded(
                child: OutlinedButton(
                  onPressed: () => setState(() {
                    _editing = false;
                    _loadFromProfile();
                  }),
                  child: const Text('Cancel'),
                ),
              ),
            if (context.read<AuthBloc>().state.user?.bankAccount?.isComplete ?? false) const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: FilledButton(onPressed: _save, child: const Text('Save')),
            ),
          ],
        ),
      ],
    );
  }
}

class _DetailLine extends StatelessWidget {
  const _DetailLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: AppTypography.textTheme.bodySmall?.copyWith(color: AppColors.textTertiary),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTypography.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _FormField extends StatelessWidget {
  const _FormField({
    required this.controller,
    required this.hint,
    required this.icon,
    this.keyboardType,
    this.inputFormatters,
  });

  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      style: AppTypography.textTheme.bodySmall?.copyWith(
        color: AppColors.textPrimary,
        fontWeight: FontWeight.w600,
      ),
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, size: 20, color: AppColors.textTertiary),
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDecorations.radiusSm),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDecorations.radiusSm),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDecorations.radiusSm),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
    );
  }
}
