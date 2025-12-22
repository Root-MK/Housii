import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/providers/home_provider.dart';
import '../../data/shopping_service.dart';
import '../../data/store_service.dart';
import '../../data/suggestions_service.dart';
import '../../data/models/shopping_item.dart';
import '../../data/models/store.dart';
import '../../data/models/item_suggestion.dart';

/// Selected stores filter - empty set means show all (store IDs)
final selectedStoresProvider = StateProvider<Set<String>>((ref) => {});

/// Whether to include items with no store in filter
final includeNoStoreProvider = StateProvider<bool>((ref) => true);

/// Whether to show completed items at bottom of lists
final showCompletedProvider = StateProvider<bool>((ref) => false);

/// Whether to hide items that are not on discount yet
final hideNonDiscountProvider = StateProvider<bool>((ref) => false);

/// Whether to show total price for each store section
final showTotalPriceProvider = StateProvider<bool>((ref) => false);

/// Whether to show completed items total price
final showCompletedTotalProvider = StateProvider<bool>((ref) => false);

/// Whether to hide "any store" items from the list
final hideAnyStoreProvider = StateProvider<bool>((ref) => false);

/// Last used store ID in session (not persisted)
final lastUsedStoreIdProvider = StateProvider<String?>((ref) => null);

/// Last used discount date range in session (not persisted)
/// Tuple of (start, end) dates
final lastUsedDiscountRangeProvider =
    StateProvider<({DateTime start, DateTime end})?>((ref) => null);

/// Stream of stores for current home
final storesProvider = StreamProvider<List<Store>>((ref) {
  debugPrint('🏪 storesProvider initialized');
  final homeAsync = ref.watch(currentHomeProvider);
  final storeService = ref.watch(storeServiceProvider);

  return homeAsync.when(
    data: (home) {
      if (home == null) {
        debugPrint('🏪 storesProvider: no home');
        return Stream.value([]);
      }
      debugPrint('🏪 storesProvider: watching home ${home.id}');
      // Ensure stores exist (initialize if first time)
      storeService.ensureStoresExist(home.id);
      return storeService.watchStores(home.id);
    },
    loading: () {
      debugPrint('🏪 storesProvider: home loading');
      return Stream.value([]);
    },
    error: (e, _) {
      debugPrint('🏪 storesProvider: home error $e');
      return Stream.value([]);
    },
  );
});

/// Get a store by ID from the cached stores list
final storeByIdProvider = Provider.family<Store?, String>((ref, storeId) {
  final stores = ref.watch(storesProvider).valueOrNull ?? [];
  try {
    return stores.firstWhere((s) => s.id == storeId);
  } catch (_) {
    return null;
  }
});

/// Stream of item suggestions for current home
final itemSuggestionsProvider = StreamProvider<List<ItemSuggestion>>((ref) {
  debugPrint('🔄 itemSuggestionsProvider initialized');
  final homeAsync = ref.watch(currentHomeProvider);
  final suggestionsService = ref.watch(suggestionsServiceProvider);

  return homeAsync.when(
    data: (home) {
      if (home == null) {
        debugPrint('🔄 itemSuggestionsProvider: no home');
        return Stream.value([]);
      }
      debugPrint('🔄 itemSuggestionsProvider: watching home ${home.id}');
      return suggestionsService.watchSuggestions(home.id);
    },
    loading: () {
      debugPrint('🔄 itemSuggestionsProvider: home loading');
      return Stream.value([]);
    },
    error: (e, _) {
      debugPrint('🔄 itemSuggestionsProvider: home error $e');
      return Stream.value([]);
    },
  );
});

