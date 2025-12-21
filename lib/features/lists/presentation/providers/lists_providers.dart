import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/providers/home_provider.dart';
import '../../../../shared/providers/auth_provider.dart';
import '../../data/lists_service.dart';
import '../../data/models/list_model.dart';
import '../../data/models/list_item_model.dart';
import '../../data/models/list_order_model.dart';

/// Filter type for list visibility
enum ListFilter {
  all,       // Show all lists
  personal,  // Show only personal lists
  household, // Show only household lists
}

/// Current list filter selection
final listFilterProvider = StateProvider<ListFilter>((ref) => ListFilter.all);

/// Currently selected list ID
final selectedListIdProvider = StateProvider<String?>((ref) => null);

/// Stream of all active lists for current home
final activeListsProvider = StreamProvider<List<ListModel>>((ref) {
  debugPrint('📋 activeListsProvider initialized');
  final homeAsync = ref.watch(currentHomeProvider);
  final userAsync = ref.watch(currentUserProvider);
  final listsService = ref.watch(listsServiceProvider);

  return homeAsync.when(
    data: (home) {
      if (home == null) {
        debugPrint('📋 activeListsProvider: no home');
        return Stream.value([]);
      }
      return userAsync.when(
        data: (user) {
          if (user == null) {
            debugPrint('📋 activeListsProvider: no user');
            return Stream.value([]);
          }
          debugPrint('📋 activeListsProvider: watching home ${home.id}');
          return listsService.watchActiveLists(home.id, user.id);
        },
        loading: () => Stream.value([]),
        error: (_, __) => Stream.value([]),
      );
    },
    loading: () => Stream.value([]),
    error: (e, _) {
      debugPrint('❌ activeListsProvider home error: $e');
      return Stream.value([]);
    },
  );
});

/// Stream of archived lists for current home
final archivedListsProvider = StreamProvider<List<ListModel>>((ref) {
  final homeAsync = ref.watch(currentHomeProvider);
  final userAsync = ref.watch(currentUserProvider);
  final listsService = ref.watch(listsServiceProvider);

  return homeAsync.when(
    data: (home) {
      if (home == null) return Stream.value([]);
      return userAsync.when(
        data: (user) {
          if (user == null) return Stream.value([]);
          return listsService.watchArchivedLists(home.id, user.id);
        },
        loading: () => Stream.value([]),
        error: (_, __) => Stream.value([]),
      );
    },
    loading: () => Stream.value([]),
    error: (_, __) => Stream.value([]),
  );
});

/// Stream of user's list order preferences
final listOrderProvider = StreamProvider<ListOrderModel?>((ref) {
  final homeAsync = ref.watch(currentHomeProvider);
  final userAsync = ref.watch(currentUserProvider);
  final listsService = ref.watch(listsServiceProvider);

  return homeAsync.when(
    data: (home) {
      if (home == null) return Stream.value(null);
      return userAsync.when(
        data: (user) {
          if (user == null) return Stream.value(null);
          return listsService.watchListOrder(user.id, home.id);
        },
        loading: () => Stream.value(null),
        error: (_, __) => Stream.value(null),
      );
    },
    loading: () => Stream.value(null),
    error: (_, __) => Stream.value(null),
  );
});

/// Filtered lists based on current filter selection
final filteredListsProvider = Provider<List<ListModel>>((ref) {
  final listsAsync = ref.watch(activeListsProvider);
  final filter = ref.watch(listFilterProvider);
  final userAsync = ref.watch(currentUserProvider);
  
  final lists = listsAsync.valueOrNull ?? [];
  final user = userAsync.valueOrNull;
  
  if (user == null) return lists;
  
  switch (filter) {
    case ListFilter.all:
      return lists;
    case ListFilter.personal:
      return lists.where((l) => l.isPersonal && l.createdBy == user.id).toList();
    case ListFilter.household:
      return lists.where((l) => l.isHousehold).toList();
  }
});

