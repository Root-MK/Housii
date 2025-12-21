import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../data/models/list_model.dart';

/// Tabs for switching between lists
class ListTabs extends StatelessWidget {
  final List<ListModel> lists;
  final int selectedIndex;
  final Function(int) onTabSelected;

  const ListTabs({
    super.key,
    required this.lists,
    required this.selectedIndex,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border(
          bottom: BorderSide(color: AppColors.lightGray.withOpacity(0.5)),
        ),
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        itemCount: lists.length,
        itemBuilder: (context, index) {
          final list = lists[index];
          final isSelected = index == selectedIndex;
          
          return GestureDetector(
            onTap: () => onTabSelected(index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xs,
                vertical: AppSpacing.sm,
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
              ),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primaryPurple : Colors.transparent,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                border: Border.all(
                  color: isSelected ? AppColors.primaryPurple : AppColors.lightGray,
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    list.isChecklist ? Icons.checklist : Icons.list,
                    size: 16,
                    color: isSelected ? AppColors.white : AppColors.gray,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    list.name,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: isSelected ? AppColors.white : AppColors.darkGray,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                  if (list.isPersonal) ...[
                    const SizedBox(width: AppSpacing.xs),
                    Icon(
                      Icons.person,
                      size: 14,
                      color: isSelected ? AppColors.white.withOpacity(0.7) : AppColors.gray,
                    ),
                  ],
                  if (list.isChecklist && list.itemCount > 0) ...[
                    const SizedBox(width: AppSpacing.xs),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isSelected 
                            ? AppColors.white.withOpacity(0.2)
                            : AppColors.lightGray,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${list.completedCount}/${list.itemCount}',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: isSelected ? AppColors.white : AppColors.gray,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
