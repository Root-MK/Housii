import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

/// Importance level for list items
enum ItemImportance {
  low,
  normal,
  high,
  urgent,
}

/// List item model - represents an item within a list
class ListItemModel {
  final String id;
  final String listId;
  final String homeId;
  final String title;
  final String? details; // Rich text content (stored as JSON/HTML)
  final bool isChecked;
  final ItemImportance importance;
  final int sortOrder; // For manual ordering via drag-and-drop
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isArchived;
  final DateTime? archivedAt;
  final String? archivedBy;

  const ListItemModel({
    required this.id,
    required this.listId,
    required this.homeId,
    required this.title,
    this.details,
    this.isChecked = false,
    this.importance = ItemImportance.normal,
    required this.sortOrder,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    this.isArchived = false,
    this.archivedAt,
    this.archivedBy,
  });

  /// Create a new list item with generated ID
  factory ListItemModel.create({
    required String listId,
    required String homeId,
    required String title,
    String? details,
    ItemImportance importance = ItemImportance.normal,
    required int sortOrder,
    required String createdBy,
  }) {
    return ListItemModel(
      id: const Uuid().v4(),
      listId: listId,
      homeId: homeId,
      title: title,
      details: details,
      importance: importance,
      sortOrder: sortOrder,
      createdBy: createdBy,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  /// Create from Firestore document
  factory ListItemModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ListItemModel(
      id: doc.id,
      listId: data['listId'] ?? '',
      homeId: data['homeId'] ?? '',
      title: data['title'] ?? '',
      details: data['details'],
      isChecked: data['isChecked'] ?? false,
      importance: ItemImportance.values.firstWhere(
        (i) => i.name == data['importance'],
        orElse: () => ItemImportance.normal,
      ),
      sortOrder: data['sortOrder'] ?? 0,
      createdBy: data['createdBy'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isArchived: data['isArchived'] ?? false,
      archivedAt: (data['archivedAt'] as Timestamp?)?.toDate(),
      archivedBy: data['archivedBy'],
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'listId': listId,
      'homeId': homeId,
      'title': title,
      'details': details,
      'isChecked': isChecked,
      'importance': importance.name,
      'sortOrder': sortOrder,
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'isArchived': isArchived,
      'archivedAt': archivedAt != null ? Timestamp.fromDate(archivedAt!) : null,
      'archivedBy': archivedBy,
    };
  }

  /// Copy with modifications
  ListItemModel copyWith({
    String? id,
    String? listId,
    String? homeId,
    String? title,
    String? details,
    bool? isChecked,
    ItemImportance? importance,
    int? sortOrder,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isArchived,
    DateTime? archivedAt,
    String? archivedBy,
  }) {
    return ListItemModel(
      id: id ?? this.id,
      listId: listId ?? this.listId,
      homeId: homeId ?? this.homeId,
      title: title ?? this.title,
      details: details ?? this.details,
      isChecked: isChecked ?? this.isChecked,
      importance: importance ?? this.importance,
      sortOrder: sortOrder ?? this.sortOrder,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isArchived: isArchived ?? this.isArchived,
      archivedAt: archivedAt ?? this.archivedAt,
      archivedBy: archivedBy ?? this.archivedBy,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ListItemModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
