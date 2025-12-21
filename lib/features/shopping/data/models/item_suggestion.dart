import 'package:cloud_firestore/cloud_firestore.dart';

/// Model for tracking frequently used item names for suggestions
class ItemSuggestion {
  /// Normalized key (trimmed, lowercase)
  final String normalizedName;

  /// Original display name (first used version)
  final String displayName;

  /// How many times this item has been added
  final int useCount;

  /// Last time this item was added
  final DateTime lastUsedAt;

  const ItemSuggestion({
    required this.normalizedName,
    required this.displayName,
    required this.useCount,
    required this.lastUsedAt,
  });

  factory ItemSuggestion.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ItemSuggestion(
      normalizedName: doc.id,
      displayName: data['displayName'] ?? '',
      useCount: data['useCount'] ?? 0,
      lastUsedAt:
          (data['lastUsedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'displayName': displayName,
      'useCount': useCount,
      'lastUsedAt': Timestamp.fromDate(lastUsedAt),
    };
  }

  /// Create initial suggestion for a new item
  factory ItemSuggestion.create({
    required String name,
  }) {
    return ItemSuggestion(
      normalizedName: _normalize(name),
      displayName: name.trim(),
      useCount: 1,
      lastUsedAt: DateTime.now(),
    );
  }

  /// Increment use count
  ItemSuggestion increment() {
    return ItemSuggestion(
      normalizedName: normalizedName,
      displayName: displayName,
      useCount: useCount + 1,
      lastUsedAt: DateTime.now(),
    );
  }

  /// Normalize a name for comparison
  static String _normalize(String name) {
    return name.trim().toLowerCase();
  }

  /// Check if this suggestion matches a query using fuzzy search
  bool matchesQuery(String query) {
    if (query.isEmpty) return false;
    final normalizedQuery = _normalize(query);

    // Simple prefix matching for now
    if (normalizedName.startsWith(normalizedQuery)) return true;

    // Contains match
    if (normalizedName.contains(normalizedQuery)) return true;

    // Fuzzy match - allow one character difference for short queries
    if (normalizedQuery.length >= 2) {
      return _fuzzyMatch(normalizedName, normalizedQuery);
    }

    return false;
  }

  /// Simple fuzzy matching - allows some character differences
  static bool _fuzzyMatch(String text, String query) {
    // If query is very short, require prefix match
    if (query.length <= 2) {
      return text.startsWith(query);
    }

    // Allow match if most characters are in sequence
    int matchedChars = 0;
    int textIndex = 0;

    for (int i = 0; i < query.length && textIndex < text.length; i++) {
      // Find next occurrence of query char in remaining text
      final charIndex = text.indexOf(query[i], textIndex);
      if (charIndex != -1) {
        matchedChars++;
        textIndex = charIndex + 1;
      }
    }

    // Require at least 70% of query characters to match in sequence
    return matchedChars >= (query.length * 0.7);
  }

  /// Calculate match score for ranking (higher is better)
  int matchScore(String query) {
    final normalizedQuery = _normalize(query);

    // Exact prefix match gets highest score
    if (normalizedName.startsWith(normalizedQuery)) {
      return 1000 + useCount;
    }

    // Contains match
    if (normalizedName.contains(normalizedQuery)) {
      return 500 + useCount;
    }

    // Fuzzy match gets base score plus use count
    return useCount;
  }
}
