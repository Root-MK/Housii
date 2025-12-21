import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/constants/strings_da.dart';
import '../../../../shared/providers/home_provider.dart';
import '../../data/models/shopping_item.dart';
import '../../data/models/store.dart';
import '../../data/shopping_service.dart';
import '../providers/shopping_providers.dart';
import '../widgets/shopping_item_card.dart';
import '../widgets/store_section_header.dart';
import '../widgets/edit_shopping_item_sheet.dart';
import '../widgets/shopping_settings_sheet.dart';

/// Main shopping list screen
class ShoppingScreen extends ConsumerStatefulWidget {
  const ShoppingScreen({super.key});

  @override
  ConsumerState<ShoppingScreen> createState() => _ShoppingScreenState();
}

class _ShoppingScreenState extends ConsumerState<ShoppingScreen> {
  // Track expanded sections
  final Map<String, bool> _expandedSections = {
    'noStore': true,
  };

  // Track dismissed items to prevent widget tree issues
  final Set<String> _dismissedItemIds = {};

  @override
  void initState() {
    super.initState();
  }

  void _initExpandedSections(List<Store> stores) {
    // Initialize store sections as expanded
    for (final store in stores) {
      if (!_expandedSections.containsKey(store.id)) {
        _expandedSections[store.id] = true;
      }
    }
  }

  void _toggleSection(String key) {
    setState(() {
      _expandedSections[key] = !(_expandedSections[key] ?? true);
    });
  }

