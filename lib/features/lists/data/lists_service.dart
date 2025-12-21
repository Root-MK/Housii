import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'models/list_model.dart';
import 'models/list_item_model.dart';
import 'models/list_order_model.dart';

/// Lists Service Provider
final listsServiceProvider = Provider<ListsService>((ref) {
  return ListsService();
});

/// Service for managing lists and list items in Firestore
class ListsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get reference to lists collection for a home
  CollectionReference<Map<String, dynamic>> _listsCollection(String homeId) {
    return _firestore.collection('homes').doc(homeId).collection('lists');
  }

  /// Get reference to list items collection for a home
  CollectionReference<Map<String, dynamic>> _listItemsCollection(String homeId) {
    return _firestore.collection('homes').doc(homeId).collection('listItems');
  }

  /// Get reference to list order collection for a user
  CollectionReference<Map<String, dynamic>> _listOrderCollection(String userId) {
    return _firestore.collection('users').doc(userId).collection('listOrders');
  }

  // ============ LIST OPERATIONS ============

  /// Create a new list
  Future<void> createList(ListModel list) async {
    debugPrint('🔥 ListsService.createList');
    debugPrint('   Path: homes/${list.homeId}/lists/${list.id}');
    await _listsCollection(list.homeId).doc(list.id).set(list.toFirestore());
    debugPrint('✅ Firestore write completed');
  }

  /// Update a list
  Future<void> updateList(ListModel list) async {
    await _listsCollection(list.homeId).doc(list.id).update(
      list.copyWith(updatedAt: DateTime.now()).toFirestore(),
    );
  }

  /// Rename a list
  Future<void> renameList(String homeId, String listId, String newName) async {
    await _listsCollection(homeId).doc(listId).update({
      'name': newName,
      'updatedAt': Timestamp.now(),
    });
  }

  /// Archive a list
  Future<void> archiveList(String homeId, String listId) async {
    await _listsCollection(homeId).doc(listId).update({
      'isArchived': true,
      'updatedAt': Timestamp.now(),
    });
  }

  /// Unarchive a list
  Future<void> unarchiveList(String homeId, String listId) async {
    await _listsCollection(homeId).doc(listId).update({
      'isArchived': false,
      'updatedAt': Timestamp.now(),
    });
  }

  /// Delete a list and all its items
  Future<void> deleteList(String homeId, String listId) async {
    // First delete all items in the list
    final itemsSnapshot = await _listItemsCollection(homeId)
        .where('listId', isEqualTo: listId)
        .get();
    
    final batch = _firestore.batch();
    for (final doc in itemsSnapshot.docs) {
      batch.delete(doc.reference);
    }
    
    // Then delete the list itself
    batch.delete(_listsCollection(homeId).doc(listId));
    
    await batch.commit();
  }

  /// Watch all active lists for a home (visible to user)
  /// Returns lists that are either household lists or personal lists created by the user
  Stream<List<ListModel>> watchActiveLists(String homeId, String userId) {
    debugPrint('📡 watchActiveLists: homes/$homeId/lists');
    return _listsCollection(homeId)
        .where('isArchived', isEqualTo: false)
        .orderBy('createdAt', descending: false)
        .limit(100)
        .snapshots()
        .map((snapshot) {
          debugPrint('📡 Got ${snapshot.docs.length} list docs');
          final lists = snapshot.docs
              .map((doc) => ListModel.fromFirestore(doc))
              .where((list) => 
                  list.visibility == ListVisibility.household ||
                  list.createdBy == userId)
              .toList();
          debugPrint('📡 Returning ${lists.length} visible lists');
          return lists;
        });
  }

  /// Watch archived lists for a home
  Stream<List<ListModel>> watchArchivedLists(String homeId, String userId) {
    return _listsCollection(homeId)
        .where('isArchived', isEqualTo: true)
        .orderBy('updatedAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) {
          final lists = snapshot.docs
              .map((doc) => ListModel.fromFirestore(doc))
              .where((list) => 
                  list.visibility == ListVisibility.household ||
                  list.createdBy == userId)
              .toList();
          return lists;
        });
  }

  /// Watch household lists only
  Stream<List<ListModel>> watchHouseholdLists(String homeId) {
    return _listsCollection(homeId)
        .where('visibility', isEqualTo: ListVisibility.household.name)
        .where('isArchived', isEqualTo: false)
        .orderBy('createdAt', descending: false)
        .limit(100)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ListModel.fromFirestore(doc))
            .toList());
  }

  /// Watch personal lists only
  Stream<List<ListModel>> watchPersonalLists(String homeId, String userId) {
    return _listsCollection(homeId)
        .where('visibility', isEqualTo: ListVisibility.personal.name)
        .where('createdBy', isEqualTo: userId)
        .where('isArchived', isEqualTo: false)
        .orderBy('createdAt', descending: false)
        .limit(50)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ListModel.fromFirestore(doc))
            .toList());
  }

  // ============ LIST ITEM OPERATIONS ============

  /// Add a new item to a list
  Future<void> addItem(ListItemModel item) async {
    debugPrint('🔥 ListsService.addItem');
    debugPrint('   Path: homes/${item.homeId}/listItems/${item.id}');
    
    final batch = _firestore.batch();
    
    // Add the item
    batch.set(
      _listItemsCollection(item.homeId).doc(item.id),
      item.toFirestore(),
    );
    
    // Update list item count
    batch.update(
      _listsCollection(item.homeId).doc(item.listId),
      {
        'itemCount': FieldValue.increment(1),
        'updatedAt': Timestamp.now(),
      },
    );
    
    await batch.commit();
    debugPrint('✅ Firestore write completed');
  }

  /// Update an item
  Future<void> updateItem(ListItemModel item) async {
    await _listItemsCollection(item.homeId).doc(item.id).update(
      item.copyWith(updatedAt: DateTime.now()).toFirestore(),
    );
  }

  /// Toggle item checked state
  Future<void> toggleItemChecked(String homeId, String listId, String itemId, bool isChecked) async {
    final batch = _firestore.batch();
    
    // Update the item
    batch.update(
      _listItemsCollection(homeId).doc(itemId),
      {
        'isChecked': isChecked,
        'updatedAt': Timestamp.now(),
      },
    );
    
    // Update list completed count
    batch.update(
      _listsCollection(homeId).doc(listId),
      {
        'completedCount': FieldValue.increment(isChecked ? 1 : -1),
        'updatedAt': Timestamp.now(),
      },
    );
    
    await batch.commit();
  }

  /// Update item sort order (for drag and drop)
  Future<void> updateItemSortOrder(String homeId, String itemId, int newSortOrder) async {
    await _listItemsCollection(homeId).doc(itemId).update({
      'sortOrder': newSortOrder,
      'updatedAt': Timestamp.now(),
    });
  }

  /// Batch update sort orders for multiple items
  Future<void> batchUpdateSortOrders(String homeId, Map<String, int> itemSortOrders) async {
    final batch = _firestore.batch();
    
    for (final entry in itemSortOrders.entries) {
      batch.update(
        _listItemsCollection(homeId).doc(entry.key),
        {
          'sortOrder': entry.value,
          'updatedAt': Timestamp.now(),
        },
      );
    }
    
    await batch.commit();
  }

  /// Archive an item
  Future<void> archiveItem(String homeId, String listId, String itemId, String userId, bool wasChecked) async {
    final batch = _firestore.batch();
    
    // Update the item
    batch.update(
      _listItemsCollection(homeId).doc(itemId),
      {
        'isArchived': true,
        'archivedAt': Timestamp.now(),
        'archivedBy': userId,
        'updatedAt': Timestamp.now(),
      },
    );
    
    // Update list counts
    final decrements = <String, dynamic>{
      'itemCount': FieldValue.increment(-1),
      'updatedAt': Timestamp.now(),
    };
    if (wasChecked) {
      decrements['completedCount'] = FieldValue.increment(-1);
    }
    batch.update(_listsCollection(homeId).doc(listId), decrements);
    
    await batch.commit();
  }

  /// Unarchive an item
  Future<void> unarchiveItem(String homeId, String listId, String itemId, bool wasChecked) async {
    final batch = _firestore.batch();
    
    // Update the item
    batch.update(
      _listItemsCollection(homeId).doc(itemId),
      {
        'isArchived': false,
        'archivedAt': null,
        'archivedBy': null,
        'updatedAt': Timestamp.now(),
      },
    );
    
    // Update list counts
    final increments = <String, dynamic>{
      'itemCount': FieldValue.increment(1),
      'updatedAt': Timestamp.now(),
    };
    if (wasChecked) {
      increments['completedCount'] = FieldValue.increment(1);
    }
    batch.update(_listsCollection(homeId).doc(listId), increments);
    
    await batch.commit();
  }

  /// Delete an item
  Future<void> deleteItem(String homeId, String listId, String itemId, bool wasChecked) async {
    final batch = _firestore.batch();
    
    // Delete the item
    batch.delete(_listItemsCollection(homeId).doc(itemId));
    
    // Update list counts
    final decrements = <String, dynamic>{
      'itemCount': FieldValue.increment(-1),
      'updatedAt': Timestamp.now(),
    };
    if (wasChecked) {
      decrements['completedCount'] = FieldValue.increment(-1);
    }
    batch.update(_listsCollection(homeId).doc(listId), decrements);
    
    await batch.commit();
  }

  /// Watch active items for a specific list
  Stream<List<ListItemModel>> watchListItems(String homeId, String listId) {
    debugPrint('📡 watchListItems: homes/$homeId/listItems for list $listId');
    return _listItemsCollection(homeId)
        .where('listId', isEqualTo: listId)
        .where('isArchived', isEqualTo: false)
        .orderBy('sortOrder', descending: false)
        .limit(500)
        .snapshots()
        .map((snapshot) {
          debugPrint('📡 Got ${snapshot.docs.length} item docs');
          return snapshot.docs
              .map((doc) => ListItemModel.fromFirestore(doc))
              .toList();
        });
  }

  /// Watch archived items for a specific list
  Stream<List<ListItemModel>> watchArchivedItems(String homeId, String listId) {
    return _listItemsCollection(homeId)
        .where('listId', isEqualTo: listId)
        .where('isArchived', isEqualTo: true)
        .orderBy('archivedAt', descending: true)
        .limit(100)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ListItemModel.fromFirestore(doc))
            .toList());
  }

  /// Watch all archived items for a home (for archive view)
  Stream<List<ListItemModel>> watchAllArchivedItems(String homeId) {
    return _listItemsCollection(homeId)
        .where('isArchived', isEqualTo: true)
        .orderBy('archivedAt', descending: true)
        .limit(200)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ListItemModel.fromFirestore(doc))
            .toList());
  }

  /// Move item to top of list
  Future<void> moveItemToTop(String homeId, String itemId) async {
    await _listItemsCollection(homeId).doc(itemId).update({
      'sortOrder': -DateTime.now().millisecondsSinceEpoch,
      'updatedAt': Timestamp.now(),
    });
  }

  /// Move item to bottom of list (but above checked items)
  Future<void> moveItemToBottom(String homeId, String listId, String itemId) async {
    // Get max sort order of unchecked items
    final snapshot = await _listItemsCollection(homeId)
        .where('listId', isEqualTo: listId)
        .where('isArchived', isEqualTo: false)
        .where('isChecked', isEqualTo: false)
        .orderBy('sortOrder', descending: true)
        .limit(1)
        .get();
    
    int newSortOrder = DateTime.now().millisecondsSinceEpoch;
    if (snapshot.docs.isNotEmpty) {
      final maxOrder = snapshot.docs.first.data()['sortOrder'] as int? ?? 0;
      newSortOrder = maxOrder + 1000;
    }
    
    await _listItemsCollection(homeId).doc(itemId).update({
      'sortOrder': newSortOrder,
      'updatedAt': Timestamp.now(),
    });
  }

  // ============ LIST ORDER OPERATIONS ============

  /// Get user's list order preferences
  Future<ListOrderModel?> getListOrder(String userId, String homeId) async {
    final snapshot = await _listOrderCollection(userId)
        .where('homeId', isEqualTo: homeId)
        .limit(1)
        .get();
    
    if (snapshot.docs.isEmpty) return null;
    return ListOrderModel.fromFirestore(snapshot.docs.first);
  }

  /// Watch user's list order preferences
  Stream<ListOrderModel?> watchListOrder(String userId, String homeId) {
    return _listOrderCollection(userId)
        .where('homeId', isEqualTo: homeId)
        .limit(1)
        .snapshots()
        .map((snapshot) {
          if (snapshot.docs.isEmpty) return null;
          return ListOrderModel.fromFirestore(snapshot.docs.first);
        });
  }

  /// Save user's list order preferences
  Future<void> saveListOrder(String userId, String homeId, List<String> listOrder) async {
    final existing = await getListOrder(userId, homeId);
    
    if (existing != null) {
      await _listOrderCollection(userId).doc(existing.id).update({
        'listOrder': listOrder,
        'updatedAt': Timestamp.now(),
      });
    } else {
      final newOrder = ListOrderModel(
        id: '${homeId}_order',
        userId: userId,
        homeId: homeId,
        listOrder: listOrder,
        updatedAt: DateTime.now(),
      );
      await _listOrderCollection(userId).doc(newOrder.id).set(newOrder.toFirestore());
    }
  }

  /// Get next sort order value for a new item in a list
  Future<int> getNextSortOrder(String homeId, String listId) async {
    final snapshot = await _listItemsCollection(homeId)
        .where('listId', isEqualTo: listId)
        .where('isArchived', isEqualTo: false)
        .where('isChecked', isEqualTo: false)
        .orderBy('sortOrder', descending: true)
        .limit(1)
        .get();
    
    if (snapshot.docs.isEmpty) {
      return 1000; // Start with 1000 to allow items to be moved above
    }
    
    final maxOrder = snapshot.docs.first.data()['sortOrder'] as int? ?? 0;
    return maxOrder + 1000;
  }
}
