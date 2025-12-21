import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/constants/strings_da.dart';
import '../providers/shopping_providers.dart';

/// Bottom sheet for shopping list settings
class ShoppingSettingsSheet extends ConsumerWidget {
  const ShoppingSettingsSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final showTotalPrice = ref.watch(showTotalPriceProvider);
    final showCompletedTotal = ref.watch(showCompletedTotalProvider);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusXLarge),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.lightGray,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Title
              Text(
                AppStrings.shoppingSettings,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Show total price toggle
              _buildSettingToggle(
                context: context,
                ref: ref,
                title: AppStrings.showTotalPrice,
                subtitle: 'Vis den samlede pris for hver butik',
                icon: Icons.attach_money,
                isEnabled: showTotalPrice,
                onChanged: (value) {
                  ref.read(showTotalPriceProvider.notifier).state = value;
                  HapticFeedback.selectionClick();
                },
              ),
              const SizedBox(height: AppSpacing.md),

              // Show completed total toggle
              _buildSettingToggle(
                context: context,
                ref: ref,
                title: AppStrings.showCompletedTotal,
                subtitle: 'Vis total for købte varer (kræver "Købt" er aktiveret)',
                icon: Icons.shopping_cart_checkout,
                isEnabled: showCompletedTotal,
                onChanged: (value) {
                  ref.read(showCompletedTotalProvider.notifier).state = value;
                  HapticFeedback.selectionClick();
                },
              ),

              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingToggle({
    required BuildContext context,
    required WidgetRef ref,
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isEnabled,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.offWhite,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
        border: Border.all(
          color: isEnabled ? AppColors.primaryPurple : AppColors.lightGray,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isEnabled
                  ? AppColors.primaryPurple.withOpacity(0.1)
                  : AppColors.lightGray.withOpacity(0.5),
              borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
            ),
            child: Icon(
              icon,
              color: isEnabled ? AppColors.primaryPurple : AppColors.gray,
              size: 20,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.gray,
                      ),
                ),
              ],
            ),
          ),
          Switch(
            value: isEnabled,
            onChanged: onChanged,
            activeColor: AppColors.primaryPurple,
          ),
        ],
      ),
    );
  }
}
