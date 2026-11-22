/// Configuration for water index calculations.
/// Allows adjustment of the evapotranspiration formula and soil thresholds.
class WaterIndexConfig {
  /// Coefficient k in ET formula: ET = k × (Tavg + 10) × (sunHours / divisor)
  final double etCoefficient;

  /// Divisor in ET formula (typically 12 for sun hours)
  final double etDivisor;

  /// Soil type affects water holding capacity
  final SoilType soilType;

  /// Water deficit threshold before recommending watering (mm)
  double get wateringThreshold => soilType.wateringThreshold;

  /// Maximum deficit (soil capacity). Beyond this, soil is "empty" and deficit stops increasing.
  /// Assumes threshold is roughly 40-50% depletion, so max is ~2.5x threshold.
  double get maxDeficit => soilType.wateringThreshold * 2.5;

  /// Dev mode: track all year. Production: April 1 - September 30 only
  final bool devMode;

  /// Season start date (April 1)
  static DateTime seasonStart(int year) => DateTime(year, 4, 1);

  /// Season end date (September 30)
  static DateTime seasonEnd(int year) => DateTime(year, 9, 30);

  const WaterIndexConfig({
    this.etCoefficient = 0.16,
    this.etDivisor = 12.0,
    this.soilType = SoilType.loam,
    this.devMode = true, // Default to dev mode for development
  });

  /// Check if tracking is active for given date
  bool isSeasonActive(DateTime date) {
    if (devMode) return true;

    final year = date.year;
    final start = seasonStart(year);
    final end = seasonEnd(year);

    return date.isAfter(start.subtract(const Duration(days: 1))) &&
        date.isBefore(end.add(const Duration(days: 1)));
  }

  /// Get season start for tracking (returns April 1 of current year, or Jan 1 in dev mode)
  DateTime getTrackingStart(DateTime currentDate) {
    if (devMode) {
      // In dev mode, start from January 1 of current year
      return DateTime(currentDate.year, 1, 1);
    }
    return seasonStart(currentDate.year);
  }

  WaterIndexConfig copyWith({
    double? etCoefficient,
    double? etDivisor,
    SoilType? soilType,
    bool? devMode,
  }) {
    return WaterIndexConfig(
      etCoefficient: etCoefficient ?? this.etCoefficient,
      etDivisor: etDivisor ?? this.etDivisor,
      soilType: soilType ?? this.soilType,
      devMode: devMode ?? this.devMode,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'etCoefficient': etCoefficient,
      'etDivisor': etDivisor,
      'soilType': soilType.name,
      'devMode': devMode,
    };
  }

  factory WaterIndexConfig.fromJson(Map<String, dynamic> json) {
    return WaterIndexConfig(
      etCoefficient: (json['etCoefficient'] as num?)?.toDouble() ?? 0.16,
      etDivisor: (json['etDivisor'] as num?)?.toDouble() ?? 12.0,
      soilType: SoilType.values.firstWhere(
        (e) => e.name == json['soilType'],
        orElse: () => SoilType.loam,
      ),
      devMode: json['devMode'] as bool? ?? true,
    );
  }
}

/// Soil types with their water holding capacity thresholds
enum SoilType {
  sandy(
    displayName: 'Sandet jord',
    wateringThreshold: 17.5, // Average of 15-20mm
    description: 'Drænner hurtigt, kræver hyppigere vanding',
  ),
  loam(
    displayName: 'Muldjord',
    wateringThreshold: 35.0, // Average of 30-40mm
    description: 'God vandholdende evne, standard for højbede',
  ),
  clay(
    displayName: 'Lerjord',
    wateringThreshold: 45.0, // Average of 40-50mm
    description: 'Holder længe på vand, kan blive vandlidende',
  );

  final String displayName;
  final double wateringThreshold;
  final String description;

  const SoilType(
      {required this.displayName,
      required this.wateringThreshold,
      required this.description});
}
