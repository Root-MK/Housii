import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../providers/lists_providers.dart';

/// Filter bar at the top of the lists screen
class ListFilterBar extends ConsumerWidget {
  const ListFilterBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentFilter = ref.watch(listFilterProvider);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border(
          bottom: BorderSide(color: AppColors.lightGray.withOpacity(0.5)),
        ),
      ),
      child: Row(
        children: [
          _FilterChip(
            label: 'Alle',
            isSelected: currentFilter == ListFilter.all,
            onTap: () => ref.read(listFilterProvider.notifier).state = ListFilter.all,
          ),
          const SizedBox(width: AppSpacing.sm),
          _FilterChip(
            label: 'Personlige',
            isSelected: currentFilter == ListFilter.personal,
            onTap: () => ref.read(listFilterProvider.notifier).state = ListFilter.personal,
          ),
          const SizedBox(width: AppSpacing.sm),
          _FilterChip(
            label: 'Husstand',
            isSelected: currentFilter == ListFilter.household,
            onTap: () => ref.read(listFilterProvider.notifier).state = ListFilter.household,
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryPurple : AppColors.offWhite,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
          border: Border.all(
            color: isSelected ? AppColors.primaryPurple : AppColors.lightGray,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: isSelected ? AppColors.white : AppColors.darkGray,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
