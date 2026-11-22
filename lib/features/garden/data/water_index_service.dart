import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'models/water_index_config.dart';
import 'models/watering_log_model.dart';
import 'models/weather_data_model.dart';
import 'weather_service.dart';
import '../../../../shared/providers/home_provider.dart';

/// Service for calculating water deficit and managing watering logs.
class WaterIndexService {
  final FirebaseFirestore _firestore;
  final WeatherService _weatherService;
  final WaterIndexConfig _config;

  WaterIndexService(this._firestore, this._weatherService, this._config);

  /// Get watering logs collection for a home
  CollectionReference<Map<String, dynamic>> _getWateringLogCollection(String homeId) {
    return _firestore
        .collection('homes')
        .doc(homeId)
        .collection('wateringLogs');
  }

  /// Add a new watering log
  Future<void> addWateringLog(WateringLog log) async {
    await _getWateringLogCollection(log.homeId).doc(log.id).set(log.toFirestore());
  }

  /// Delete a watering log
  Future<void> deleteWateringLog(String homeId, String logId) async {
    await _getWateringLogCollection(homeId).doc(logId).delete();
  }

  /// Watch watering logs for a specific bed
  Stream<List<WateringLog>> watchWateringLogsForBed(String homeId, String bedId) {
    return _getWateringLogCollection(homeId)
        .where('bedId', isEqualTo: bedId)
        .snapshots()
        .map((snapshot) {
          final logs = snapshot.docs.map((doc) => WateringLog.fromFirestore(doc)).toList();
          logs.sort((a, b) => b.date.compareTo(a.date)); // Sort descending
          return logs;
        });
  }

  /// Watch all watering logs for a home
  Stream<List<WateringLog>> watchWateringLogs(String homeId) {
    return _getWateringLogCollection(homeId)
        .snapshots()
        .map((snapshot) {
          final logs = snapshot.docs.map((doc) => WateringLog.fromFirestore(doc)).toList();
          logs.sort((a, b) => b.date.compareTo(a.date)); // Sort descending
          return logs;
        });
  }

  /// Get watering logs for a date range
  Future<List<WateringLog>> getWateringLogsInRange(
      String homeId, String bedId, DateTime startDate, DateTime endDate) async {
    // Query only by bedId to avoid composite index requirement
    final snapshot = await _getWateringLogCollection(homeId)
        .where('bedId', isEqualTo: bedId)
        .get();

    final logs = snapshot.docs.map((doc) => WateringLog.fromFirestore(doc)).toList();
    
    // Filter by date range in Dart
    return logs.where((log) {
      return log.date.isAfter(startDate.subtract(const Duration(seconds: 1))) && 
             log.date.isBefore(endDate.add(const Duration(seconds: 1)));
    }).toList();
  }

  /// Calculate total water deficit for a bed from season start to now
  Future<BedWaterStatus> calculateBedWaterStatus(
    String homeId,
    String bedId,
  ) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Check if season is active
    if (!_config.isSeasonActive(today)) {
      return BedWaterStatus(
        bedId: bedId,
        deficit: 0,
        availableWater: 0,
        maxCapacity: _config.maxDeficit,
        lastUpdated: today,
        isSeasonActive: false,
        daysTracked: 0,
      );
    }

    // Get tracking start date
    final startDate = _config.getTrackingStart(today);
    debugPrint('WaterIndex: Calculating for bed $bedId from ${startDate.toString().split(' ')[0]} to ${today.toString().split(' ')[0]}');
    
    // Get weather data (sync with API if needed)
    final weatherData = await _weatherService.syncWeatherData(startDate, today);
    debugPrint('WaterIndex: Retrieved ${weatherData.length} days of weather data');

    // Get watering logs for this bed
    final wateringLogs = await getWateringLogsInRange(homeId, bedId, startDate, now);
    debugPrint('WaterIndex: Retrieved ${wateringLogs.length} watering logs');

    final wateringByDate = <String, double>{};
    for (final log in wateringLogs) {
      final dateId = WeatherData.dateToId(log.date);
      wateringByDate[dateId] = (wateringByDate[dateId] ?? 0) + log.amountMm;
    }

    // Calculate cumulative deficit
    double cumulativeDeficit = 0;
    double totalEvaporation = 0;
    double totalRainfall = 0;
    double totalWatering = 0;

    DateTime lastProcessedDate = startDate.subtract(const Duration(days: 1));

