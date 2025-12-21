import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

/// Store model for shopping - stored per household in Firestore
class Store {
  final String id;
  final String name;
  final String colorHex; // Hex color string like '#FF5733'
  final String? emoji; // Optional emoji for the store
  final int sortOrder; // For custom ordering
  final bool isDefault; // Default stores cannot be deleted (only "Valgfri butik")
  final DateTime createdAt;

  const Store({
    required this.id,
    required this.name,
    required this.colorHex,
    this.emoji,
    required this.sortOrder,
    required this.isDefault,
    required this.createdAt,
  });

  /// Get Color from hex string
  Color get color {
    final hex = colorHex.replaceFirst('#', '');
    return Color(int.parse('FF$hex', radix: 16));
  }

  /// Create a new store with generated ID
  factory Store.create({
    required String name,
    required String colorHex,
    String? emoji,
    required int sortOrder,
    bool isDefault = false,
  }) {
    return Store(
      id: const Uuid().v4(),
      name: name,
      colorHex: colorHex,
      emoji: emoji,
      sortOrder: sortOrder,
      isDefault: isDefault,
      createdAt: DateTime.now(),
    );
  }

  /// Create from Firestore document
  factory Store.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Store(
      id: doc.id,
      name: data['name'] ?? '',
      colorHex: data['colorHex'] ?? '#808080',
      emoji: data['emoji'] ?? '🏪',
      sortOrder: data['sortOrder'] ?? 0,
      isDefault: data['isDefault'] ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Convert to Firestore data
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'colorHex': colorHex,
      'emoji': emoji,
      'sortOrder': sortOrder,
      'isDefault': isDefault,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  /// Copy with modifications
  Store copyWith({
    String? id,
    String? name,
    String? colorHex,
    String? emoji,
    int? sortOrder,
    bool? isDefault,
    DateTime? createdAt,
  }) {
    return Store(
      id: id ?? this.id,
      name: name ?? this.name,
      colorHex: colorHex ?? this.colorHex,
      emoji: emoji ?? this.emoji,
      sortOrder: sortOrder ?? this.sortOrder,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Store && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// Default stores for Danish households
class DefaultStores {
  static const String otherStoreId = 'other'; // Fixed ID for "Other" store

  static List<Store> get defaultStores => [
        Store(
          id: 'rema1000',
          name: 'Rema 1000',
          colorHex: '#1E3A8A', // Dark blue
          emoji: '🔵',
          sortOrder: 0,
          isDefault: false,
          createdAt: DateTime.now(),
        ),
        Store(
          id: 'superbrugsen',
          name: 'Superbrugsen',
          colorHex: '#16A34A', // Green
          emoji: '🟢',
          sortOrder: 1,
          isDefault: false,
          createdAt: DateTime.now(),
        ),
        Store(
          id: 'abc_lavpris',
          name: 'ABC Lavpris',
          colorHex: '#DC2626', // Red
          emoji: '🔴',
          sortOrder: 2,
          isDefault: false,
          createdAt: DateTime.now(),
        ),
        Store(
          id: 'bilka',
          name: 'Bilka',
          colorHex: '#EAB308', // Yellow
          emoji: '🟡',
          sortOrder: 3,
          isDefault: false,
          createdAt: DateTime.now(),
        ),
        Store(
          id: '365',
          name: '365',
          colorHex: '#F97316', // Orange
          emoji: '🟠',
          sortOrder: 4,
          isDefault: false,
          createdAt: DateTime.now(),
        ),
        Store(
          id: 'netto',
          name: 'Netto',
          colorHex: '#FBBF24', // Amber
          emoji: '💛',
          sortOrder: 5,
          isDefault: false,
          createdAt: DateTime.now(),
        ),
        Store(
          id: otherStoreId,
          name: 'Valgfri butik',
          colorHex: '#6B7280', // Gray
          emoji: '🏪',
          sortOrder: 999, // Always last
          isDefault: true, // Cannot be deleted
          createdAt: DateTime.now(),
        ),
      ];
}
