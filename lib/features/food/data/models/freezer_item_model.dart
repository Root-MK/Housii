import 'package:cloud_firestore/cloud_firestore.dart';
import 'food_emoji.dart';

/// Model for an item in the freezer
class FreezerItemModel {
  final String id;
  final String homeId;
  final String name;
  final double quantity;
  final QuantityUnit unit;
  final FoodEmoji emoji;
  final DateTime addedAt;
  final String addedBy;
  final DateTime updatedAt;

  const FreezerItemModel({
    required this.id,
    required this.homeId,
    required this.name,
    required this.quantity,
    required this.unit,
    required this.emoji,
    required this.addedAt,
    required this.addedBy,
    required this.updatedAt,
  });

  /// Create from Firestore document
  factory FreezerItemModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FreezerItemModel(
      id: doc.id,
      homeId: data['homeId'] as String,
      name: data['name'] as String,
      quantity: (data['quantity'] as num).toDouble(),
      unit: QuantityUnit.fromName(data['unit'] as String? ?? 'stk'),
      emoji: FoodEmoji.fromName(data['emoji'] as String? ?? 'plate'),
      addedAt: (data['addedAt'] as Timestamp).toDate(),
      addedBy: data['addedBy'] as String,
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'homeId': homeId,
      'name': name,
      'quantity': quantity,
      'unit': unit.name,
      'emoji': emoji.name,
      'addedAt': Timestamp.fromDate(addedAt),
      'addedBy': addedBy,
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  FreezerItemModel copyWith({
    String? id,
    String? homeId,
    String? name,
    double? quantity,
    QuantityUnit? unit,
    FoodEmoji? emoji,
    DateTime? addedAt,
    String? addedBy,
    DateTime? updatedAt,
  }) {
    return FreezerItemModel(
      id: id ?? this.id,
      homeId: homeId ?? this.homeId,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      emoji: emoji ?? this.emoji,
      addedAt: addedAt ?? this.addedAt,
      addedBy: addedBy ?? this.addedBy,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Check if item is empty (quantity is 0)
  bool get isEmpty => quantity <= 0;

  /// Get formatted quantity string (e.g., "2 kg", "5 stk")
  String get formattedQuantity => '${quantity.toStringAsFixed(quantity.truncateToDouble() == quantity ? 0 : 1)} ${unit.abbreviation}';
}
