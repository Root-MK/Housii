import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/loading/loading_indicators.dart';

/// Splash screen with animated Housii logo
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated Logo
            ShaderMask(
              shaderCallback: (bounds) => AppColors.primaryGradient.createShader(bounds),
              child: Text(
                'Housii',
                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                  fontSize: 56,
                  fontWeight: FontWeight.w700,
                  color: AppColors.white, // This will be masked by gradient
                  letterSpacing: -1.5,
                ),
              ),
            )
                .animate()
                .fadeIn(duration: 500.ms)
                .slideY(begin: 0.2, end: 0, duration: 500.ms, curve: Curves.easeOut)
                .then()
                .shimmer(
                  duration: 1500.ms,
                  color: AppColors.primaryPurpleLight.withOpacity(0.3),
                ),
            
            const SizedBox(height: AppSpacing.xxl),
            
            // Loading indicator
            const LoadingDots()
                .animate()
                .fadeIn(delay: 500.ms, duration: 300.ms),
          ],
        ),
      ),
    );
  }
}