    for (final weather in weatherData) {
      lastProcessedDate = weather.date;
      // Calculate ET for the day
      final et = weather.calculateET(
        k: _config.etCoefficient,
        divisor: _config.etDivisor,
      );
      totalEvaporation += et;
      totalRainfall += weather.rainfall;

      // Get watering for this day
      final watering = wateringByDate[weather.id] ?? 0;
      totalWatering += watering;

      // Calculate net change
      final netChange = et - weather.rainfall - watering;
      final oldDeficit = cumulativeDeficit;
      cumulativeDeficit += netChange;

      // Deficit can go below 0 (soil is saturated/flooded)
      // We allow it to go negative to track surplus water (puddles)
      // if (cumulativeDeficit < 0) cumulativeDeficit = 0;

      // Deficit can't exceed max soil capacity (soil is empty)
      // This prevents "infinite" deficit buildup over dry summers that never recovers
      if (cumulativeDeficit > _config.maxDeficit) {
        cumulativeDeficit = _config.maxDeficit;
      }
      
      // Log significant changes or errors
      if (weather.rainfall > 0 || et > 5 || watering > 0) {
         debugPrint('WaterIndex: ${weather.id} - ET: ${et.toStringAsFixed(1)}, Rain: ${weather.rainfall}, Water: $watering. Deficit: ${oldDeficit.toStringAsFixed(1)} -> ${cumulativeDeficit.toStringAsFixed(1)}');
      }
    }

    // Explicitly handle "today" if it wasn't in weather data (common for current day)
    // This ensures today's watering is always counted immediately
    if (lastProcessedDate.isBefore(today)) {
      final todayId = WeatherData.dateToId(today);
      final todayWatering = wateringByDate[todayId] ?? 0;
      
      if (todayWatering > 0) {
        debugPrint('WaterIndex: Processing today ($todayId) separately. Water: $todayWatering');
        totalWatering += todayWatering;
        
        // Assume 0 ET and 0 Rain for today if no weather data yet
        // This is safe because ET/Rain will be added later when weather data is available
        // But we want the user to see their watering effect immediately
        cumulativeDeficit -= todayWatering;
        
        if (cumulativeDeficit > _config.maxDeficit) {
          cumulativeDeficit = _config.maxDeficit;
        }
        debugPrint('WaterIndex: Updated deficit with today\'s watering: ${cumulativeDeficit.toStringAsFixed(1)}');
      }
    }
    
    debugPrint('WaterIndex: Final Deficit: ${cumulativeDeficit.toStringAsFixed(1)}');

    // Check for flood risk
    FloodRisk floodRisk = FloodRisk.none;
    String? floodMessage;

    // Check current state for flooding (negative deficit)
    if (cumulativeDeficit < 0) {
      final surplus = cumulativeDeficit.abs();
      if (surplus > 20) {
        floodRisk = FloodRisk.critical;
        floodMessage = 'KRITISK: ${surplus.toStringAsFixed(0)}mm stående vand i bedet!';
      } else if (surplus > 10) {
        floodRisk = FloodRisk.danger;
        floodMessage = 'FARE: ${surplus.toStringAsFixed(0)}mm stående vand.';
      } else {
        floodRisk = FloodRisk.warning;
        floodMessage = 'ADVARSEL: Jorden er mættet (${surplus.toStringAsFixed(0)}mm overskud).';
      }
    }

    // Fetch forecast if not already critical
    if (floodRisk != FloodRisk.critical) {
      try {
        final forecast = await _weatherService.fetchForecast();
        
        // 1. Check individual days in forecast
        for (final day in forecast) {
          if (day.rainfall > 45) {
            floodRisk = FloodRisk.critical;
            floodMessage = 'KRITISK: ${day.rainfall.toStringAsFixed(0)}mm regn forventes d. ${_formatDate(day.date)}';
            break; // Critical is highest, stop checking
          } else if (day.rainfall > 40 && floodRisk.index < FloodRisk.danger.index) {
            floodRisk = FloodRisk.danger;
            floodMessage = 'FARE: ${day.rainfall.toStringAsFixed(0)}mm regn forventes d. ${_formatDate(day.date)}';
          } else if (day.rainfall > 30 && floodRisk.index < FloodRisk.warning.index) {
            floodRisk = FloodRisk.warning;
            floodMessage = 'ADVARSEL: Kraftig regn (${day.rainfall.toStringAsFixed(0)}mm) forventes d. ${_formatDate(day.date)}';
          }
        }

        // 2. Check rolling 3-day sum in forecast
        if (floodRisk != FloodRisk.critical) {
          for (int i = 0; i < forecast.length - 2; i++) {
            final sum3Day = forecast[i].rainfall + forecast[i+1].rainfall + forecast[i+2].rainfall;
            if (sum3Day > 60) {
               if (sum3Day > 90) {
                  floodRisk = FloodRisk.critical;
                  floodMessage = 'KRITISK: ${sum3Day.toStringAsFixed(0)}mm regn over 3 dage (${_formatDate(forecast[i].date)}-${_formatDate(forecast[i+2].date)})';
                  break;
               } else if (floodRisk.index < FloodRisk.warning.index) {
                  floodRisk = FloodRisk.warning;
                  floodMessage = 'Høj vandstand: ${sum3Day.toStringAsFixed(0)}mm regn over 3 dage (${_formatDate(forecast[i].date)}-${_formatDate(forecast[i+2].date)})';
               }
            }
          }
        }
      } catch (e) {
        debugPrint('Error checking flood risk: $e');
      }
    }

