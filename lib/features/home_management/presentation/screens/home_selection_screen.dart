import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/constants/strings_da.dart';
import '../../../../core/widgets/cards/option_card.dart';
import '../../../../core/router/app_router.dart';
import '../../../../shared/providers/auth_provider.dart';

/// Screen for selecting to create or join a home
class HomeSelectionScreen extends ConsumerWidget {
  const HomeSelectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Sign out button at top right
              Align(
                alignment: Alignment.topRight,
                child: TextButton.icon(
                  onPressed: () => ref.read(authActionsProvider).signOut(),
                  icon: const Icon(Icons.logout, size: 18),
                  label: const Text('Log ud'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.gray,
                  ),
                ),
              ),
              
              const SizedBox(height: AppSpacing.md),
              
              // Header
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ShaderMask(
                    shaderCallback: (bounds) => AppColors.primaryGradient.createShader(bounds),
                    child: Text(
                      'Housii',
                      style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    AppStrings.selectHomeTitle,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    AppStrings.selectHomeSubtitle,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.gray,
                    ),
                  ),
                ],
              )
                  .animate()
                  .fadeIn(duration: 500.ms)
                  .slideY(begin: -0.1, end: 0, duration: 500.ms),
              
              const SizedBox(height: AppSpacing.xxl),
              
              // Options
              OptionCard(
                title: AppStrings.createHome,
                subtitle: AppStrings.createHomeDesc,
                icon: Icons.add_home_rounded,
                onTap: () => context.push(AppRoutes.createHome),
              )
                  .animate()
                  .fadeIn(delay: 200.ms, duration: 400.ms)
                  .slideX(begin: -0.1, end: 0, delay: 200.ms, duration: 400.ms),
              
              const SizedBox(height: AppSpacing.md),
              
              OptionCard(
                title: AppStrings.joinHome,
                subtitle: AppStrings.joinHomeDesc,
                icon: Icons.group_add_rounded,
                onTap: () => context.push(AppRoutes.joinHome),
              )
                  .animate()
                  .fadeIn(delay: 350.ms, duration: 400.ms)
                  .slideX(begin: -0.1, end: 0, delay: 350.ms, duration: 400.ms),
              
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
