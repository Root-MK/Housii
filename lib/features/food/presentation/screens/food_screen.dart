import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/constants/strings_da.dart';
import '../providers/food_providers.dart';
import '../widgets/meal_plan_tab.dart';
import '../widgets/food_ideas_tab.dart';
import '../widgets/freezer_tab.dart';
import '../widgets/add_food_idea_sheet.dart';
import '../widgets/add_freezer_item_sheet.dart';

/// Food module screen with 3 tabs: Meal Plan, Food Ideas, Freezer
class FoodScreen extends ConsumerStatefulWidget {
  const FoodScreen({super.key});

  @override
  ConsumerState<FoodScreen> createState() => _FoodScreenState();
}

class _FoodScreenState extends ConsumerState<FoodScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    // Default to middle tab (index 1 = Food Ideas)
    _tabController = TabController(length: 3, vsync: this, initialIndex: 1);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        ref.read(foodTabIndexProvider.notifier).state = _tabController.index;
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Tab bar
        Container(
          color: AppColors.white,
          child: TabBar(
            controller: _tabController,
            labelColor: AppColors.primaryPurple,
            unselectedLabelColor: AppColors.gray,
            indicatorColor: AppColors.primaryPurple,
            indicatorWeight: 3,
            tabs: const [
              Tab(
                icon: Icon(Icons.calendar_month),
                text: AppStrings.mealPlan,
              ),
              Tab(
                icon: Icon(Icons.lightbulb_outline),
                text: AppStrings.foodIdeas,
              ),
              Tab(
                icon: Icon(Icons.kitchen),
                text: AppStrings.freezer,
              ),
            ],
          ),
        ),
        // Tab content
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: const [
              MealPlanTab(),
              FoodIdeasTab(),
              FreezerTab(),
            ],
          ),
        ),
      ],
    );
  }
}

/// Get the FAB action for the current food tab
void showFoodFabAction(BuildContext context, int tabIndex) {
  switch (tabIndex) {
    case 0:
      // Meal Plan tab - could show a quick add or navigate to ideas
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Gå til Madidéer for at planlægge'),
          action: SnackBarAction(
            label: 'OK',
            onPressed: () {},
          ),
        ),
      );
      break;
    case 1:
      // Food Ideas tab - add new idea
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => const AddFoodIdeaSheet(),
      );
      break;
    case 2:
      // Freezer tab - add new item
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => const AddFreezerItemSheet(),
      );
      break;
  }
}
