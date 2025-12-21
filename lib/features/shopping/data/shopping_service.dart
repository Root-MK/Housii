import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'models/shopping_item.dart';

/// Shopping Service Provider
final shoppingServiceProvider = Provider<ShoppingService>((ref) {
  return ShoppingService();
});

/// Service for managing shopping items in Firestore
class ShoppingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get reference to shopping collection for a home
  CollectionReference<Map<String, dynamic>> _shoppingCollection(String homeId) {
    return _firestore.collection('homes').doc(homeId).collection('shopping');
  }

  /// Add a new shopping item
  Future<void> addItem(ShoppingItem item) async {
    debugPrint('🔥 ShoppingService.addItem');
    debugPrint('   Path: homes/${item.homeId}/shopping/${item.id}');
    debugPrint('   Data: ${item.toFirestore()}');
    await _shoppingCollection(item.homeId).doc(item.id).set(item.toFirestore());
    debugPrint('✅ Firestore write completed');
  }

  /// Update an existing shopping item
  Future<void> updateItem(ShoppingItem item) async {
    await _shoppingCollection(item.homeId).doc(item.id).update(
      item.copyWith(updatedAt: DateTime.now()).toFirestore(),
    );
  }

  /// Delete a shopping item
  Future<void> deleteItem(String homeId, String itemId) async {
    await _shoppingCollection(homeId).doc(itemId).delete();
  }

  /// Mark item as complete (set active = false)
  Future<void> markComplete(String homeId, String itemId) async {
    await _shoppingCollection(homeId).doc(itemId).update({
      'active': false,
      'updatedAt': Timestamp.now(),
    });
  }

  /// Mark item as active again (undo complete)
  Future<void> markActive(String homeId, String itemId) async {
    await _shoppingCollection(homeId).doc(itemId).update({
      'active': true,
      'updatedAt': Timestamp.now(),
    });
  }

  /// Watch all active shopping items for a home
  /// Limited to 500 items for cost control
  Stream<List<ShoppingItem>> watchActiveItems(String homeId) {
    debugPrint('📡 watchActiveItems: homes/$homeId/shopping');
    // Query active items with limit for cost control
    return _shoppingCollection(homeId)
        .where('active', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .limit(500)
        .snapshots()
        .map((snapshot) {
          debugPrint('📡 Got ${snapshot.docs.length} active docs');
          final items = snapshot.docs
              .map((doc) => ShoppingItem.fromFirestore(doc))
              .toList();
          debugPrint('📡 Returning ${items.length} active items');
          return items;
        });
  }

  /// Watch completed shopping items for a home (for history)
  /// Limited to 50 most recent completed items for cost control
  Stream<List<ShoppingItem>> watchCompletedItems(String homeId) {
    // Query completed items with limit for cost control
    return _shoppingCollection(homeId)
        .where('active', isEqualTo: false)
        .orderBy('updatedAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) {
          final items = snapshot.docs
              .map((doc) => ShoppingItem.fromFirestore(doc))
              .toList();
          return items;
        });
  }

  /// Get a single shopping item
  Future<ShoppingItem?> getItem(String homeId, String itemId) async {
    final doc = await _shoppingCollection(homeId).doc(itemId).get();
    if (!doc.exists) return null;
    return ShoppingItem.fromFirestore(doc);
  }

  /// Mark multiple items as complete
  Future<void> markMultipleComplete(String homeId, List<String> itemIds) async {
    final batch = _firestore.batch();
    for (final itemId in itemIds) {
      batch.update(_shoppingCollection(homeId).doc(itemId), {
        'active': false,
        'updatedAt': Timestamp.now(),
      });
    }
    await batch.commit();
  }

  /// Delete all completed items (clear history)
  /// Handles large batches by chunking (Firestore limit is 500 per batch)
  Future<void> clearCompletedItems(String homeId) async {
    final snapshot = await _shoppingCollection(homeId)
        .where('active', isEqualTo: false)
        .limit(500) // Process in chunks of 500
        .get();
    
    if (snapshot.docs.isEmpty) return;
    
    final batch = _firestore.batch();
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
    
    // If there were 500 docs, there might be more - recursively delete
    if (snapshot.docs.length == 500) {
      await clearCompletedItems(homeId);
    }
  }

  /// Update an item's store (for drag and drop between lists)
  Future<void> updateItemStore(String homeId, String itemId, String? newStoreId) async {
    await _shoppingCollection(homeId).doc(itemId).update({
      'storeId': newStoreId,
      'updatedAt': Timestamp.now(),
    });
    debugPrint('✅ Item store updated to: $newStoreId');
  }
}
