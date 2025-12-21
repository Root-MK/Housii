import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../data/models/store.dart';

/// Section header for store groups in shopping list
class StoreSectionHeader extends StatelessWidget {
  final Store? store;
  final String title;
  final String? emoji;
  final int itemCount;
  final bool isExpanded;
  final VoidCallback? onToggle;
  final IconData? icon;
  final Color? iconColor;
  final Color? backgroundColor;
  final double? totalPrice;
  final double? completedTotal;
  final bool showTotalPrice;
  final bool showCompletedTotal;
  final VoidCallback? onDragAccept;

  const StoreSectionHeader({
    super.key,
    this.store,
    required this.title,
    this.emoji,
    required this.itemCount,
    this.isExpanded = true,
    this.onToggle,
    this.icon,
    this.iconColor,
    this.backgroundColor,
    this.totalPrice,
    this.completedTotal,
    this.showTotalPrice = false,
    this.showCompletedTotal = false,
    this.onDragAccept,
  });

  /// Factory for important section
  factory StoreSectionHeader.important({
    required int itemCount,
    bool isExpanded = true,
    VoidCallback? onToggle,
    double? totalPrice,
    double? completedTotal,
    bool showTotalPrice = false,
    bool showCompletedTotal = false,
  }) {
    return StoreSectionHeader(
      title: 'Vigtigt',
      itemCount: itemCount,
      isExpanded: isExpanded,
      onToggle: onToggle,
      icon: Icons.priority_high_rounded,
      iconColor: AppColors.white,
      backgroundColor: AppColors.primaryPurple,
      totalPrice: totalPrice,
      completedTotal: completedTotal,
      showTotalPrice: showTotalPrice,
      showCompletedTotal: showCompletedTotal,
    );
  }

  /// Factory for lookout section
  factory StoreSectionHeader.lookout({
    required int itemCount,
    bool isExpanded = true,
    VoidCallback? onToggle,
    double? totalPrice,
    double? completedTotal,
    bool showTotalPrice = false,
    bool showCompletedTotal = false,
  }) {
    return StoreSectionHeader(
      title: 'Hold udkig',
      itemCount: itemCount,
      isExpanded: isExpanded,
      onToggle: onToggle,
      icon: Icons.visibility_outlined,
      iconColor: AppColors.warning,
      backgroundColor: AppColors.warning.withOpacity(0.1),
      totalPrice: totalPrice,
      completedTotal: completedTotal,
      showTotalPrice: showTotalPrice,
      showCompletedTotal: showCompletedTotal,
    );
  }

  /// Factory for no store section
  factory StoreSectionHeader.noStore({
    required int itemCount,
    bool isExpanded = true,
    VoidCallback? onToggle,
    double? totalPrice,
    double? completedTotal,
    bool showTotalPrice = false,
    bool showCompletedTotal = false,
    VoidCallback? onDragAccept,
  }) {
    return StoreSectionHeader(
      title: 'Valgfri butik',
      itemCount: itemCount,
      isExpanded: isExpanded,
      onToggle: onToggle,
      icon: Icons.help_outline,
      iconColor: AppColors.gray,
      backgroundColor: AppColors.lightGray,
      totalPrice: totalPrice,
      completedTotal: completedTotal,
      showTotalPrice: showTotalPrice,
      showCompletedTotal: showCompletedTotal,
      onDragAccept: onDragAccept,
    );
  }

  /// Factory for store section using Store model
  factory StoreSectionHeader.storeById({
    required Store? store,
    required String storeId,
    required int itemCount,
    bool isExpanded = true,
    VoidCallback? onToggle,
    double? totalPrice,
    double? completedTotal,
    bool showTotalPrice = false,
    bool showCompletedTotal = false,
    VoidCallback? onDragAccept,
  }) {
    return StoreSectionHeader(
      store: store,
      title: store?.name ?? 'Ukendt butik',
      emoji: store?.emoji,
      itemCount: itemCount,
      isExpanded: isExpanded,
      onToggle: onToggle,
      totalPrice: totalPrice,
      completedTotal: completedTotal,
      showTotalPrice: showTotalPrice,
      showCompletedTotal: showCompletedTotal,
      onDragAccept: onDragAccept,
    );
  }

  @override
  Widget build(BuildContext context) {
    String formatPrice(double price) {
      return '${price.toStringAsFixed(2).replaceAll('.', ',')} kr';
    }

    return GestureDetector(
      onTap: onToggle,
      child: Container(
        margin: const EdgeInsets.only(
          top: AppSpacing.md,
          bottom: AppSpacing.sm,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: backgroundColor ?? AppColors.primaryPurpleSubtle,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
        ),
        child: Row(
          children: [
            // Icon or emoji
            if (emoji != null)
              Text(emoji!, style: const TextStyle(fontSize: 18))
            else if (store?.emoji != null)
              Text(store!.emoji!, style: const TextStyle(fontSize: 18))
            else if (icon != null)
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: backgroundColor == AppColors.primaryPurple
                      ? AppColors.white.withOpacity(0.2)
                      : iconColor?.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
                ),
                child: Icon(
                  icon,
                  size: 16,
                  color: iconColor,
                ),
              ),
            const SizedBox(width: AppSpacing.sm),

            // Title
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: backgroundColor == AppColors.primaryPurple
                          ? AppColors.white
                          : AppColors.black,
                    ),
              ),
            ),

            // Completed total (green)
            if (showCompletedTotal && completedTotal != null && completedTotal! > 0) ...[
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xs,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
                ),
                child: Text(
                  formatPrice(completedTotal!),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.success,
                        fontSize: 10,
                      ),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
            ],

            // Total price
            if (showTotalPrice && totalPrice != null && totalPrice! > 0) ...[
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xs,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: backgroundColor == AppColors.primaryPurple
                      ? AppColors.white.withOpacity(0.2)
                      : AppColors.primaryPurple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
                ),
                child: Text(
                  formatPrice(totalPrice!),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: backgroundColor == AppColors.primaryPurple
                            ? AppColors.white
                            : AppColors.primaryPurple,
                        fontSize: 10,
                      ),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
            ],

            // Item count
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: backgroundColor == AppColors.primaryPurple
                    ? AppColors.white.withOpacity(0.2)
                    : AppColors.white,
                borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
              ),
              child: Text(
                '$itemCount',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: backgroundColor == AppColors.primaryPurple
                          ? AppColors.white
                          : AppColors.darkGray,
                    ),
              ),
            ),

            // Expand/collapse icon
            if (onToggle != null) ...[
              const SizedBox(width: AppSpacing.sm),
              AnimatedRotation(
                turns: isExpanded ? 0 : -0.25,
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  Icons.expand_more,
                  size: 20,
                  color: backgroundColor == AppColors.primaryPurple
                      ? AppColors.white
                      : AppColors.gray,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
