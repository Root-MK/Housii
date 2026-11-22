import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

class GardenHarvest {
  final String id;
  final String homeId;
  final String? bedId;
  final String? cropId;
  final String cropName;
  final String? variety;
  final DateTime date;
  final double? weight; // in grams
  final String unit; // 'g', 'kg', 'stk'
  final int? count;
  final int quality; // 1-5
  final String? notes;

  const GardenHarvest({
    required this.id,
    required this.homeId,
    this.bedId,
    this.cropId,
    required this.cropName,
    this.variety,
    required this.date,
    this.weight,
    this.unit = 'g',
    this.count,
    this.quality = 3,
    this.notes,
  });

  factory GardenHarvest.create({
    required String homeId,
    String? bedId,
    String? cropId,
    required String cropName,
    String? variety,
    double? weight,
    String unit = 'g',
    int? count,
    int quality = 3,
    String? notes,
  }) {
    return GardenHarvest(
      id: const Uuid().v4(),
      homeId: homeId,
      bedId: bedId,
      cropId: cropId,
      cropName: cropName,
      variety: variety,
      date: DateTime.now(),
      weight: weight,
      unit: unit,
      count: count,
      quality: quality,
      notes: notes,
    );
  }

  factory GardenHarvest.fromFirestore(DocumentSnapshot doc) {
    final map = doc.data() as Map<String, dynamic>;
    return GardenHarvest(
      id: doc.id,
      homeId: map['homeId'] ?? '',
      bedId: map['bedId'],
      cropId: map['cropId'],
      cropName: map['cropName'] ?? '',
      variety: map['variety'],
      date: (map['date'] as Timestamp).toDate(),
      weight: (map['weight'] as num?)?.toDouble(),
      unit: map['unit'] ?? 'g',
      count: (map['count'] as num?)?.toInt(),
      quality: (map['quality'] as num?)?.toInt() ?? 3,
      notes: map['notes'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'homeId': homeId,
      'bedId': bedId,
      'cropId': cropId,
      'cropName': cropName,
      'variety': variety,
      'date': Timestamp.fromDate(date),
      'weight': weight,
      'unit': unit,
      'count': count,
      'quality': quality,
      'notes': notes,
    };
  }

  GardenHarvest copyWith({
    String? cropName,
    String? variety,
    DateTime? date,
    double? weight,
    String? unit,
    int? count,
    int? quality,
    String? notes,
  }) {
    return GardenHarvest(
      id: id,
      homeId: homeId,
      bedId: bedId,
      cropId: cropId,
      cropName: cropName ?? this.cropName,
      variety: variety ?? this.variety,
      date: date ?? this.date,
      weight: weight ?? this.weight,
      unit: unit ?? this.unit,
      count: count ?? this.count,
      quality: quality ?? this.quality,
      notes: notes ?? this.notes,
    );
  }
}