/// Ordered lists based on user's preferences
final orderedListsProvider = Provider<List<ListModel>>((ref) {
  final filteredLists = ref.watch(filteredListsProvider);
  final orderAsync = ref.watch(listOrderProvider);
  
  final order = orderAsync.valueOrNull;
  
  if (order == null || order.listOrder.isEmpty) {
    // No custom order, return as-is (sorted by creation date)
    return filteredLists;
  }
  
  // Sort by user's custom order
  final orderMap = <String, int>{};
  for (var i = 0; i < order.listOrder.length; i++) {
    orderMap[order.listOrder[i]] = i;
  }
  
  final sortedLists = List<ListModel>.from(filteredLists);
  sortedLists.sort((a, b) {
    final aIndex = orderMap[a.id] ?? 99999;
    final bIndex = orderMap[b.id] ?? 99999;
    if (aIndex == bIndex) {
      // Both not in order, sort by creation date
      return a.createdAt.compareTo(b.createdAt);
    }
    return aIndex.compareTo(bIndex);
  });
  
  return sortedLists;
});

/// Currently selected list
final selectedListProvider = Provider<ListModel?>((ref) {
  final selectedId = ref.watch(selectedListIdProvider);
  final lists = ref.watch(orderedListsProvider);
  
  if (selectedId == null && lists.isNotEmpty) {
    // Auto-select first list if none selected
    return lists.first;
  }
  
  if (selectedId == null) return null;
  
  try {
    return lists.firstWhere((l) => l.id == selectedId);
  } catch (_) {
    // Selected list not found, return first or null
    return lists.isNotEmpty ? lists.first : null;
  }
});

/// Stream of items for the currently selected list
final currentListItemsProvider = StreamProvider<List<ListItemModel>>((ref) {
  final selectedList = ref.watch(selectedListProvider);
  final homeAsync = ref.watch(currentHomeProvider);
  final listsService = ref.watch(listsServiceProvider);
  
  if (selectedList == null) return Stream.value([]);
  
  return homeAsync.when(
    data: (home) {
      if (home == null) return Stream.value([]);
      return listsService.watchListItems(home.id, selectedList.id);
    },
    loading: () => Stream.value([]),
    error: (_, __) => Stream.value([]),
  );
});

/// Sorted items for the current list (unchecked first, then checked)
final sortedListItemsProvider = Provider<SortedListItems>((ref) {
  final itemsAsync = ref.watch(currentListItemsProvider);
  final selectedList = ref.watch(selectedListProvider);
  
  final items = itemsAsync.valueOrNull ?? [];
  
  if (selectedList == null || !selectedList.isChecklist) {
    // Not a checklist, just sort by order
    final sorted = List<ListItemModel>.from(items)
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return SortedListItems(unchecked: sorted, checked: []);
  }
  
  // Checklist: separate unchecked and checked
  final unchecked = items.where((i) => !i.isChecked).toList()
    ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  final checked = items.where((i) => i.isChecked).toList()
    ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  
  return SortedListItems(unchecked: unchecked, checked: checked);
});

/// Stream of all archived items for current home
final allArchivedItemsProvider = StreamProvider<List<ListItemModel>>((ref) {
  final homeAsync = ref.watch(currentHomeProvider);
  final listsService = ref.watch(listsServiceProvider);
  
  return homeAsync.when(
    data: (home) {
      if (home == null) return Stream.value([]);
      return listsService.watchAllArchivedItems(home.id);
    },
    loading: () => Stream.value([]),
    error: (_, __) => Stream.value([]),
  );
});

/// Archive search query
final archiveSearchQueryProvider = StateProvider<String>((ref) => '');

/// Filtered archived items based on search
final filteredArchivedItemsProvider = Provider<List<ListItemModel>>((ref) {
  final itemsAsync = ref.watch(allArchivedItemsProvider);
  final searchQuery = ref.watch(archiveSearchQueryProvider).toLowerCase();
  
  final items = itemsAsync.valueOrNull ?? [];
  
  if (searchQuery.isEmpty) return items;
  
  return items.where((item) {
    return item.title.toLowerCase().contains(searchQuery) ||
           (item.details?.toLowerCase().contains(searchQuery) ?? false);
  }).toList();
});

/// Helper class for sorted list items
class SortedListItems {
  final List<ListItemModel> unchecked;
  final List<ListItemModel> checked;
  
  const SortedListItems({
    required this.unchecked,
    required this.checked,
  });
  
  List<ListItemModel> get all => [...unchecked, ...checked];
  int get totalCount => unchecked.length + checked.length;
  bool get isEmpty => unchecked.isEmpty && checked.isEmpty;
}

/// Get a list by ID
final listByIdProvider = Provider.family<ListModel?, String>((ref, listId) {
  final lists = ref.watch(activeListsProvider).valueOrNull ?? [];
  try {
    return lists.firstWhere((l) => l.id == listId);
  } catch (_) {
    return null;
  }
});
