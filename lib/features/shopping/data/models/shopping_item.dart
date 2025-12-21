import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

/// Shopping item model
class ShoppingItem {
  final String id;
  final String name;
  final bool active;
  final String homeId;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Optional fields
  final String? storeId; // Reference to store document ID (null = no store)
  final double? price;
  final int? amount;
  final bool important;
  final bool lookoutFor;
  final DateTime? discountStart;
  final DateTime? discountEnd;

  const ShoppingItem({
    required this.id,
    required this.name,
    required this.active,
    required this.homeId,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    this.storeId,
    this.price,
    this.amount,
    this.important = false,
    this.lookoutFor = false,
    this.discountStart,
    this.discountEnd,
  });

  /// Check if item has an active discount
  bool get hasActiveDiscount {
    if (discountStart == null || discountEnd == null) return false;
    final now = DateTime.now();
    return now.isAfter(discountStart!) && now.isBefore(discountEnd!);
  }

  /// Check if discount has expired
  bool get hasExpiredDiscount {
    if (discountEnd == null) return false;
    return DateTime.now().isAfter(discountEnd!);
  }

  /// Check if discount is upcoming (within 7 days)
  bool get hasUpcomingDiscount {
    if (discountStart == null) return false;
    final now = DateTime.now();
    final weekFromNow = now.add(const Duration(days: 7));
    return discountStart!.isAfter(now) && discountStart!.isBefore(weekFromNow);
  }

  /// Display amount (defaults to 1 if null)
  int get displayAmount => amount ?? 1;

  /// Create a new shopping item with generated ID
  factory ShoppingItem.create({
    required String name,
    required String homeId,
    required String createdBy,
    String? storeId,
    double? price,
    int? amount,
    bool important = false,
    bool lookoutFor = false,
    DateTime? discountStart,
    DateTime? discountEnd,
  }) {
    // Enforce business rule: lookoutFor and store are mutually exclusive
    final effectiveStoreId = lookoutFor ? null : storeId;
    final effectiveLookoutFor = storeId != null ? false : lookoutFor;

    return ShoppingItem(
      id: const Uuid().v4(),
      name: name,
      active: true,
      homeId: homeId,
      createdBy: createdBy,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      storeId: effectiveStoreId,
      price: price,
      amount: amount,
      important: important,
      lookoutFor: effectiveLookoutFor,
      discountStart: discountStart,
      discountEnd: discountEnd,
    );
  }

  /// Create from Firestore document
  factory ShoppingItem.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ShoppingItem(
      id: doc.id,
      name: data['name'] ?? '',
      active: data['active'] ?? true,
      homeId: data['homeId'] ?? '',
      createdBy: data['createdBy'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      storeId: data['storeId'] as String?, // Now a string ID
      price: (data['price'] as num?)?.toDouble(),
      amount: data['amount'] as int?,
      important: data['important'] ?? false,
      lookoutFor: data['lookoutFor'] ?? false,
      discountStart: (data['discountStart'] as Timestamp?)?.toDate(),
      discountEnd: (data['discountEnd'] as Timestamp?)?.toDate(),
    );
  }

  /// Convert to Firestore data
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'active': active,
      'homeId': homeId,
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'storeId': storeId,
      'price': price,
      'amount': amount,
      'important': important,
      'lookoutFor': lookoutFor,
      'discountStart': discountStart != null ? Timestamp.fromDate(discountStart!) : null,
      'discountEnd': discountEnd != null ? Timestamp.fromDate(discountEnd!) : null,
    };
  }

  /// Copy with modifications
  ShoppingItem copyWith({
    String? id,
    String? name,
    bool? active,
    String? homeId,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? storeId,
    bool clearStoreId = false,
    double? price,
    bool clearPrice = false,
    int? amount,
    bool clearAmount = false,
    bool? important,
    bool? lookoutFor,
    DateTime? discountStart,
    bool clearDiscountStart = false,
    DateTime? discountEnd,
    bool clearDiscountEnd = false,
  }) {
    // Enforce business rule: lookoutFor and store are mutually exclusive
    final newLookoutFor = lookoutFor ?? this.lookoutFor;
    final newStoreId = clearStoreId ? null : (storeId ?? this.storeId);
    
    final effectiveStoreId = newLookoutFor ? null : newStoreId;
    final effectiveLookoutFor = newStoreId != null ? false : newLookoutFor;

    return ShoppingItem(
      id: id ?? this.id,
      name: name ?? this.name,
      active: active ?? this.active,
      homeId: homeId ?? this.homeId,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      storeId: effectiveStoreId,
      price: clearPrice ? null : (price ?? this.price),
      amount: clearAmount ? null : (amount ?? this.amount),
      important: important ?? this.important,
      lookoutFor: effectiveLookoutFor,
      discountStart: clearDiscountStart ? null : (discountStart ?? this.discountStart),
      discountEnd: clearDiscountEnd ? null : (discountEnd ?? this.discountEnd),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ShoppingItem &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