/// Stream of active shopping items for current home
final activeShoppingItemsProvider = StreamProvider<List<ShoppingItem>>((ref) {
  final homeAsync = ref.watch(currentHomeProvider);
  final shoppingService = ref.watch(shoppingServiceProvider);

  return homeAsync.when(
    data: (home) {
      if (home == null) {
        debugPrint('📋 activeShoppingItemsProvider: no home');
        return Stream.value([]);
      }
      debugPrint('📋 activeShoppingItemsProvider: watching home ${home.id}');
      return shoppingService.watchActiveItems(home.id).handleError((error) {
        debugPrint('❌ activeShoppingItemsProvider error: $error');
      });
    },
    loading: () => Stream.value([]),
    error: (e, _) {
      debugPrint('❌ activeShoppingItemsProvider home error: $e');
      return Stream.value([]);
    },
  );
});

/// Stream of completed shopping items for current home
final completedShoppingItemsProvider =
    StreamProvider<List<ShoppingItem>>((ref) {
  final homeAsync = ref.watch(currentHomeProvider);
  final shoppingService = ref.watch(shoppingServiceProvider);

  return homeAsync.when(
    data: (home) {
      if (home == null) return Stream.value([]);
      return shoppingService.watchCompletedItems(home.id).handleError((error) {
        debugPrint('❌ completedShoppingItemsProvider error: $error');
      });
    },
    loading: () => Stream.value([]),
    error: (_, __) => Stream.value([]),
  );
});

/// Grouped and sorted shopping items
final groupedShoppingItemsProvider = Provider<GroupedShoppingItems>((ref) {
  final showCompleted = ref.watch(showCompletedProvider);
  final hideNonDiscount = ref.watch(hideNonDiscountProvider);
  final activeItemsAsync = ref.watch(activeShoppingItemsProvider);
  final completedItemsAsync = ref.watch(completedShoppingItemsProvider);
  final selectedStoreIds = ref.watch(selectedStoresProvider);
  final includeNoStore = ref.watch(includeNoStoreProvider);
  final stores = ref.watch(storesProvider).valueOrNull ?? [];

  final activeItems = activeItemsAsync.valueOrNull ?? [];
  final completedItems = showCompleted
      ? (completedItemsAsync.valueOrNull ?? [])
      : <ShoppingItem>[];

  return _groupAndSortItems(
    activeItems,
    completedItems,
    selectedStoreIds,
    includeNoStore,
    hideNonDiscount,
    stores,
  );
});

/// Group and sort items according to display rules
/// - Important items at top of each section
/// - Lookout items at bottom of active items
/// - Completed items at very bottom
GroupedShoppingItems _groupAndSortItems(
  List<ShoppingItem> activeItems,
  List<ShoppingItem> completedItems,
  Set<String> selectedStoreIds,
  bool includeNoStore,
  bool hideNonDiscount,
  List<Store> stores,
) {
  // Filter function
  bool passesFilter(ShoppingItem item) {
    // Hide non-discount filter: hide items where discount start date is in the future
    if (hideNonDiscount &&
        item.discountStart != null &&
        item.discountStart!.isAfter(DateTime.now())) {
      return false;
    }
    // Store filter
    if (selectedStoreIds.isEmpty && includeNoStore) return true;
    if (selectedStoreIds.isEmpty && !includeNoStore)
      return item.storeId != null;
    if (item.storeId != null && selectedStoreIds.contains(item.storeId))
      return true;
    if (item.storeId == null && includeNoStore) return true;
    return false;
  }

  final filteredActive = activeItems.where(passesFilter).toList();
  final filteredCompleted = completedItems.where(passesFilter).toList();

  // Group by store ID
  final byStoreId = <String, List<ShoppingItem>>{};
  final noStore = <ShoppingItem>[];

  for (final item in filteredActive) {
    if (item.storeId != null) {
      byStoreId.putIfAbsent(item.storeId!, () => []).add(item);
    } else {
      noStore.add(item);
    }
  }

  // Add completed items to their respective stores
  for (final item in filteredCompleted) {
    if (item.storeId != null) {
      byStoreId.putIfAbsent(item.storeId!, () => []).add(item);
    } else {
      noStore.add(item);
    }
  }

  // Sort each list: important first, then regular by date, then lookout, then completed last
  void sortItems(List<ShoppingItem> list) {
    list.sort((a, b) {
      // Completed items last
      if (!a.active && b.active) return 1;
      if (a.active && !b.active) return -1;
      // Important items first
      if (a.important && !b.important) return -1;
      if (!a.important && b.important) return 1;
      // Lookout items after regular
      if (a.lookoutFor && !b.lookoutFor) return 1;
      if (!a.lookoutFor && b.lookoutFor) return -1;
      // Sort by date descending
      return b.createdAt.compareTo(a.createdAt);
    });
  }

  for (final list in byStoreId.values) {
    sortItems(list);
  }
  sortItems(noStore);

  return GroupedShoppingItems(
    byStoreId: byStoreId,
    noStore: noStore,
    stores: stores,
  );
}

