import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/constants/strings_da.dart';
import '../../../../core/router/app_router.dart';
import '../../../../shared/providers/auth_provider.dart';
import '../../../../shared/providers/home_provider.dart';
import '../../../shopping/presentation/widgets/add_shopping_item_sheet.dart';
import '../../../shopping/presentation/widgets/manage_stores_sheet.dart';
import '../../../shopping/presentation/widgets/receipt_sheet.dart';
import '../../../lists/presentation/widgets/add_list_sheet.dart';
import '../../../lists/presentation/widgets/add_list_item_sheet.dart';
import '../../../lists/presentation/widgets/archive_sheet.dart';
import '../../../lists/presentation/widgets/list_management_sheet.dart';
import '../../../lists/presentation/providers/lists_providers.dart';
import '../../../food/presentation/providers/food_providers.dart';
import '../../../food/presentation/screens/food_screen.dart';
import '../../../garden/presentation/providers/garden_view_provider.dart';
import '../../../garden/presentation/widgets/bed_form_sheet.dart';
import '../../../garden/presentation/widgets/garden_settings_sheet.dart';
import '../../../garden/data/garden_service.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/add_fab.dart';

/// Main shell screen with bottom navigation
class MainShellScreen extends ConsumerWidget {
  final Widget child;

  const MainShellScreen({
    super.key,
    required this.child,
  });

