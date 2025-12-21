import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/constants/strings_da.dart';
import '../../data/models/shopping_item.dart';
import '../providers/shopping_providers.dart';

/// Shopping item card with swipe-to-complete and context menu
class ShoppingItemCard extends ConsumerStatefulWidget {
  final ShoppingItem item;
  final VoidCallback onComplete;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final Widget? dragHandle;

  const ShoppingItemCard({
    super.key,
    required this.item,
    required this.onComplete,
    required this.onEdit,
    required this.onDelete,
    this.dragHandle,
  });

  @override
  ConsumerState<ShoppingItemCard> createState() => _ShoppingItemCardState();
}

class _ShoppingItemCardState extends ConsumerState<ShoppingItemCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;
  bool _isCompleting = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _slideAnimation = Tween<double>(begin: 0, end: -100).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _fadeAnimation = Tween<double>(begin: 1, end: 0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleComplete() async {
    if (_isCompleting) return;
    setState(() => _isCompleting = true);

    HapticFeedback.mediumImpact();
    await _controller.forward();
    widget.onComplete();
  }

  void _showContextMenu(BuildContext context, Offset position) {
    HapticFeedback.mediumImpact();

    showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy,
        position.dx + 1,
        position.dy + 1,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
      ),
      color: AppColors.white,
      elevation: 8,
      items: [
        PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              Icon(Icons.edit_outlined,
                  color: AppColors.primaryPurple, size: 20),
              const SizedBox(width: AppSpacing.sm),
              Text(AppStrings.edit),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'complete',
          child: Row(
            children: [
              Icon(Icons.check_circle_outline,
                  color: AppColors.success, size: 20),
              const SizedBox(width: AppSpacing.sm),
              Text(AppStrings.markComplete),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete_outline, color: AppColors.error, size: 20),
              const SizedBox(width: AppSpacing.sm),
              Text(AppStrings.delete, style: TextStyle(color: AppColors.error)),
            ],
          ),
        ),
      ],
    ).then((value) {
      switch (value) {
        case 'edit':
          widget.onEdit();
          break;
        case 'complete':
          _handleComplete();
          break;
        case 'delete':
          widget.onDelete();
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(_slideAnimation.value, 0),
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: child,
          ),
        );
      },
      child: Dismissible(
        key: Key(widget.item.id),
        direction: DismissDirection.endToStart,
        dismissThresholds: const {DismissDirection.endToStart: 0.3},
        // Don't use onDismissed - it causes issues when Firebase stream updates
        // before the dismissible animation completes
        // Instead, trigger action in confirmDismiss and return false to keep
        // the widget in tree until Firebase stream removes it
        confirmDismiss: (direction) async {
          HapticFeedback.mediumImpact();
          // Trigger the complete action
          widget.onComplete();
          // Return false - we don't want Dismissible to remove the widget
          // The item will be hidden via _dismissedItemIds and removed
          // properly when Firebase stream updates
          return false;
        },
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.success,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
          ),
          child: const Icon(
            Icons.check_rounded,
            color: AppColors.white,
            size: 28,
          ),
        ),
        child: GestureDetector(
          onLongPressStart: (details) {
            _showContextMenu(context, details.globalPosition);
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
              border: widget.item.important
                  ? Border.all(
                      color: AppColors.primaryPurple.withOpacity(0.3),
                      width: 1.5)
                  : null,
              boxShadow: [
                BoxShadow(
                  color: AppColors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: Row(
                children: [
                  // Drag handle (optional, provided externally for drag functionality)
                  if (widget.dragHandle != null) ...[
                    widget.dragHandle!,
                    const SizedBox(width: AppSpacing.xs),
                  ],
                  
                  // Leading indicator
                  _buildLeadingIndicator(),
                  const SizedBox(width: AppSpacing.md),

                  // Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Name and amount
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                widget.item.name,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyLarge
                                    ?.copyWith(
                                      fontWeight: FontWeight.w500,
                                      decoration: !widget.item.active
                                          ? TextDecoration.lineThrough
                                          : null,
                                      decorationColor: AppColors.gray,
                                      color: !widget.item.active
                                          ? AppColors.gray
                                          : null,
                                    ),
                              ),
                            ),
                            if (widget.item.displayAmount > 1)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.sm,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.lightGray,
                                  borderRadius: BorderRadius.circular(
                                      AppSpacing.radiusSmall),
                                ),
                                child: Text(
                                  'x${widget.item.displayAmount}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.darkGray,
                                      ),
                                ),
                              ),
                          ],
                        ),

                        // Price and discount info
                        if (widget.item.price != null ||
                            widget.item.hasActiveDiscount ||
                            widget.item.hasUpcomingDiscount ||
                            widget.item.hasExpiredDiscount)
                          const SizedBox(height: AppSpacing.xs),

                        if (widget.item.price != null ||
                            widget.item.hasActiveDiscount ||
                            widget.item.hasUpcomingDiscount ||
                            widget.item.hasExpiredDiscount)
                          Row(
                            children: [
                              if (widget.item.price != null)
                                Text(
                                  '${widget.item.price!.toStringAsFixed(2)} kr',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: AppColors.gray,
                                      ),
                                ),
                              if (widget.item.price != null &&
                                  (widget.item.hasActiveDiscount ||
                                      widget.item.hasUpcomingDiscount ||
                                      widget.item.hasExpiredDiscount))
                                const SizedBox(width: AppSpacing.sm),
                              if (widget.item.hasExpiredDiscount)
                                _buildExpiredDiscountBadge(context)
                              else if (widget.item.hasActiveDiscount)
                                _buildDiscountBadge(context, isActive: true)
                              else if (widget.item.hasUpcomingDiscount)
                                _buildDiscountBadge(context, isActive: false),
                            ],
                          ),
                      ],
                    ),
                  ),

                  // Trailing icon
                  Icon(
                    Icons.chevron_left_rounded,
                    color: AppColors.lightGray,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLeadingIndicator() {
    if (widget.item.important) {
      return Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
        ),
        child: const Icon(
          Icons.priority_high_rounded,
          color: AppColors.white,
          size: 16,
        ),
      );
    }

    if (widget.item.lookoutFor) {
      return Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: AppColors.warning.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
        ),
        child: Icon(
          Icons.visibility_outlined,
          color: AppColors.warning,
          size: 16,
        ),
      );
    }

    if (widget.item.storeId != null) {
      final store = ref.watch(storeByIdProvider(widget.item.storeId!));
      return Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: AppColors.primaryPurpleSubtle,
          borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
        ),
        child: Center(
          child: Text(
            store?.emoji ?? '🛒',
            style: const TextStyle(fontSize: 14),
          ),
        ),
      );
    }

    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: AppColors.lightGray,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
      ),
      child: Icon(
        Icons.shopping_bag_outlined,
        color: AppColors.gray,
        size: 16,
      ),
    );
  }

  Widget _buildDiscountBadge(BuildContext context, {required bool isActive}) {
    final dateFormat = DateFormat('d/M');
    final discountText = isActive
        ? '${AppStrings.discountBadge} til ${dateFormat.format(widget.item.discountEnd!)}'
        : '${AppStrings.upcomingDiscount} ${dateFormat.format(widget.item.discountStart!)}';

    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2),
      decoration: BoxDecoration(
        color: isActive
            ? AppColors.success.withOpacity(0.1)
            : AppColors.warning.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isActive ? Icons.local_offer : Icons.schedule,
            size: 12,
            color: isActive ? AppColors.success : AppColors.warning,
          ),
          const SizedBox(width: 4),
          Text(
            discountText,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: isActive ? AppColors.success : AppColors.warning,
                  fontSize: 11,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpiredDiscountBadge(BuildContext context) {
    final dateFormat = DateFormat('d/M');
    final expiredText =
        '${AppStrings.expiredDiscount} ${dateFormat.format(widget.item.discountEnd!)}';

    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.timer_off,
            size: 12,
            color: AppColors.error,
          ),
          const SizedBox(width: 4),
          Text(
            expiredText,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.error,
                  fontSize: 11,
                ),
          ),
        ],
      ),
    );
  }
}
