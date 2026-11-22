import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

/// Represents a watering event for a garden bed.
/// Tracks the amount of water added in mm.
class WateringLog {
  final String id;
  final String homeId;
  final String bedId;
  final DateTime date;
  final double amountMm; // Water added in mm
  final String? notes;
  final DateTime createdAt;

  const WateringLog({
    required this.id,
    required this.homeId,
    required this.bedId,
    required this.date,
    required this.amountMm,
    this.notes,
    required this.createdAt,
  });

  factory WateringLog.create({
    required String homeId,
    required String bedId,
    required double amountMm,
    DateTime? date,
    String? notes,
  }) {
    return WateringLog(
      id: const Uuid().v4(),
      homeId: homeId,
      bedId: bedId,
      date: date ?? DateTime.now(),
      amountMm: amountMm,
      notes: notes,
      createdAt: DateTime.now(),
    );
  }

  factory WateringLog.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return WateringLog(
      id: doc.id,
      homeId: data['homeId'] ?? '',
      bedId: data['bedId'] ?? '',
      date: (data['date'] as Timestamp).toDate(),
      amountMm: (data['amountMm'] as num).toDouble(),
      notes: data['notes'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'homeId': homeId,
      'bedId': bedId,
      'date': Timestamp.fromDate(date),
      'amountMm': amountMm,
      'notes': notes,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  /// Convert mm to liters based on bed area
  /// 1 mm on 1 m² = 1 liter
  double toLiters(double bedWidthCm, double bedHeightCm) {
    final areaM2 = (bedWidthCm / 100) * (bedHeightCm / 100);
    return amountMm * areaM2;
  }

  /// Create from liters based on bed area
  static double litersToMm(double liters, double bedWidthCm, double bedHeightCm) {
    final areaM2 = (bedWidthCm / 100) * (bedHeightCm / 100);
    if (areaM2 <= 0) return 0;
    return liters / areaM2;
  }

  WateringLog copyWith({
    DateTime? date,
    double? amountMm,
    String? notes,
  }) {
    return WateringLog(
      id: id,
      homeId: homeId,
      bedId: bedId,
      date: date ?? this.date,
      amountMm: amountMm ?? this.amountMm,
      notes: notes ?? this.notes,
      createdAt: createdAt,
    );
  }
}
