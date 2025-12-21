import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../data/models/list_item_model.dart';

/// Card widget for displaying a list item
class ListItemCard extends StatelessWidget {
  final ListItemModel item;
  final bool isChecklist;
  final VoidCallback? onTap;
  final void Function(Offset position)? onLongPress;
  final VoidCallback? onCheck;

  const ListItemCard({
    super.key,
    required this.item,
    required this.isChecklist,
    this.onTap,
    this.onLongPress,
    this.onCheck,
  });

  Color _getImportanceColor() {
    switch (item.importance) {
      case ItemImportance.low:
        return AppColors.gray;
      case ItemImportance.normal:
        return AppColors.darkGray;
      case ItemImportance.high:
        return AppColors.warning;
      case ItemImportance.urgent:
        return AppColors.error;
    }
  }

  IconData _getImportanceIcon() {
    switch (item.importance) {
      case ItemImportance.low:
        return Icons.arrow_downward;
      case ItemImportance.normal:
        return Icons.remove;
      case ItemImportance.high:
        return Icons.arrow_upward;
      case ItemImportance.urgent:
        return Icons.priority_high;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPressStart: (details) {
        HapticFeedback.mediumImpact();
        onLongPress?.call(details.globalPosition);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Checkbox for checklists
                  if (isChecklist)
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        onCheck?.call();
                      },
                      child: Container(
                        margin: const EdgeInsets.only(right: AppSpacing.sm, top: 2),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: item.isChecked ? AppColors.success : Colors.transparent,
                            border: Border.all(
                              color: item.isChecked ? AppColors.success : AppColors.lightGray,
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: item.isChecked
                              ? const Icon(Icons.check, size: 16, color: AppColors.white)
                              : null,
                        ),
                      ),
                    ),
                  
                  // Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title row
                        Row(
                          children: [
                            // Importance indicator
                            if (item.importance != ItemImportance.normal)
                              Padding(
                                padding: const EdgeInsets.only(right: AppSpacing.xs),
                                child: Icon(
                                  _getImportanceIcon(),
                                  size: 16,
                                  color: _getImportanceColor(),
                                ),
                              ),
                            
                            // Title
                            Expanded(
                              child: Text(
                                item.title,
                                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  decoration: item.isChecked ? TextDecoration.lineThrough : null,
                                  color: item.isChecked ? AppColors.gray : AppColors.darkGray,
                                ),
                              ),
                            ),
                          ],
                        ),
                        
                        // Details preview
                        if (item.details != null && item.details!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: AppSpacing.xs),
                            child: Text(
                              _stripHtml(item.details!),
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.gray,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                    ),
                  ),
                  
                  // Drag handle
                  const Icon(
                    Icons.drag_handle,
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

  String _stripHtml(String html) {
    // Simple HTML stripping for preview
    return html
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .trim();
  }
}