    final maxCapacity = _config.maxDeficit;
    final availableWater = maxCapacity - cumulativeDeficit;

    return BedWaterStatus(
      bedId: bedId,
      deficit: cumulativeDeficit,
      availableWater: availableWater,
      maxCapacity: maxCapacity,
      lastUpdated: today,
      isSeasonActive: true,
      daysTracked: weatherData.length,
      totalEvaporation: totalEvaporation,
      totalRainfall: totalRainfall,
      totalWatering: totalWatering,
      floodRisk: floodRisk,
      floodMessage: floodMessage,
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}';
  }

  /// Get watering recommendation in liters for a bed
  WateringRecommendation getWateringRecommendation({
    required double deficit,
    required double bedWidthCm,
    required double bedHeightCm,
  }) {
    final areaM2 = (bedWidthCm / 100) * (bedHeightCm / 100);
    final threshold = _config.wateringThreshold;

    if (deficit < threshold * 0.5) {
      return WateringRecommendation(
        status: WaterStatus.optimal,
        deficitMm: deficit,
        recommendedMm: 0,
        recommendedLiters: 0,
        message: 'Optimal vandtilstand',
      );
    } else if (deficit < threshold) {
      return WateringRecommendation(
        status: WaterStatus.adequate,
        deficitMm: deficit,
        recommendedMm: 0,
        recommendedLiters: 0,
        message: 'Vanding snart nødvendig',
      );
    } else {
      // Calculate how much to water
      // Water to bring deficit back below half threshold
      final targetDeficit = threshold * 0.3;
      final neededMm = deficit - targetDeficit;
      final neededLiters = neededMm * areaM2;

      return WateringRecommendation(
        status: WaterStatus.needsWater,
        deficitMm: deficit,
        recommendedMm: neededMm,
        recommendedLiters: neededLiters,
        message: 'Vanding anbefales',
      );
    }
  }
  /// Get historical deficit data for a bed
  Future<List<DailyWaterStatus>> getHistoricalDeficit(
    String homeId,
    String bedId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    // Ensure we don't go before season start if configured
    DateTime effectiveStart = startDate;
    if (_config.isSeasonActive(endDate)) {
      final seasonStart = _config.getTrackingStart(endDate);
      if (effectiveStart.isBefore(seasonStart)) {
        effectiveStart = seasonStart;
      }
    }

    // Get weather data
    final weatherData = await _weatherService.syncWeatherData(effectiveStart, endDate);
    
    // Get watering logs
    final wateringLogs = await getWateringLogsInRange(homeId, bedId, effectiveStart, endDate);
    final wateringByDate = <String, double>{};
    for (final log in wateringLogs) {
      final dateId = WeatherData.dateToId(log.date);
      wateringByDate[dateId] = (wateringByDate[dateId] ?? 0) + log.amountMm;
    }

    // Calculate daily status
    double currentDeficit = 0;
    final result = <DailyWaterStatus>[];

    for (final weather in weatherData) {
      final et = weather.calculateET(
        k: _config.etCoefficient,
        divisor: _config.etDivisor,
      );
      final watering = wateringByDate[weather.id] ?? 0;
      
      final netChange = et - weather.rainfall - watering;
      currentDeficit += netChange;

      // if (currentDeficit < 0) currentDeficit = 0; // Allow negative for surplus
      if (currentDeficit > _config.maxDeficit) currentDeficit = _config.maxDeficit;

      result.add(DailyWaterStatus(
        date: weather.date,
        deficit: currentDeficit,
        rainfall: weather.rainfall,
        watering: watering,
        et: et,
      ));
    }

    return result;
  }
}

