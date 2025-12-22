import 'package:cloud_firestore/cloud_firestore.dart';

/// Home model for Firestore
class HomeModel {
  final String id;
  final String name;
  final String joinCode;
  final String ownerId;
  final List<String> memberIds;
  final Map<String, dynamic> gardenSettings;
  final DateTime createdAt;
  final DateTime updatedAt;

  const HomeModel({
    required this.id,
    required this.name,
    required this.joinCode,
    required this.ownerId,
    required this.memberIds,
    this.gardenSettings = const {},
    required this.createdAt,
    required this.updatedAt,
  });

  factory HomeModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return HomeModel(
      id: doc.id,
      name: data['name'] ?? '',
      joinCode: data['joinCode'] ?? '',
      ownerId: data['ownerId'] ?? '',
      memberIds: List<String>.from(data['memberIds'] ?? []),
      gardenSettings: Map<String, dynamic>.from(data['gardenSettings'] ?? {}),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'joinCode': joinCode,
      'ownerId': ownerId,
      'memberIds': memberIds,
      'gardenSettings': gardenSettings,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  bool isOwner(String userId) => ownerId == userId;
  
  bool isMember(String userId) => memberIds.contains(userId);

  /// Formatted join code with dashes: XXXX-XXXX-XXXX-XXXX
  String get formattedJoinCode {
    if (joinCode.length != 16) return joinCode;
    return '${joinCode.substring(0, 4)}-${joinCode.substring(4, 8)}-${joinCode.substring(8, 12)}-${joinCode.substring(12, 16)}';
  }

  HomeModel copyWith({
    String? id,
    String? name,
    String? joinCode,
    String? ownerId,
    List<String>? memberIds,
    Map<String, dynamic>? gardenSettings,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return HomeModel(
      id: id ?? this.id,
      name: name ?? this.name,
      joinCode: joinCode ?? this.joinCode,
      ownerId: ownerId ?? this.ownerId,
      memberIds: memberIds ?? this.memberIds,
      gardenSettings: gardenSettings ?? this.gardenSettings,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
