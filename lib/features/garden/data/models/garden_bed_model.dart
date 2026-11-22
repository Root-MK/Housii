import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import 'garden_crop_model.dart';

class GardenBed {
  final String id;
  final String name;
  final double x; // x position in cm (or grid units)
  final double y; // y position in cm
  final double width; // width in cm
  final double height; // height in cm
  final int? color; // Color value (int)
  final String? icon; // Icon for the bed (emoji or identifier)
  final String homeId;
  final DateTime createdAt;
  final List<GardenCrop> crops;

  const GardenBed({
    required this.id,
    required this.name,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    this.color,
    this.icon,
    required this.homeId,
    required this.createdAt,
    required this.crops,
  });

  factory GardenBed.create({
    required String name,
    required String homeId,
    double x = 0,
    double y = 0,
    double width = 100, // Default 100cm
    double height = 100, // Default 100cm
    int? color,
    String? icon,
  }) {
    return GardenBed(
      id: const Uuid().v4(),
      name: name,
      x: x,
      y: y,
      width: width,
      height: height,
      color: color,
      icon: icon,
      homeId: homeId,
      createdAt: DateTime.now(),
      crops: [],
    );
  }

  factory GardenBed.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return GardenBed(
      id: doc.id,
      name: data['name'] ?? 'Unnamed Bed',
      x: (data['x'] as num?)?.toDouble() ?? 0.0,
      y: (data['y'] as num?)?.toDouble() ?? 0.0,
      width: (data['width'] as num?)?.toDouble() ?? 100.0,
      height: (data['height'] as num?)?.toDouble() ?? 100.0,
      color: data['color'] as int?,
      icon: data['icon'] as String?,
      homeId: data['homeId'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      crops: (data['crops'] as List<dynamic>?)
              ?.map((c) => GardenCrop.fromMap(c as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'x': x,
      'y': y,
      'width': width,
      'height': height,
      'color': color,
      'icon': icon,
      'homeId': homeId,
      'createdAt': Timestamp.fromDate(createdAt),
      'crops': crops.map((c) => c.toMap()).toList(),
    };
  }

  GardenBed copyWith({
    String? name,
    double? x,
    double? y,
    double? width,
    double? height,
    int? color,
    String? icon,
    List<GardenCrop>? crops,
  }) {
    return GardenBed(
      id: id,
      name: name ?? this.name,
      x: x ?? this.x,
      y: y ?? this.y,
      width: width ?? this.width,
      height: height ?? this.height,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      homeId: homeId,
      createdAt: createdAt,
      crops: crops ?? this.crops,
    );
  }
}