/// Daily water status for graphing
class DailyWaterStatus {
  final DateTime date;
  final double deficit;
  final double rainfall;
  final double watering;
  final double et;

  const DailyWaterStatus({
    required this.date,
    required this.deficit,
    required this.rainfall,
    required this.watering,
    required this.et,
  });
}

/// Flood risk levels
enum FloodRisk {
  none,
  warning, // > 30mm
  danger,  // > 40mm
  critical // > 45mm
}

/// Water status for a garden bed
class BedWaterStatus {
  final String bedId;
  final double deficit; // in mm
  final DateTime lastUpdated;
  final bool isSeasonActive;
  final int daysTracked;
  final double totalEvaporation;
  final double totalRainfall;
  final double totalWatering;
  final FloodRisk floodRisk;
  final String? floodMessage;

  final double availableWater; // in mm (maxCapacity - deficit)
  final double maxCapacity; // in mm

  const BedWaterStatus({
    required this.bedId,
    required this.deficit,
    required this.availableWater,
    required this.maxCapacity,
    required this.lastUpdated,
    required this.isSeasonActive,
    required this.daysTracked,
    this.totalEvaporation = 0,
    this.totalRainfall = 0,
    this.totalWatering = 0,
    this.floodRisk = FloodRisk.none,
    this.floodMessage,
  });
}

/// Watering status enum
enum WaterStatus { optimal, adequate, needsWater }

/// Watering recommendation for a bed
class WateringRecommendation {
  final WaterStatus status;
  final double deficitMm;
  final double recommendedMm;
  final double recommendedLiters;
  final String message;

  const WateringRecommendation({
    required this.status,
    required this.deficitMm,
    required this.recommendedMm,
    required this.recommendedLiters,
    required this.message,
  });
}

// Providers

// Provider for the water index configuration
// Watches the Firestore document for the current home
final waterIndexConfigProvider = StreamProvider<WaterIndexConfig>((ref) {
  final homeAsync = ref.watch(currentHomeProvider);
  return homeAsync.when(
    data: (home) {
      if (home == null) return Stream.value(const WaterIndexConfig());
      return FirebaseFirestore.instance
          .collection('homes')
          .doc(home.id)
          .collection('settings')
          .doc('waterIndex')
          .snapshots()
          .map((doc) {
            if (!doc.exists) return const WaterIndexConfig();
            return WaterIndexConfig.fromJson(doc.data()!);
          });
    },
    loading: () => Stream.value(const WaterIndexConfig()),
    error: (_, __) => Stream.value(const WaterIndexConfig()),
  );
});

// Controller for updating the configuration
class WaterIndexConfigController extends StateNotifier<AsyncValue<void>> {
  final String? _homeId;

  WaterIndexConfigController(this._homeId) : super(const AsyncData(null));

  Future<void> updateConfig(WaterIndexConfig config) async {
    if (_homeId == null) return;
    state = const AsyncLoading();
    try {
      await FirebaseFirestore.instance
          .collection('homes')
          .doc(_homeId!)
          .collection('settings')
          .doc('waterIndex')
          .set(config.toJson());
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> setSoilType(SoilType type, WaterIndexConfig currentConfig) async {
    await updateConfig(currentConfig.copyWith(soilType: type));
  }

  Future<void> setDevMode(bool enabled, WaterIndexConfig currentConfig) async {
    await updateConfig(currentConfig.copyWith(devMode: enabled));
  }
}

final waterIndexConfigControllerProvider = StateNotifierProvider<WaterIndexConfigController, AsyncValue<void>>((ref) {
  final home = ref.watch(currentHomeProvider).value;
  return WaterIndexConfigController(home?.id);
});

final waterIndexServiceProvider = Provider<WaterIndexService>((ref) {
  final firestore = FirebaseFirestore.instance;
  final weatherService = ref.watch(weatherServiceProvider);
  // Use default config if loading or error, it will update when stream emits
  final config = ref.watch(waterIndexConfigProvider).value ?? const WaterIndexConfig();
  return WaterIndexService(firestore, weatherService, config);
});

// Provider for watering logs for a specific home
final wateringLogsProvider = StreamProvider.family<List<WateringLog>, String>((ref, homeId) {
  final service = ref.watch(waterIndexServiceProvider);
  return service.watchWateringLogs(homeId);
});

// Provider for watering logs for a specific bed
final bedWateringLogsProvider = StreamProvider.family<List<WateringLog>, ({String homeId, String bedId})>((ref, params) {
  final service = ref.watch(waterIndexServiceProvider);
  return service.watchWateringLogsForBed(params.homeId, params.bedId);
});
