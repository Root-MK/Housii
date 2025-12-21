import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'models/store.dart';

/// Provider for the store service
final storeServiceProvider = Provider<StoreService>((ref) {
  return StoreService();
});

/// Service for managing stores in Firestore
class StoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get reference to stores collection for a home
  CollectionReference<Map<String, dynamic>> _storesCollection(String homeId) {
    return _firestore.collection('homes').doc(homeId).collection('stores');
  }

  /// Initialize default stores for a new home
  Future<void> initializeDefaultStores(String homeId) async {
    debugPrint('🏪 Initializing default stores for home: $homeId');
    
    final batch = _firestore.batch();
    
    for (final store in DefaultStores.defaultStores) {
      final docRef = _storesCollection(homeId).doc(store.id);
      batch.set(docRef, store.toFirestore());
    }
    
    await batch.commit();
    debugPrint('✅ Default stores initialized');
  }

  /// Check if stores exist for a home, initialize if not
  Future<void> ensureStoresExist(String homeId) async {
    final snapshot = await _storesCollection(homeId).limit(1).get();
    
    if (snapshot.docs.isEmpty) {
      await initializeDefaultStores(homeId);
    }
  }

  /// Add a new store
  Future<Store> addStore(String homeId, {
    required String name,
    required String colorHex,
    required String emoji,
  }) async {
    debugPrint('🏪 Adding store: $name');
    
    // Get current max sort order
    final snapshot = await _storesCollection(homeId)
        .orderBy('sortOrder', descending: true)
        .limit(1)
        .get();
    
    int nextSortOrder = 0;
    if (snapshot.docs.isNotEmpty) {
      final maxOrder = snapshot.docs.first.data()['sortOrder'] as int? ?? 0;
      // Insert before "Valgfri butik" (sortOrder 999)
      nextSortOrder = maxOrder < 999 ? maxOrder + 1 : maxOrder;
    }
    
    final store = Store.create(
      name: name,
      colorHex: colorHex,
      emoji: emoji,
      sortOrder: nextSortOrder,
      isDefault: false,
    );
    
    await _storesCollection(homeId).doc(store.id).set(store.toFirestore());
    debugPrint('✅ Store added: ${store.id}');
    
    return store;
  }

  /// Update an existing store
  Future<void> updateStore(String homeId, Store store) async {
    await _storesCollection(homeId).doc(store.id).update(store.toFirestore());
    debugPrint('✅ Store updated: ${store.name}');
  }

  /// Delete a store (only non-default stores can be deleted)
  Future<bool> deleteStore(String homeId, String storeId) async {
    // Check if it's a default store
    final doc = await _storesCollection(homeId).doc(storeId).get();
    if (!doc.exists) return false;
    
    final store = Store.fromFirestore(doc);
    if (store.isDefault) {
      debugPrint('⚠️ Cannot delete default store: ${store.name}');
      return false;
    }
    
    await _storesCollection(homeId).doc(storeId).delete();
    debugPrint('✅ Store deleted: ${store.name}');
    return true;
  }

  /// Watch all stores for a home (ordered by sortOrder)
  Stream<List<Store>> watchStores(String homeId) {
    return _storesCollection(homeId)
        .orderBy('sortOrder')
        .snapshots()
        .map((snapshot) {
          final stores = snapshot.docs
              .map((doc) => Store.fromFirestore(doc))
              .toList();
          debugPrint('👀 Watching stores: ${stores.length} stores');
          return stores;
        })
        .handleError((e) {
          debugPrint('❌ Error watching stores: $e');
          return <Store>[];
        });
  }

  /// Get all stores for a home (one-time fetch)
  Future<List<Store>> getStores(String homeId) async {
    final snapshot = await _storesCollection(homeId)
        .orderBy('sortOrder')
        .get();
    
    return snapshot.docs.map((doc) => Store.fromFirestore(doc)).toList();
  }

  /// Get a single store by ID
  Future<Store?> getStore(String homeId, String storeId) async {
    final doc = await _storesCollection(homeId).doc(storeId).get();
    if (!doc.exists) return null;
    return Store.fromFirestore(doc);
  }

  /// Update sort order for multiple stores (batch update)
  Future<void> updateStoreOrder(String homeId, List<Store> stores) async {
    final batch = _firestore.batch();
    
    for (int i = 0; i < stores.length; i++) {
      final store = stores[i];
      batch.update(_storesCollection(homeId).doc(store.id), {
        'sortOrder': i,
      });
    }
    
    await batch.commit();
    debugPrint('✅ Store order updated');
  }
}
