import 'package:cloud_firestore/cloud_firestore.dart';

/// User's personal list ordering preferences
/// Stored per user to allow personal ordering of household lists
class ListOrderModel {
  final String id;
  final String userId;
  final String homeId;
  final List<String> listOrder; // List IDs in preferred order
  final DateTime updatedAt;

  const ListOrderModel({
    required this.id,
    required this.userId,
    required this.homeId,
    required this.listOrder,
    required this.updatedAt,
  });

  /// Create from Firestore document
  factory ListOrderModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ListOrderModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      homeId: data['homeId'] ?? '',
      listOrder: List<String>.from(data['listOrder'] ?? []),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'homeId': homeId,
      'listOrder': listOrder,
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  /// Copy with modifications
  ListOrderModel copyWith({
    String? id,
    String? userId,
    String? homeId,
    List<String>? listOrder,
    DateTime? updatedAt,
  }) {
    return ListOrderModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      homeId: homeId ?? this.homeId,
      listOrder: listOrder ?? this.listOrder,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
