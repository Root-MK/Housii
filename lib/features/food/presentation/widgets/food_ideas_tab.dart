import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/providers/home_provider.dart';
import '../../data/food_service.dart';
import '../../data/models/food_idea_model.dart';
import '../../data/models/meal_plan_model.dart';
import '../providers/food_providers.dart';

/// Tab 2: Food Ideas - list of meal ideas with search and planning
class FoodIdeasTab extends ConsumerWidget {
  const FoodIdeasTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filteredIdeas = ref.watch(filteredFoodIdeasProvider);
    final searchQuery = ref.watch(foodSearchQueryProvider);

    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Søg efter mad...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () => ref.read(foodSearchQueryProvider.notifier).state = '',
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.lightGray),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.lightGray),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.primaryPurple, width: 2),
              ),
              filled: true,
              fillColor: AppColors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            onChanged: (value) => ref.read(foodSearchQueryProvider.notifier).state = value,
          ),
        ),
        // Food ideas list
        Expanded(
          child: filteredIdeas.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.restaurant_menu,
                        size: 64,
                        color: AppColors.lightGray,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        searchQuery.isNotEmpty 
                            ? 'Ingen resultater for "$searchQuery"'
                            : 'Ingen madidéer endnu',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppColors.gray,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'Tryk + for at tilføje en madidé',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.gray,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  itemCount: filteredIdeas.length,
                  separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (context, index) {
                    final idea = filteredIdeas[index];
                    return _FoodIdeaCard(idea: idea);
                  },
                ),
        ),
      ],
    );
  }
}

class _FoodIdeaCard extends ConsumerWidget {
  final FoodIdeaModel idea;

  const _FoodIdeaCard({required this.idea});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Dismissible(
      key: Key(idea.id),
      direction: DismissDirection.startToEnd,
      confirmDismiss: (_) async {
        _showPlanningSheet(context, ref);
        return false; // Don't dismiss, just show the sheet
      },
      background: Container(
        decoration: BoxDecoration(
          color: AppColors.primaryPurple,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: AppSpacing.lg),
        child: Row(
          children: [
            Icon(Icons.calendar_today, color: AppColors.white),
            const SizedBox(width: AppSpacing.sm),
            Text(
              'Planlæg',
              style: theme.textTheme.titleMedium?.copyWith(
                color: AppColors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      child: GestureDetector(
        onLongPress: () => _showPlanningSheet(context, ref),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.lightGray),
          ),
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              // Emoji
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primaryPurpleSubtle,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    idea.emoji.emoji,
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      idea.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (idea.description != null && idea.description!.isNotEmpty)
                      Text(
                        idea.description!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.gray,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    if (idea.hasBeenPlanned)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          'Sidst planlagt: ${_formatLastPlanned(idea.lastPlannedAt!)}',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: AppColors.gray,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              // Swipe hint icon
              Icon(
                Icons.chevron_right,
                color: AppColors.lightGray,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatLastPlanned(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date).inDays;
    if (diff == 0) return 'I dag';
    if (diff == 1) return 'I går';
    if (diff < 7) return '$diff dage siden';
    if (diff < 30) return '${diff ~/ 7} uger siden';
    return '${date.day}/${date.month}';
  }

  void _showPlanningSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _PlanningSheet(idea: idea),
    );
  }
}

class _PlanningSheet extends ConsumerWidget {
  final FoodIdeaModel idea;

  const _PlanningSheet({required this.idea});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final dates = ref.watch(mealPlanDatesProvider);
    final plansAsync = ref.watch(mealPlansProvider);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.lightGray,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                Text(
                  idea.emoji.emoji,
                  style: const TextStyle(fontSize: 32),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Planlæg ${idea.name}',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Vælg en dag',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppColors.gray,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Date list
          plansAsync.when(
            data: (plans) => SizedBox(
              height: 400,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                itemCount: dates.length,
                itemBuilder: (context, index) {
                  final date = dates[index];
                  final existingPlan = _getPlanForDate(plans, date);
                  final isToday = index == 0;

                  return ListTile(
                    leading: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: isToday ? AppColors.primaryPurpleSubtle : AppColors.lightGray,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          '${date.day}',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isToday ? AppColors.primaryPurple : AppColors.darkGray,
                          ),
                        ),
                      ),
                    ),
                    title: Row(
                      children: [
                        Text(
                          getDanishWeekday(date),
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: isToday ? FontWeight.bold : FontWeight.w500,
                          ),
                        ),
                        if (isToday) ...[
                          const SizedBox(width: AppSpacing.sm),
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
                    subtitle: existingPlan != null
                        ? Row(
                            children: [
                              Text(
                                existingPlan.emoji.emoji,
                                style: const TextStyle(fontSize: 14),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                existingPlan.foodName,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: AppColors.gray,
                                ),
                              ),
                            ],
                          )
                        : Text(
                            'Ingen planlagt',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppColors.gray,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                    trailing: existingPlan != null
                        ? Icon(Icons.swap_horiz, color: AppColors.warning)
                        : Icon(Icons.add, color: AppColors.primaryPurple),
                    onTap: () => _planFood(context, ref, date, existingPlan),
                  );
                },
              ),
            ),
            loading: () => const SizedBox(
              height: 200,
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => SizedBox(
              height: 200,
              child: Center(child: Text('Fejl: $e')),
            ),
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom + AppSpacing.md),
        ],
      ),
    );
  }

  MealPlanModel? _getPlanForDate(List<MealPlanModel> plans, DateTime date) {
    final dateOnly = DateTime(date.year, date.month, date.day);
    for (final plan in plans) {
      if (plan.dateOnly == dateOnly) return plan;
    }
    return null;
  }

  Future<void> _planFood(
    BuildContext context,
    WidgetRef ref,
    DateTime date,
    MealPlanModel? existingPlan,
  ) async {
    final home = ref.read(currentHomeProvider).value;
    // User info obtained from home owner for now
    if (home == null) return;

    final foodService = ref.read(foodServiceProvider);

    // If there's an existing plan, delete it first
    if (existingPlan != null) {
      await foodService.deleteMealPlan(home.id, existingPlan.id);
    }

    // Create new meal plan
    await foodService.createMealPlan(
      homeId: home.id,
      date: date,
      foodIdeaId: idea.id,
      foodName: idea.name,
      description: idea.description,
      emoji: idea.emoji,
      createdBy: home.ownerId, // Using home owner for now
    );

    // Mark idea as planned (moves to bottom)
    await foodService.markFoodIdeaAsPlanned(home.id, idea.id);

    if (context.mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${idea.name} planlagt til ${getDanishWeekday(date)}'),
          backgroundColor: AppColors.primaryPurple,
        ),
      );
    }
  }
}
