import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/providers/home_provider.dart';
import '../../data/food_service.dart';
import '../../data/models/meal_plan_model.dart';
import '../../data/models/food_idea_model.dart';
import '../../data/models/freezer_item_model.dart';

/// Currently selected tab index (0: Meal Plan, 1: Food Ideas, 2: Freezer)
/// Defaults to 1 (Food Ideas - middle tab)
final foodTabIndexProvider = StateProvider<int>((ref) => 1);

/// Search query for food ideas
final foodSearchQueryProvider = StateProvider<String>((ref) => '');

/// Stream of meal plans for the next 8 days (today + 7)
final mealPlansProvider = StreamProvider<List<MealPlanModel>>((ref) {
  final homeAsync = ref.watch(currentHomeProvider);
  final foodService = ref.watch(foodServiceProvider);

  return homeAsync.when(
    data: (home) {
      if (home == null) return Stream.value([]);
      final today = DateTime.now();
      final endDate = today.add(const Duration(days: 7));
      return foodService.watchMealPlans(home.id, today, endDate);
    },
    loading: () => Stream.value([]),
    error: (_, __) => Stream.value([]),
  );
});

/// Get meal plan for a specific date
final mealPlanForDateProvider = Provider.family<MealPlanModel?, DateTime>((ref, date) {
  final plansAsync = ref.watch(mealPlansProvider);
  final dateOnly = DateTime(date.year, date.month, date.day);

  return plansAsync.when(
    data: (plans) {
      for (final plan in plans) {
        if (plan.dateOnly == dateOnly) return plan;
      }
      return null;
    },
    loading: () => null,
    error: (_, __) => null,
  );
});

/// Stream of all food ideas
final foodIdeasProvider = StreamProvider<List<FoodIdeaModel>>((ref) {
  final homeAsync = ref.watch(currentHomeProvider);
  final foodService = ref.watch(foodServiceProvider);

  return homeAsync.when(
    data: (home) {
      if (home == null) return Stream.value([]);
      return foodService.watchFoodIdeas(home.id);
    },
    loading: () => Stream.value([]),
    error: (_, __) => Stream.value([]),
  );
});

/// Filtered food ideas based on search query
final filteredFoodIdeasProvider = Provider<List<FoodIdeaModel>>((ref) {
  final ideasAsync = ref.watch(foodIdeasProvider);
  final searchQuery = ref.watch(foodSearchQueryProvider);
  final foodService = ref.watch(foodServiceProvider);

  return ideasAsync.when(
    data: (ideas) => foodService.searchFoodIdeas(ideas, searchQuery),
    loading: () => [],
    error: (_, __) => [],
  );
});

/// Stream of all freezer items
final freezerItemsProvider = StreamProvider<List<FreezerItemModel>>((ref) {
  final homeAsync = ref.watch(currentHomeProvider);
  final foodService = ref.watch(foodServiceProvider);

  return homeAsync.when(
    data: (home) {
      if (home == null) return Stream.value([]);
      return foodService.watchFreezerItems(home.id);
    },
    loading: () => Stream.value([]),
    error: (_, __) => Stream.value([]),
  );
});

/// Date range for meal planning (today + 7 days)
final mealPlanDatesProvider = Provider<List<DateTime>>((ref) {
  final today = DateTime.now();
  return List.generate(8, (index) => DateTime(
    today.year,
    today.month,
    today.day,
  ).add(Duration(days: index)));
});

/// Danish weekday names
const danishWeekdays = [
  'Mandag',
  'Tirsdag',
  'Onsdag',
  'Torsdag',
  'Fredag',
  'Lørdag',
  'Søndag',
];

/// Get Danish weekday name from DateTime
String getDanishWeekday(DateTime date) {
  // DateTime.weekday is 1 = Monday, 7 = Sunday
  return danishWeekdays[date.weekday - 1];
}

/// Format date as "Mandag d. 16/12"
String formatMealPlanDate(DateTime date) {
  final weekday = getDanishWeekday(date);
  final day = date.day;
  final month = date.month;
  return '$weekday d. $day/$month';
}

/// Check if date is today
bool isToday(DateTime date) {
  final now = DateTime.now();
  return date.year == now.year && date.month == now.month && date.day == now.day;
}
