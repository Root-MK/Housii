import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents daily weather data from Open-Meteo API.
/// Stored globally in Firestore as it's location-specific (Langaa, Randers).
class WeatherData {
  final String id; // Format: YYYY-MM-DD
  final DateTime date;
  final double tempAvg; // Average temperature in °C
  final double tempMin; // Minimum temperature in °C
  final double tempMax; // Maximum temperature in °C
  final double rainfall; // Precipitation in mm
  final double sunHours; // Sunshine duration in hours
  final double latitude;
  final double longitude;
  final DateTime fetchedAt;

  const WeatherData({
    required this.id,
    required this.date,
    required this.tempAvg,
    required this.tempMin,
    required this.tempMax,
    required this.rainfall,
    required this.sunHours,
    required this.latitude,
    required this.longitude,
    required this.fetchedAt,
  });

  /// Create ID from date (YYYY-MM-DD format)
  static String dateToId(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  factory WeatherData.fromOpenMeteo({
    required DateTime date,
    required double tempAvg,
    required double tempMin,
    required double tempMax,
    required double precipitation,
    required double sunshineDurationSeconds,
    required double latitude,
    required double longitude,
  }) {
    return WeatherData(
      id: dateToId(date),
      date: date,
      tempAvg: tempAvg,
      tempMin: tempMin,
      tempMax: tempMax,
      rainfall: precipitation,
      sunHours: sunshineDurationSeconds / 3600, // Convert seconds to hours
      latitude: latitude,
      longitude: longitude,
      fetchedAt: DateTime.now(),
    );
  }

  factory WeatherData.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return WeatherData(
      id: doc.id,
      date: (data['date'] as Timestamp).toDate(),
      tempAvg: (data['tempAvg'] as num).toDouble(),
      tempMin: (data['tempMin'] as num).toDouble(),
      tempMax: (data['tempMax'] as num).toDouble(),
      rainfall: (data['rainfall'] as num).toDouble(),
      sunHours: (data['sunHours'] as num).toDouble(),
      latitude: (data['latitude'] as num).toDouble(),
      longitude: (data['longitude'] as num).toDouble(),
      fetchedAt: (data['fetchedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'date': Timestamp.fromDate(date),
      'tempAvg': tempAvg,
      'tempMin': tempMin,
      'tempMax': tempMax,
      'rainfall': rainfall,
      'sunHours': sunHours,
      'latitude': latitude,
      'longitude': longitude,
      'fetchedAt': Timestamp.fromDate(fetchedAt),
    };
  }

  /// Calculate evapotranspiration using simplified formula
  /// ET (mm/day) = k × (Tavg + 10) × (sunHours / divisor)
  double calculateET({double k = 0.16, double divisor = 12}) {
    return k * (tempAvg + 10) * (sunHours / divisor);
  }

  /// Calculate net water loss (ET - rainfall)
  double calculateNetWaterLoss({double k = 0.16, double divisor = 12}) {
    final et = calculateET(k: k, divisor: divisor);
    return et - rainfall;
  }

  @override
  String toString() {
    return 'WeatherData(date: $id, tempAvg: $tempAvg°C, rain: ${rainfall}mm, sun: ${sunHours.toStringAsFixed(1)}h)';
  }
}