  void _showEditItemSheet(BuildContext context, ShoppingItem item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useRootNavigator: true,
      builder: (context) => EditShoppingItemSheet(item: item),
    );
  }

  void _showSettingsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useRootNavigator: true,
      builder: (context) => const ShoppingSettingsSheet(),
    );
  }

  Future<void> _handleItemDroppedOnStore(ShoppingItem item, String? newStoreId) async {
    if (item.storeId == newStoreId) return; // No change
    
    final home = ref.read(currentHomeProvider).valueOrNull;
    if (home == null) return;
    
    try {
      await ref.read(shoppingServiceProvider).updateItemStore(
        home.id,
        item.id,
        newStoreId,
      );
      HapticFeedback.mediumImpact();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Kunne ikke flytte vare: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _handleCompleteItem(ShoppingItem item) async {
    // Check if already processing this item (prevents double triggers)
    if (_dismissedItemIds.contains(item.id)) return;

    // Add to dismissed set immediately to hide from UI
    setState(() {
      _dismissedItemIds.add(item.id);
    });

    final home = ref.read(currentHomeProvider).valueOrNull;
    if (home == null) return;

    // Check if this is the last item in a selected store filter
    // We need to do this BEFORE the Firebase update
    final selectedStoreIds = ref.read(selectedStoresProvider);
    final groupedItems = ref.read(groupedShoppingItemsProvider);
    bool shouldResetFilter = false;

    if (selectedStoreIds.isNotEmpty) {
      // Count remaining visible items in the selected store(s)
      int remainingItems = 0;
      for (final storeId in selectedStoreIds) {
        final storeItems = groupedItems.byStoreId[storeId] ?? [];
        // Count items that are not being dismissed
        remainingItems += storeItems
            .where((i) => i.id != item.id && !_dismissedItemIds.contains(i.id))
            .length;
      }
      // Also check no-store section if we're filtering and item has no store
      if (item.storeId == null) {
        remainingItems += groupedItems.noStore
            .where((i) => i.id != item.id && !_dismissedItemIds.contains(i.id))
            .length;
      }
      shouldResetFilter = remainingItems == 0;
    }

    // Perform Firebase update
    try {
      await ref.read(shoppingServiceProvider).markComplete(home.id, item.id);
    } catch (e) {
      // On error, restore the item visibility
      if (mounted) {
        setState(() {
          _dismissedItemIds.remove(item.id);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Kunne ikke fuldføre: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    // Reset store filter if this was the last item
    if (shouldResetFilter && mounted) {
      ref.read(selectedStoresProvider.notifier).state = {};
    }

    // Clean up dismissed set after a delay to allow Firebase stream to update
    // This prevents the item from flickering back if stream updates slowly
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _dismissedItemIds.remove(item.id);
        });
      }
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppStrings.itemCompleted),
          action: SnackBarAction(
            label: AppStrings.undo,
            onPressed: () async {
              // Re-add to dismissed temporarily while undoing
              if (mounted) {
                setState(() {
                  _dismissedItemIds.add(item.id);
                });
              }
              try {
                await ref
                    .read(shoppingServiceProvider)
                    .markActive(home.id, item.id);
              } finally {
                Future.delayed(const Duration(milliseconds: 500), () {
                  if (mounted) {
                    setState(() {
                      _dismissedItemIds.remove(item.id);
                    });
                  }
                });
              }
            },
          ),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
          ),
        ),
      );
    }
  }

  void _handleDeleteItem(ShoppingItem item) async {
    final home = ref.read(currentHomeProvider).valueOrNull;
    if (home == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppStrings.deleteItem),
        content: Text(AppStrings.deleteItemConfirm),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppStrings.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: Text(AppStrings.delete),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      HapticFeedback.mediumImpact();

      // Add to dismissed set immediately to hide from UI
      setState(() {
        _dismissedItemIds.add(item.id);
      });

      // Check if this is the last item in a selected store filter
      final selectedStoreIds = ref.read(selectedStoresProvider);
      final groupedItems = ref.read(groupedShoppingItemsProvider);
      bool shouldResetFilter = false;

      if (selectedStoreIds.isNotEmpty) {
        int remainingItems = 0;
        for (final storeId in selectedStoreIds) {
          final storeItems = groupedItems.byStoreId[storeId] ?? [];
          remainingItems += storeItems
              .where(
                  (i) => i.id != item.id && !_dismissedItemIds.contains(i.id))
              .length;
        }
        if (item.storeId == null) {
          remainingItems += groupedItems.noStore
              .where(
                  (i) => i.id != item.id && !_dismissedItemIds.contains(i.id))
              .length;
        }
        shouldResetFilter = remainingItems == 0;
      }

      try {
        await ref.read(shoppingServiceProvider).deleteItem(home.id, item.id);
      } catch (e) {
        // On error, restore the item visibility
        if (mounted) {
          setState(() {
            _dismissedItemIds.remove(item.id);
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Kunne ikke slette: $e'),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
      }

      // Reset store filter if this was the last item
      if (shouldResetFilter && mounted) {
        ref.read(selectedStoresProvider.notifier).state = {};
      }

      // Clean up dismissed set after delay
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          setState(() {
            _dismissedItemIds.remove(item.id);
          });
        }
      });
    }
  }

  void _toggleStoreFilter(String storeId) {
    final currentSelection = ref.read(selectedStoresProvider);

    // If this store is already the only one selected, go back to all
    if (currentSelection.length == 1 && currentSelection.contains(storeId)) {
      ref.read(selectedStoresProvider.notifier).state = {};
    } else {
      // Otherwise, select just this store (exclusive selection)
      ref.read(selectedStoresProvider.notifier).state = {storeId};
    }
    HapticFeedback.selectionClick();
  }

  void _clearAllFilters() {
    ref.read(selectedStoresProvider.notifier).state = {};
    HapticFeedback.selectionClick();
  }

  @override
  Widget build(BuildContext context) {
    final selectedStoreIds = ref.watch(selectedStoresProvider);
    final showCompleted = ref.watch(showCompletedProvider);
    final hideAnyStore = ref.watch(hideAnyStoreProvider);
    final showTotalPrice = ref.watch(showTotalPriceProvider);
    final showCompletedTotal = ref.watch(showCompletedTotalProvider);
    final groupedItems = ref.watch(groupedShoppingItemsProvider);

    // Initialize expanded sections for stores
    _initExpandedSections(groupedItems.stores);

    // Get store IDs that actually have items
    final storeIdsWithItems = groupedItems.orderedStoreIds;

    // Get stores ordered by active item count for the filter row
    final storesOrderedByCount = groupedItems.storesOrderedByActiveCount;

    return Scaffold(
      backgroundColor: AppColors.offWhite,
      body: Column(
        children: [
          // Filter section
          Container(
            color: AppColors.white,
            child: Column(
              children: [
                // Store filters row
                Padding(
                  padding: const EdgeInsets.only(
                    left: AppSpacing.md,
                    right: AppSpacing.md,
                    top: AppSpacing.sm,
                    bottom: AppSpacing.xs,
                  ),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        // Alle butikker - always shown, toggles all on
                        _buildStoreChip(
                          label: AppStrings.allStores,
                          isSelected: selectedStoreIds.isEmpty,
                          onTap: _clearAllFilters,
                          icon: Icons.store,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        // Store filters - ordered by active item count
                        ...storesOrderedByCount.map((store) {
                          final hasItems = storeIdsWithItems.contains(store.id);
                          final isSelected =
                              selectedStoreIds.contains(store.id);
                          final activeCount =
                              groupedItems.activeItemCount(store.id);
                          return Padding(
                            padding:
                                const EdgeInsets.only(right: AppSpacing.xs),
                            child: _buildStoreChip(
                              label: store.name,
                              emoji: store.emoji,
                              isSelected: isSelected,
                              hasNoItems: !hasItems,
                              itemCount: activeCount > 0 ? activeCount : null,
                              onTap: () => _toggleStoreFilter(store.id),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ),
                // Second row: Completed toggle, hide non-discount, hide any store, settings
                Padding(
                  padding: const EdgeInsets.only(
                    left: AppSpacing.md,
                    right: AppSpacing.md,
                    top: AppSpacing.xs,
                    bottom: AppSpacing.sm,
                  ),
                  child: Row(
                    children: [
                      _buildCompletedToggle(showCompleted),
                      const SizedBox(width: AppSpacing.sm),
                      _buildHideNonDiscountToggle(),
                      const SizedBox(width: AppSpacing.sm),
                      _buildHideAnyStoreToggle(hideAnyStore),
                      const Spacer(),
                      // Settings button
                      GestureDetector(
                        onTap: () => _showSettingsSheet(context),
                        child: Container(
                          padding: const EdgeInsets.all(AppSpacing.xs),
                          decoration: BoxDecoration(
                            color: AppColors.offWhite,
                            borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                          ),
                          child: Icon(
                            Icons.tune,
                            size: 20,
                            color: AppColors.gray,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // List content
          Expanded(
            child: groupedItems.isEmpty
                ? _buildEmptyState(showCompleted)
                : RefreshIndicator(
                    onRefresh: () async {
                      ref.invalidate(activeShoppingItemsProvider);
                      ref.invalidate(completedShoppingItemsProvider);
                    },
                    color: AppColors.primaryPurple,
                    child: ListView(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      children: [
                        // Store sections FIRST (ordered by sortOrder)
                        for (final storeId in groupedItems.orderedStoreIds)
                          if (_getVisibleItems(groupedItems.byStoreId[storeId]!)
                              .isNotEmpty)
                            _buildStoreSection(
                              storeId: storeId,
                              store: groupedItems.getStore(storeId),
                              items: groupedItems.byStoreId[storeId]!,
                              groupedItems: groupedItems,
                              showTotalPrice: showTotalPrice,
                              showCompletedTotal: showCompletedTotal && showCompleted,
                            ),

                        // No store section LAST (items without specific store)
                        if (!hideAnyStore && _getVisibleItems(groupedItems.noStore)
                            .isNotEmpty)
                          _buildNoStoreSection(
                            items: groupedItems.noStore,
                            groupedItems: groupedItems,
                            showTotalPrice: showTotalPrice,
                            showCompletedTotal: showCompletedTotal && showCompleted,
                          ),

                        // Bottom padding for FAB
                        const SizedBox(height: 80),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStoreSection({
    required String storeId,
    required Store? store,
    required List<ShoppingItem> items,
    required GroupedShoppingItems groupedItems,
    required bool showTotalPrice,
    required bool showCompletedTotal,
  }) {
    return _buildDropTarget(
      storeId: storeId,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StoreSectionHeader.storeById(
            store: store,
            storeId: storeId,
            itemCount: _getVisibleItems(items).length,
            isExpanded: _expandedSections[storeId] ?? true,
            onToggle: () => _toggleSection(storeId),
            totalPrice: groupedItems.totalPriceForStore(storeId),
            completedTotal: groupedItems.completedTotalForStore(storeId),
            showTotalPrice: showTotalPrice,
            showCompletedTotal: showCompletedTotal,
          ),
          if (_expandedSections[storeId] ?? true)
            ..._buildDraggableItemsList(items),
        ],
      ),
    );
  }

  Widget _buildNoStoreSection({
    required List<ShoppingItem> items,
    required GroupedShoppingItems groupedItems,
    required bool showTotalPrice,
    required bool showCompletedTotal,
  }) {
    return _buildDropTarget(
      storeId: null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StoreSectionHeader.noStore(
            itemCount: _getVisibleItems(items).length,
            isExpanded: _expandedSections['noStore'] ?? true,
            onToggle: () => _toggleSection('noStore'),
            totalPrice: groupedItems.totalPriceForStore(null),
            completedTotal: groupedItems.completedTotalForStore(null),
            showTotalPrice: showTotalPrice,
            showCompletedTotal: showCompletedTotal,
          ),
          if (_expandedSections['noStore'] ?? true)
            ..._buildDraggableItemsList(items),
        ],
      ),
    );
  }

  Widget _buildDropTarget({required String? storeId, required Widget child}) {
    return DragTarget<ShoppingItem>(
      onWillAcceptWithDetails: (details) {
        // Accept if item is from a different store
        return details.data.storeId != storeId;
      },
      onAcceptWithDetails: (details) {
        _handleItemDroppedOnStore(details.data, storeId);
      },
      builder: (context, candidateData, rejectedData) {
        final isHovering = candidateData.isNotEmpty;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
            border: isHovering
                ? Border.all(color: AppColors.primaryPurple, width: 2)
                : null,
          ),
          child: child,
        );
      },
    );
  }

  List<Widget> _buildDraggableItemsList(List<ShoppingItem> items) {
    // Filter out dismissed items
    final visibleItems = _getVisibleItems(items);

    return visibleItems.asMap().entries.map((entry) {
      final index = entry.key;
      final item = entry.value;

      return _DraggableShoppingItem(
        key: Key(item.id),
        item: item,
        onComplete: () => _handleCompleteItem(item),
        onEdit: () => _showEditItemSheet(context, item),
        onDelete: () => _handleDeleteItem(item),
        index: index,
      );
    }).toList();
  }

  List<ShoppingItem> _getVisibleItems(List<ShoppingItem> items) {
    return items.where((item) => !_dismissedItemIds.contains(item.id)).toList();
  }

  List<Widget> _buildItemsList(List<ShoppingItem> items) {
    // Filter out dismissed items
    final visibleItems = _getVisibleItems(items);

    return visibleItems.asMap().entries.map((entry) {
      final index = entry.key;
      final item = entry.value;

      return ShoppingItemCard(
        key: Key(item.id),
        item: item,
        onComplete: () => _handleCompleteItem(item),
        onEdit: () => _showEditItemSheet(context, item),
        onDelete: () => _handleDeleteItem(item),
      )
          .animate(delay: Duration(milliseconds: 50 * index))
          .fadeIn(duration: 200.ms)
          .slideX(begin: 0.1, end: 0, duration: 200.ms, curve: Curves.easeOut);
    }).toList();
  }

  Widget _buildCompletedToggle(bool showCompleted) {
    return GestureDetector(
      onTap: () {
        ref.read(showCompletedProvider.notifier).state = !showCompleted;
        HapticFeedback.selectionClick();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: showCompleted
              ? AppColors.success.withOpacity(0.1)
              : Colors.transparent,
          border: Border.all(
            color: showCompleted ? AppColors.success : AppColors.lightGray,
          ),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              showCompleted ? Icons.check : Icons.check_circle_outline,
              size: 18,
              color: showCompleted ? AppColors.success : AppColors.gray,
            ),
            const SizedBox(width: AppSpacing.xs),
            Text(
              AppStrings.completedItems,
              style: TextStyle(
                color: showCompleted ? AppColors.success : AppColors.gray,
                fontWeight: showCompleted ? FontWeight.w600 : FontWeight.w400,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHideNonDiscountToggle() {
    final hideNonDiscount = ref.watch(hideNonDiscountProvider);

    return GestureDetector(
      onTap: () {
        ref.read(hideNonDiscountProvider.notifier).state = !hideNonDiscount;
        HapticFeedback.selectionClick();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: hideNonDiscount
              ? AppColors.primaryPurple.withOpacity(0.1)
              : Colors.transparent,
          border: Border.all(
            color:
                hideNonDiscount ? AppColors.primaryPurple : AppColors.lightGray,
          ),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              hideNonDiscount
                  ? Icons.visibility_off
                  : Icons.visibility_off_outlined,
              size: 18,
              color: hideNonDiscount ? AppColors.primaryPurple : AppColors.gray,
            ),
            const SizedBox(width: AppSpacing.xs),
            Text(
              AppStrings.hideUpcomingDiscount,
              style: TextStyle(
                color:
                    hideNonDiscount ? AppColors.primaryPurple : AppColors.gray,
                fontWeight: hideNonDiscount ? FontWeight.w600 : FontWeight.w400,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHideAnyStoreToggle(bool hideAnyStore) {
    return GestureDetector(
      onTap: () {
        ref.read(hideAnyStoreProvider.notifier).state = !hideAnyStore;
        HapticFeedback.selectionClick();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: hideAnyStore
              ? AppColors.warning.withOpacity(0.1)
              : Colors.transparent,
          border: Border.all(
            color: hideAnyStore ? AppColors.warning : AppColors.lightGray,
          ),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              hideAnyStore ? Icons.store_mall_directory : Icons.store_mall_directory_outlined,
              size: 18,
              color: hideAnyStore ? AppColors.warning : AppColors.gray,
            ),
            const SizedBox(width: AppSpacing.xs),
            Text(
              AppStrings.hideAnyStore,
              style: TextStyle(
                color: hideAnyStore ? AppColors.warning : AppColors.gray,
                fontWeight: hideAnyStore ? FontWeight.w600 : FontWeight.w400,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStoreChip({
    required String label,
    required bool isSelected,
    VoidCallback? onTap,
    bool hasNoItems = false,
    IconData? icon,
    String? emoji,
    int? itemCount,
  }) {
    final Color bgColor;
    final Color borderColor;
    final Color textColor;

    if (isSelected) {
      bgColor = AppColors.primaryPurple.withOpacity(0.1);
      borderColor = AppColors.primaryPurple;
      textColor = AppColors.primaryPurple;
    } else if (hasNoItems) {
      bgColor = AppColors.offWhite;
      borderColor = Colors.transparent;
      textColor = AppColors.lightGray;
    } else {
      bgColor = AppColors.offWhite;
      borderColor = AppColors.lightGray;
      textColor = AppColors.darkGray;
    }

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: bgColor,
          border: Border.all(color: borderColor),
          borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
        ),
        child: AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 200),
          style: TextStyle(
            color: textColor,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            fontSize: 12,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (emoji != null) ...[
                Text(emoji,
                    style: TextStyle(
                        fontSize: 14,
                        color:
                            hasNoItems ? Colors.grey.withOpacity(0.5) : null)),
                const SizedBox(width: AppSpacing.xs),
              ] else if (icon != null) ...[
                Icon(icon, size: 14, color: textColor),
                const SizedBox(width: AppSpacing.xs),
              ],
              Text(label),
              if (itemCount != null && itemCount > 0) ...[
                const SizedBox(width: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primaryPurple.withOpacity(0.2)
                        : AppColors.gray.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$itemCount',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color:
                          isSelected ? AppColors.primaryPurple : AppColors.gray,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool showCompleted) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: showCompleted
                    ? AppColors.success.withOpacity(0.1)
                    : AppColors.primaryPurpleSubtle,
                borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
              ),
              child: Icon(
                showCompleted
                    ? Icons.check_circle_outline
                    : Icons.shopping_cart_outlined,
                size: 40,
                color:
                    showCompleted ? AppColors.success : AppColors.primaryPurple,
              ),
            ).animate().scale(duration: 400.ms, curve: Curves.elasticOut),
            const SizedBox(height: AppSpacing.lg),
            Text(
              showCompleted
                  ? AppStrings.noCompletedItems
                  : AppStrings.emptyShoppingList,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
              textAlign: TextAlign.center,
            ).animate().fadeIn(delay: 100.ms),
            const SizedBox(height: AppSpacing.sm),
            Text(
              showCompleted
                  ? AppStrings.noCompletedItemsHint
                  : AppStrings.addFirstItem,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.gray,
                  ),
              textAlign: TextAlign.center,
            ).animate().fadeIn(delay: 200.ms),
          ],
        ),
      ),
    );
  }
}

/// A shopping item that can be dragged via its handle
class _DraggableShoppingItem extends StatefulWidget {
  final ShoppingItem item;
  final VoidCallback onComplete;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final int index;

  const _DraggableShoppingItem({
    super.key,
    required this.item,
    required this.onComplete,
    required this.onEdit,
    required this.onDelete,
    required this.index,
  });

  @override
  State<_DraggableShoppingItem> createState() => _DraggableShoppingItemState();
}

class _DraggableShoppingItemState extends State<_DraggableShoppingItem> {
  @override
  Widget build(BuildContext context) {
    // Build a draggable wrapper around the handle icon
    // Use LongPressDraggable for better mobile/touch support (especially iOS Safari)
    final dragHandle = LongPressDraggable<ShoppingItem>(
      data: widget.item,
      delay: const Duration(milliseconds: 150), // Short delay for touch
      hapticFeedbackOnStart: true,
      onDragStarted: () {
        HapticFeedback.mediumImpact();
      },
      feedback: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
        child: Container(
          width: MediaQuery.of(context).size.width - 64,
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
            border: Border.all(color: AppColors.primaryPurple, width: 2),
          ),
          child: Row(
            children: [
              Icon(
                Icons.drag_indicator,
                color: AppColors.primaryPurple,
                size: 20,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  widget.item.name,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
      // Show a faded version when dragging
      childWhenDragging: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: AppColors.primaryPurpleSubtle,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Icon(
          Icons.drag_indicator,
          color: AppColors.primaryPurple.withOpacity(0.3),
          size: 20,
        ),
      ),
      // The visible handle - use purple background to make it very obvious
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: AppColors.primaryPurpleSubtle,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: AppColors.primaryPurple.withOpacity(0.3)),
        ),
        child: Icon(
          Icons.drag_indicator,
          color: AppColors.primaryPurple,
          size: 20,
        ),
      ),
    );

    return ShoppingItemCard(
      item: widget.item,
      onComplete: widget.onComplete,
      onEdit: widget.onEdit,
      onDelete: widget.onDelete,
      dragHandle: dragHandle,
    )
        .animate(delay: Duration(milliseconds: 50 * widget.index))
        .fadeIn(duration: 200.ms)
        .slideX(begin: 0.1, end: 0, duration: 200.ms, curve: Curves.easeOut);
  }
}
