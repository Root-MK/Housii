import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/providers/home_provider.dart';
import '../../data/food_service.dart';
import '../../data/models/meal_plan_model.dart';
import '../providers/food_providers.dart';

/// Tab 1: Meal Plan - shows today + 7 days
class MealPlanTab extends ConsumerWidget {
  const MealPlanTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dates = ref.watch(mealPlanDatesProvider);
    final plansAsync = ref.watch(mealPlansProvider);

    return plansAsync.when(
      data: (plans) => ListView.separated(
        padding: const EdgeInsets.all(AppSpacing.md),
        itemCount: dates.length,
        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
        itemBuilder: (context, index) {
          final date = dates[index];
          final plan = _getPlanForDate(plans, date);
          return _MealPlanCard(
            date: date,
            plan: plan,
            isToday: index == 0,
          );
        },
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Fejl: $e')),
    );
  }

  MealPlanModel? _getPlanForDate(List<MealPlanModel> plans, DateTime date) {
    final dateOnly = DateTime(date.year, date.month, date.day);
    for (final plan in plans) {
      if (plan.dateOnly == dateOnly) return plan;
    }
    return null;
  }
}

class _MealPlanCard extends ConsumerWidget {
  final DateTime date;
  final MealPlanModel? plan;
  final bool isToday;

  const _MealPlanCard({
    required this.date,
    this.plan,
    required this.isToday,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return GestureDetector(
      onLongPress: plan != null ? () => _showDeleteDialog(context, ref) : null,
      child: Container(
        decoration: BoxDecoration(
          color: isToday ? AppColors.primaryPurpleSubtle : AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isToday ? AppColors.primaryPurple : AppColors.lightGray,
            width: isToday ? 2 : 1,
          ),
        ),
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            // Date column
            SizedBox(
              width: 100,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    getDanishWeekday(date),
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: isToday ? FontWeight.bold : FontWeight.w500,
                      color: isToday ? AppColors.primaryPurple : AppColors.darkGray,
                    ),
                  ),
                  Text(
                    '${date.day}/${date.month}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.gray,
                    ),
                  ),
                  if (isToday) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primaryPurple,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'I dag',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: AppColors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            // Food content
            Expanded(
              child: plan != null
                  ? _FoodContent(plan: plan!)
                  : Text(
                      'Ingen planlagt mad',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.gray,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Slet planlagt mad'),
        content: Text('Vil du slette "${plan!.foodName}" fra ${getDanishWeekday(date)}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuller'),
          ),
          TextButton(
            onPressed: () async {
              final home = ref.read(currentHomeProvider).value;
              if (home != null) {
                await ref.read(foodServiceProvider).deleteMealPlan(home.id, plan!.id);
              }
              if (context.mounted) Navigator.pop(context);
            },
            child: Text(
              'Slet',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}

class _FoodContent extends StatelessWidget {
  final MealPlanModel plan;

  const _FoodContent({required this.plan});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        // Emoji
        Text(
          plan.emoji.emoji,
          style: const TextStyle(fontSize: 28),
        ),
        const SizedBox(width: AppSpacing.sm),
        // Food name with auto-scaling text
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  plan.foodName,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (plan.description != null && plan.description!.isNotEmpty)
                Text(
                  plan.description!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.gray,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),
      ],
    );
  }
}
