import 'package:flutter/material.dart';
import 'package:spare_kart/core/theme/app_colors.dart';
import 'package:spare_kart/core/utils/responsive.dart';
import 'package:spare_kart/core/widgets/common_widgets.dart';

class AiPartFinderScreen extends StatelessWidget {
  const AiPartFinderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final r = Responsive(context);
    return Scaffold(
      appBar: AppBar(title: const Text('AI Part Finder')),
      body: Padding(
        padding: EdgeInsets.all(r.horizontalPadding()),
        child: Column(
          children: [
            const SizedBox(height: 24),
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.3), width: 2, style: BorderStyle.solid),
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.auto_awesome, size: 48, color: AppColors.primary),
                  SizedBox(height: 12),
                  Text('Upload or take a photo of your part',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  SizedBox(height: 4),
                  Text('Our AI will identify the part for you',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                ],
              ),
            ),
            const SizedBox(height: 32),
            PrimaryButton(
              label: 'Upload Photo',
              icon: Icons.photo_library_outlined,
              onPressed: () => _showDemoResult(context),
            ),
            const SizedBox(height: 12),
            SecondaryButton(
              label: 'Take Photo',
              onPressed: () => _showDemoResult(context),
            ),
            const Spacer(),
            const Text(
              'Demo: AI identification will show sample results',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  void _showDemoResult(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: AppColors.success, size: 48),
            const SizedBox(height: 16),
            const Text('Part Identified!', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Alternator - Toyota Corolla 2016', style: TextStyle(fontSize: 16)),
            const SizedBox(height: 4),
            const Text('Confidence: 94%', style: TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 24),
            PrimaryButton(
              label: 'View Matching Parts',
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}