/// Grouped shopping items for display
class GroupedShoppingItems {
  final Map<String, List<ShoppingItem>> byStoreId;
  final List<ShoppingItem> noStore;
  final List<Store> stores;

  const GroupedShoppingItems({
    required this.byStoreId,
    required this.noStore,
    required this.stores,
  });

  factory GroupedShoppingItems.empty() {
    return const GroupedShoppingItems(
      byStoreId: {},
      noStore: [],
      stores: [],
    );
  }

  /// Total count of all items
  int get totalCount {
    return byStoreId.values.fold<int>(0, (sum, list) => sum + list.length) +
        noStore.length;
  }

  /// Check if empty
  bool get isEmpty => totalCount == 0;

  /// Get store by ID
  Store? getStore(String storeId) {
    try {
      return stores.firstWhere((s) => s.id == storeId);
    } catch (_) {
      return null;
    }
  }

  /// Get store IDs that have items (ordered by store sortOrder)
  List<String> get orderedStoreIds {
    final storeIdsWithItems = byStoreId.keys.toList();
    // Sort by the store's sortOrder
    storeIdsWithItems.sort((a, b) {
      final storeA = getStore(a);
      final storeB = getStore(b);
      return (storeA?.sortOrder ?? 999).compareTo(storeB?.sortOrder ?? 999);
    });
    return storeIdsWithItems;
  }

  /// Get active item count for a specific store
  int activeItemCount(String storeId) {
    final items = byStoreId[storeId];
    if (items == null) return 0;
    return items.where((item) => item.active).length;
  }

  /// Get stores ordered by active item count (descending), then by sortOrder
  /// Stores with items come first, then stores without items
  List<Store> get storesOrderedByActiveCount {
    final storeIdsWithItems = byStoreId.keys.toSet();
    final storesWithItemsList =
        stores.where((s) => storeIdsWithItems.contains(s.id)).toList();
    final storesWithoutItems =
        stores.where((s) => !storeIdsWithItems.contains(s.id)).toList();

    // Sort stores with items by active count (descending)
    storesWithItemsList.sort((a, b) {
      final countA = activeItemCount(a.id);
      final countB = activeItemCount(b.id);
      if (countA != countB) return countB.compareTo(countA);
      // If same count, sort by sortOrder
      return a.sortOrder.compareTo(b.sortOrder);
    });

    // Sort stores without items by sortOrder
    storesWithoutItems.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    return [...storesWithItemsList, ...storesWithoutItems];
  }

  /// Calculate total price for active items in a store
  double totalPriceForStore(String? storeId) {
    final items = storeId == null ? noStore : (byStoreId[storeId] ?? []);
    return items
        .where((item) => item.active)
        .fold(0.0, (sum, item) => sum + ((item.price ?? 0.0) * item.displayAmount));
  }

  /// Calculate total price for completed items in a store
  double completedTotalForStore(String? storeId) {
    final items = storeId == null ? noStore : (byStoreId[storeId] ?? []);
    return items
        .where((item) => !item.active)
        .fold(0.0, (sum, item) => sum + ((item.price ?? 0.0) * item.displayAmount));
  }

  /// Get completed item count for a specific store
  int completedItemCount(String? storeId) {
    final items = storeId == null ? noStore : (byStoreId[storeId] ?? []);
    return items.where((item) => !item.active).length;
  }
}
