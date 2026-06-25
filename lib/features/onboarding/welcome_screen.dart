import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:spare_kart/core/router/app_routes.dart';
import 'package:spare_kart/core/theme/app_colors.dart';
import 'package:spare_kart/core/utils/responsive.dart';
import 'package:spare_kart/core/widgets/common_widgets.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final r = Responsive(context);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(gradient: AppColors.splashGradient),
          child: Stack(
            children: [
              Positioned(
                top: -80,
                right: -60,
                child: Container(
                  width: 240,
                  height: 240,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.04),
                  ),
                ),
              ),
              Positioned(
                bottom: 120,
                left: -40,
                child: Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primary.withValues(alpha: 0.15),
                  ),
                ),
              ),
              SafeArea(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: r.horizontalPadding()),
                  child: Column(
                    children: [
                      const Spacer(flex: 2),
                      const AppLogo(size: 110),
                      const Spacer(flex: 3),
                      PrimaryButton(
                        label: 'Login',
                        icon: Icons.arrow_forward_rounded,
                        onPressed: () => Navigator.pushNamed(context, AppRoutes.login),
                      ),
                      const SizedBox(height: 14),
                      SecondaryButton(
                        label: 'Signup',
                        light: true,
                        onPressed: () => Navigator.pushNamed(context, AppRoutes.signup),
                      ),
                      const SizedBox(height: 36),
                      Text(
                        'Trusted by 50,000+ auto enthusiasts',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