  int _getCurrentIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    switch (location) {
      case AppRoutes.shopping:
        return 0;
      case AppRoutes.lists:
        return 1;
      case AppRoutes.food:
        return 2;
      case AppRoutes.garden:
        return 3;
      default:
        return 0;
    }
  }

  void _onItemTapped(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go(AppRoutes.shopping);
        break;
      case 1:
        context.go(AppRoutes.lists);
        break;
      case 2:
        context.go(AppRoutes.food);
        break;
      case 3:
        context.go(AppRoutes.garden);
        break;
    }
  }

  void _onAddPressed(BuildContext context, WidgetRef ref) {
    final currentIndex = _getCurrentIndex(context);
    final home = ref.read(currentHomeProvider).valueOrNull;
    final user = ref.read(currentUserProvider).valueOrNull;

    debugPrint(
        '➕ FAB pressed: index=$currentIndex, home=${home?.id}, user=${user?.id}');

    // For shopping module, show the add item sheet
    if (currentIndex == 0 && home != null && user != null) {
      debugPrint('🛒 Opening AddShoppingItemSheet');
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        useRootNavigator: true,
        builder: (context) => AddShoppingItemSheet(
          homeId: home.id,
          userId: user.id,
        ),
      );
      return;
    }

    if (currentIndex == 0 && (home == null || user == null)) {
      debugPrint('⚠️ Cannot open sheet: home or user is null');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Indlæser... Prøv igen.')),
      );
      return;
    }

    // For lists module, show add options
    if (currentIndex == 1 && home != null && user != null) {
      debugPrint('📋 Opening Lists add options');
      _showListsAddSheet(context, ref);
      return;
    }

    if (currentIndex == 1 && (home == null || user == null)) {
      debugPrint('⚠️ Cannot open sheet: home or user is null');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Indlæser... Prøv igen.')),
      );
      return;
    }

    // For food module, delegate to food screen's FAB action
    if (currentIndex == 2 && home != null && user != null) {
      debugPrint('🍽️ Opening Food add options');
      final foodTabIndex = ref.read(foodTabIndexProvider);
      showFoodFabAction(context, foodTabIndex);
      return;
    }

    if (currentIndex == 2 && (home == null || user == null)) {
      debugPrint('⚠️ Cannot open sheet: home or user is null');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Indlæser... Prøv igen.')),
      );
      return;
    }

    // For garden module, control edit mode
    if (currentIndex == 3) {
      debugPrint('🌱 Garden FAB pressed');
      final gardenViewState = ref.read(gardenViewProvider);
      final beds = ref.read(gardenBedsProvider).valueOrNull ?? [];
      
      // If in Visual tab:
      if (gardenViewState.tabIndex == 1) {
        if (beds.isEmpty) {
          // Empty: show add bed sheet
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            builder: (context) => const BedFormSheet(),
          );
        } else {
          // Toggle edit mode
          ref.read(gardenViewProvider.notifier).toggleEditMode();
        }
        return;
      } else {
        // In List tab - show coming soon or add bed
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          builder: (context) => const BedFormSheet(),
        );
        return;
      }
    }

    // For other modules, show placeholder
    String title;
    switch (currentIndex) {
      case 0:
        title = AppStrings.shopping;
        break;
      case 1:
        title = AppStrings.household;
        break;
      case 2:
        title = AppStrings.food;
        break;
      case 3:
        title = AppStrings.garden;
        break;
      default:
        title = AppStrings.add;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusXLarge),
        ),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.lightGray,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              '${AppStrings.add} - $title',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              AppStrings.comingSoon,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.gray,
                  ),
            ),
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }

  void _showListsAddSheet(BuildContext context, WidgetRef ref) {
    final selectedList = ref.read(selectedListProvider);
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useRootNavigator: true,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppSpacing.radiusXLarge),
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.lightGray,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'Tilføj',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: AppSpacing.lg),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: AppColors.primaryPurpleSubtle,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
                    ),
                    child: Icon(Icons.add_task, color: AppColors.primaryPurple),
                  ),
                  title: const Text('Tilføj punkt til listen'),
                  subtitle: Text(
                    selectedList != null 
                        ? 'Tilføj til "${selectedList.name}"'
                        : 'Opret en liste først',
                  ),
                  onTap: selectedList != null
                      ? () {
                          Navigator.pop(context);
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            useRootNavigator: true,
                            builder: (context) => AddListItemSheet(list: selectedList),
                          );
                        }
                      : null,
                ),
                const SizedBox(height: AppSpacing.sm),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: AppColors.accentGreenSubtle,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
                    ),
                    child: Icon(Icons.playlist_add, color: AppColors.accentGreen),
                  ),
                  title: const Text('Opret ny liste'),
                  subtitle: const Text('Opret en ny liste'),
                  onTap: () {
                    Navigator.pop(context);
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      useRootNavigator: true,
                      builder: (context) => const AddListSheet(),
                    );
                  },
                ),
                const SizedBox(height: AppSpacing.md),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = _getCurrentIndex(context);

    return Scaffold(
      backgroundColor: AppColors.offWhite,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        title: ShaderMask(
          shaderCallback: (bounds) =>
              AppColors.primaryGradient.createShader(bounds),
          child: Text(
            'Housii',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.white,
                ),
          ),
        ),
        actions: [
          // Store management - only show on shopping screen
          if (currentIndex == 0) ...[
            IconButton(
              icon: const Icon(Icons.receipt_long_outlined),
              tooltip: 'Dagens kvittering',
              onPressed: () => showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                useRootNavigator: true,
                builder: (context) => const ReceiptSheet(),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.store_outlined),
              tooltip: 'Administrer butikker',
              onPressed: () => showManageStoresSheet(context),
            ),
          ],
          // Lists management - only show on lists screen
          if (currentIndex == 1) ...[
            IconButton(
              icon: const Icon(Icons.archive_outlined),
              tooltip: 'Arkiv',
              onPressed: () => showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                useRootNavigator: true,
                builder: (context) => const ArchiveSheet(),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.reorder),
              tooltip: 'Administrer lister',
              onPressed: () => showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                useRootNavigator: true,
                builder: (context) => const ListManagementSheet(),
              ),
            ),
          ],
          // Garden-specific buttons
          if (currentIndex == 3) ...[
            IconButton(
              icon: const Icon(Icons.settings_outlined),
              onPressed: () => showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                builder: (context) => const GardenSettingsSheet(),
              ),
            ),
          ] else ...[
            IconButton(
              icon: const Icon(Icons.settings_outlined),
              onPressed: () => context.push(AppRoutes.homeSettings),
            ),
          ],
        ],
      ),
      body: child,
      floatingActionButton: _buildFab(context, ref, currentIndex),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomNavBar(
        currentIndex: currentIndex,
        onTap: (index) => _onItemTapped(context, index),
      ),
    );
  }

  Widget _buildFab(BuildContext context, WidgetRef ref, int currentIndex) {
    // Garden-specific FAB logic
    if (currentIndex == 3) {
      final gardenViewState = ref.watch(gardenViewProvider);
      final beds = ref.watch(gardenBedsProvider).valueOrNull ?? [];

      // Only show special icons in Visual tab
      if (gardenViewState.tabIndex == 1) {
        if (beds.isEmpty) {
          // Empty: show Add icon
          return AddFab(
            onPressed: () => _onAddPressed(context, ref),
            icon: Icons.add,
          );
        } else if (gardenViewState.isEditMode) {
          // Edit mode: show Check icon with green background
          return AddFab(
            onPressed: () => _onAddPressed(context, ref),
            icon: Icons.check,
            backgroundColor: Colors.green,
          );
        } else {
          // Normal mode: show Edit icon
          return AddFab(
            onPressed: () => _onAddPressed(context, ref),
            icon: Icons.edit,
          );
        }
      }
    }

    // Default: show Add icon
    return AddFab(
      onPressed: () => _onAddPressed(context, ref),
    );
  }
}
