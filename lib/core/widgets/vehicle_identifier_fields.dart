import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:spare_kart/core/theme/app_colors.dart';
import 'package:spare_kart/core/theme/app_decorations.dart';
import 'package:spare_kart/core/theme/app_typography.dart';

class VehicleIdentifierFields extends StatelessWidget {
  const VehicleIdentifierFields({
    super.key,
    required this.chassisController,
    this.partNumberController,
    this.compact = false,
  });

  final TextEditingController chassisController;
  final TextEditingController? partNumberController;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (partNumberController == null) {
      return _IdentifierField(
        controller: chassisController,
        hint: 'Chassis No.',
        icon: Icons.pin_outlined,
        compact: compact,
      );
    }

    final gap = compact ? 6.0 : 8.0;
    return Row(
      children: [
        Expanded(
          child: _IdentifierField(
            controller: chassisController,
            hint: 'Chassis No.',
            icon: Icons.pin_outlined,
            compact: compact,
          ),
        ),
        SizedBox(width: gap),
        Expanded(
          child: _IdentifierField(
            controller: partNumberController!,
            hint: 'Part No.',
            icon: Icons.tag_outlined,
            compact: compact,
          ),
        ),
      ],
    );
  }
}

class _IdentifierField extends StatelessWidget {
  const _IdentifierField({
    required this.controller,
    required this.hint,
    required this.icon,
    required this.compact,
  });

  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9\-]')),
        TextInputFormatter.withFunction(
          (old, next) => next.copyWith(text: next.text.toUpperCase()),
        ),
      ],
      textCapitalization: TextCapitalization.characters,
      style: AppTypography.textTheme.bodySmall?.copyWith(
        color: AppColors.textPrimary,
        fontWeight: FontWeight.w600,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: AppTypography.textTheme.bodySmall?.copyWith(
          color: AppColors.textTertiary,
          fontWeight: FontWeight.w500,
        ),
        filled: true,
        fillColor: AppColors.surfaceElevated,
        contentPadding: EdgeInsets.symmetric(
          horizontal: compact ? 10 : 12,
          vertical: compact ? 10 : 12,
        ),
        prefixIcon: Icon(
          icon,
          size: compact ? 16 : 18,
          color: AppColors.textTertiary,
        ),
        prefixIconConstraints: BoxConstraints(
          minWidth: compact ? 36 : 40,
          minHeight: compact ? 36 : 40,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(
            compact ? AppDecorations.radiusSm : AppDecorations.radiusMd,
          ),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(
            compact ? AppDecorations.radiusSm : AppDecorations.radiusMd,
          ),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(
            compact ? AppDecorations.radiusSm : AppDecorations.radiusMd,
          ),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
    );
  }
}
