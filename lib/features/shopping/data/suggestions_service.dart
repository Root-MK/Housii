import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'models/item_suggestion.dart';

/// Provider for the suggestions service
final suggestionsServiceProvider = Provider<SuggestionsService>((ref) {
  return SuggestionsService();
});

/// Service for managing item name suggestions
class SuggestionsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get reference to suggestions collection for a home
  CollectionReference<Map<String, dynamic>> _suggestionsCollection(
      String homeId) {
    return _firestore
        .collection('homes')
        .doc(homeId)
        .collection('item_suggestions');
  }

  /// Normalize a name for use as document ID
  String _normalizeForId(String name) {
    // Firestore doesn't allow / in doc IDs, so we sanitize
    return name.trim().toLowerCase().replaceAll('/', '_');
  }

  /// Record an item name being used (call when item is created)
  Future<void> recordItemUsage(String homeId, String itemName) async {
    debugPrint(
        '📝 recordItemUsage called - homeId: $homeId, itemName: $itemName');
    final normalizedId = _normalizeForId(itemName);
    debugPrint('📝 Normalized ID: $normalizedId');
    final docRef = _suggestionsCollection(homeId).doc(normalizedId);
    debugPrint('📝 Doc path: ${docRef.path}');

    try {
      final doc = await docRef.get();
      debugPrint('📝 Doc exists: ${doc.exists}');

      if (doc.exists) {
        // Increment existing suggestion
        await docRef.update({
          'useCount': FieldValue.increment(1),
          'lastUsedAt': Timestamp.now(),
        });
        debugPrint('✅ Incremented suggestion count for: $itemName');
      } else {
        // Create new suggestion
        final suggestion = ItemSuggestion.create(name: itemName);
        debugPrint('📝 Creating new suggestion: ${suggestion.toFirestore()}');
        await docRef.set(suggestion.toFirestore());
        debugPrint('✅ Created new suggestion for: $itemName');
      }
    } catch (e, stack) {
      debugPrint('❌ Error recording item usage: $e');
      debugPrint('❌ Stack: $stack');
    }
  }

  /// Get all suggestions with useCount >= 2 for a home
  Future<List<ItemSuggestion>> getSuggestions(String homeId) async {
    try {
      final snapshot = await _suggestionsCollection(homeId)
          .where('useCount', isGreaterThanOrEqualTo: 2)
          .orderBy('useCount', descending: true)
          .limit(100) // Limit for performance
          .get();

      return snapshot.docs
          .map((doc) => ItemSuggestion.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('❌ Error getting suggestions: $e');
      return [];
    }
  }

  /// Stream suggestions for real-time updates
  Stream<List<ItemSuggestion>> watchSuggestions(String homeId) {
    debugPrint('👀 watchSuggestions called for homeId: $homeId');
    return _suggestionsCollection(homeId)
        .where('useCount', isGreaterThanOrEqualTo: 2)
        .orderBy('useCount', descending: true)
        .limit(100)
        .snapshots()
        .map((snapshot) {
      debugPrint('👀 watchSuggestions got ${snapshot.docs.length} docs');
      final suggestions = snapshot.docs
          .map((doc) => ItemSuggestion.fromFirestore(doc))
          .toList();
      debugPrint('👀 Parsed ${suggestions.length} suggestions');
      for (final s in suggestions) {
        debugPrint('   - ${s.displayName} (count: ${s.useCount})');
      }
      return suggestions;
    }).handleError((e, stack) {
      debugPrint('❌ Error watching suggestions: $e');
      debugPrint('❌ Stack: $stack');
      return <ItemSuggestion>[];
    });
  }

  /// Get matching suggestions for a query
  Future<List<ItemSuggestion>> getMatchingSuggestions(
    String homeId,
    String query, {
    int limit = 3,
  }) async {
    if (query.trim().isEmpty) return [];

    final allSuggestions = await getSuggestions(homeId);

    // Filter and sort by match score
    final matches = allSuggestions.where((s) => s.matchesQuery(query)).toList()
      ..sort((a, b) => b.matchScore(query).compareTo(a.matchScore(query)));

    return matches.take(limit).toList();
  }
}
