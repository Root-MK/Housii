import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

/// List type - determines behavior
enum ListType {
  /// Standard list without checkboxes
  defaultList,
  /// Checklist with checkable items
  checklist,
}

/// List visibility - who can see/access the list
enum ListVisibility {
  /// Only the creator can see and edit
  personal,
  /// All household members can see and edit
  household,
}

/// List model - represents a user-created list
class ListModel {
  final String id;
  final String name;
  final ListType type;
  final ListVisibility visibility;
  final String homeId;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isArchived;
  final int itemCount;
  final int completedCount;

  const ListModel({
    required this.id,
    required this.name,
    required this.type,
    required this.visibility,
    required this.homeId,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    this.isArchived = false,
    this.itemCount = 0,
    this.completedCount = 0,
  });

  /// Check if list is a checklist
  bool get isChecklist => type == ListType.checklist;

  /// Check if list is personal (only creator can see)
  bool get isPersonal => visibility == ListVisibility.personal;

  /// Check if list is shared with household
  bool get isHousehold => visibility == ListVisibility.household;

  /// Progress percentage for checklists (0.0 - 1.0)
  double get progress => itemCount > 0 ? completedCount / itemCount : 0.0;

  /// Create a new list with generated ID
  factory ListModel.create({
    required String name,
    required ListType type,
    required ListVisibility visibility,
    required String homeId,
    required String createdBy,
  }) {
    return ListModel(
      id: const Uuid().v4(),
      name: name,
      type: type,
      visibility: visibility,
      homeId: homeId,
      createdBy: createdBy,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  /// Create from Firestore document
  factory ListModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ListModel(
      id: doc.id,
      name: data['name'] ?? '',
      type: ListType.values.firstWhere(
        (t) => t.name == data['type'],
        orElse: () => ListType.defaultList,
      ),
      visibility: ListVisibility.values.firstWhere(
        (v) => v.name == data['visibility'],
        orElse: () => ListVisibility.household,
      ),
      homeId: data['homeId'] ?? '',
      createdBy: data['createdBy'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isArchived: data['isArchived'] ?? false,
      itemCount: data['itemCount'] ?? 0,
      completedCount: data['completedCount'] ?? 0,
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'type': type.name,
      'visibility': visibility.name,
      'homeId': homeId,
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'isArchived': isArchived,
      'itemCount': itemCount,
      'completedCount': completedCount,
    };
  }

  /// Copy with modifications
  ListModel copyWith({
    String? id,
    String? name,
    ListType? type,
    ListVisibility? visibility,
    String? homeId,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isArchived,
    int? itemCount,
    int? completedCount,
  }) {
    return ListModel(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      visibility: visibility ?? this.visibility,
      homeId: homeId ?? this.homeId,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isArchived: isArchived ?? this.isArchived,
      itemCount: itemCount ?? this.itemCount,
      completedCount: completedCount ?? this.completedCount,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ListModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
