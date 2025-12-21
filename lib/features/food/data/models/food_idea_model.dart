import 'package:cloud_firestore/cloud_firestore.dart';
import 'food_emoji.dart';

/// Model for a food idea that can be planned
class FoodIdeaModel {
  final String id;
  final String homeId;
  final String name;
  final String? description;
  final FoodEmoji emoji;
  final DateTime createdAt;
  final String createdBy;
  /// Last time this food was planned/eaten - used for sorting (most recent eaten at bottom)
  final DateTime? lastPlannedAt;
  /// Position for ordering - lower values appear first
  final int position;

  const FoodIdeaModel({
    required this.id,
    required this.homeId,
    required this.name,
    this.description,
    required this.emoji,
    required this.createdAt,
    required this.createdBy,
    this.lastPlannedAt,
    this.position = 0,
  });

  /// Create from Firestore document
  factory FoodIdeaModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FoodIdeaModel(
      id: doc.id,
      homeId: data['homeId'] as String,
      name: data['name'] as String,
      description: data['description'] as String?,
      emoji: FoodEmoji.fromName(data['emoji'] as String? ?? 'plate'),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      createdBy: data['createdBy'] as String,
      lastPlannedAt: data['lastPlannedAt'] != null 
          ? (data['lastPlannedAt'] as Timestamp).toDate() 
          : null,
      position: data['position'] as int? ?? 0,
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'homeId': homeId,
      'name': name,
      'description': description,
      'emoji': emoji.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'createdBy': createdBy,
      'lastPlannedAt': lastPlannedAt != null ? Timestamp.fromDate(lastPlannedAt!) : null,
      'position': position,
    };
  }

  FoodIdeaModel copyWith({
    String? id,
    String? homeId,
    String? name,
    String? description,
    FoodEmoji? emoji,
    DateTime? createdAt,
    String? createdBy,
    DateTime? lastPlannedAt,
    int? position,
  }) {
    return FoodIdeaModel(
      id: id ?? this.id,
      homeId: homeId ?? this.homeId,
      name: name ?? this.name,
      description: description ?? this.description,
      emoji: emoji ?? this.emoji,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
      lastPlannedAt: lastPlannedAt ?? this.lastPlannedAt,
      position: position ?? this.position,
    );
  }

  /// Check if this food has been planned recently (has lastPlannedAt)
  bool get hasBeenPlanned => lastPlannedAt != null;
}
