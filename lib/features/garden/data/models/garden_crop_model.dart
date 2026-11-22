import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

class GardenCrop {
  final String id;
  final String name;
  final String? variety;
  final int quantity;
  final DateTime? plantDate;
  final DateTime? lastFertilized;
  final DateTime? lastWatered;
  final String? notes;

  const GardenCrop({
    required this.id,
    required this.name,
    this.variety,
    this.quantity = 1,
    this.plantDate,
    this.lastFertilized,
    this.lastWatered,
    this.notes,
  });

  factory GardenCrop.create({
    required String name,
    String? variety,
    int quantity = 1,
    DateTime? plantDate,
    String? notes,
  }) {
    return GardenCrop(
      id: const Uuid().v4(),
      name: name,
      variety: variety,
      quantity: quantity,
      plantDate: plantDate,
      notes: notes,
    );
  }

  factory GardenCrop.fromMap(Map<String, dynamic> map) {
    return GardenCrop(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      variety: map['variety'],
      quantity: (map['quantity'] as num?)?.toInt() ?? 1,
      plantDate: (map['plantDate'] as Timestamp?)?.toDate(),
      lastFertilized: (map['lastFertilized'] as Timestamp?)?.toDate(),
      lastWatered: (map['lastWatered'] as Timestamp?)?.toDate(),
      notes: map['notes'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'variety': variety,
      'quantity': quantity,
      'plantDate': plantDate != null ? Timestamp.fromDate(plantDate!) : null,
      'lastFertilized': lastFertilized != null ? Timestamp.fromDate(lastFertilized!) : null,
      'lastWatered': lastWatered != null ? Timestamp.fromDate(lastWatered!) : null,
      'notes': notes,
    };
  }

  GardenCrop copyWith({
    String? name,
    String? variety,
    int? quantity,
    DateTime? plantDate,
    bool clearPlantDate = false,
    DateTime? lastFertilized,
    bool clearLastFertilized = false,
    DateTime? lastWatered,
    bool clearLastWatered = false,
    String? notes,
    bool clearNotes = false,
  }) {
    return GardenCrop(
      id: id,
      name: name ?? this.name,
      variety: variety ?? this.variety,
      quantity: quantity ?? this.quantity,
      plantDate: clearPlantDate ? null : (plantDate ?? this.plantDate),
      lastFertilized: clearLastFertilized ? null : (lastFertilized ?? this.lastFertilized),
      lastWatered: clearLastWatered ? null : (lastWatered ?? this.lastWatered),
      notes: clearNotes ? null : (notes ?? this.notes),
    );
  }
}
