import 'package:cloud_firestore/cloud_firestore.dart';
import 'food_emoji.dart';

/// Model for a planned meal on a specific date
class MealPlanModel {
  final String id;
  final String homeId;
  final DateTime date;
  final String foodIdeaId;
  final String foodName;
  final String? description;
  final FoodEmoji emoji;
  final DateTime createdAt;
  final String createdBy;

  const MealPlanModel({
    required this.id,
    required this.homeId,
    required this.date,
    required this.foodIdeaId,
    required this.foodName,
    this.description,
    required this.emoji,
    required this.createdAt,
    required this.createdBy,
  });

  /// Create from Firestore document
  factory MealPlanModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MealPlanModel(
      id: doc.id,
      homeId: data['homeId'] as String,
      date: (data['date'] as Timestamp).toDate(),
      foodIdeaId: data['foodIdeaId'] as String,
      foodName: data['foodName'] as String,
      description: data['description'] as String?,
      emoji: FoodEmoji.fromName(data['emoji'] as String? ?? 'plate'),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      createdBy: data['createdBy'] as String,
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'homeId': homeId,
      'date': Timestamp.fromDate(DateTime(date.year, date.month, date.day)),
      'foodIdeaId': foodIdeaId,
      'foodName': foodName,
      'description': description,
      'emoji': emoji.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'createdBy': createdBy,
    };
  }

  MealPlanModel copyWith({
    String? id,
    String? homeId,
    DateTime? date,
    String? foodIdeaId,
    String? foodName,
    String? description,
    FoodEmoji? emoji,
    DateTime? createdAt,
    String? createdBy,
  }) {
    return MealPlanModel(
      id: id ?? this.id,
      homeId: homeId ?? this.homeId,
      date: date ?? this.date,
      foodIdeaId: foodIdeaId ?? this.foodIdeaId,
      foodName: foodName ?? this.foodName,
      description: description ?? this.description,
      emoji: emoji ?? this.emoji,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
    );
  }

  /// Get date only (no time component)
  DateTime get dateOnly => DateTime(date.year, date.month, date.day);
}
