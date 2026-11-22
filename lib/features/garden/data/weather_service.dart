import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'models/weather_data_model.dart';

/// Service for fetching weather data from Open-Meteo API and caching in Firestore.
/// Weather data is stored globally as it's location-specific (Langaa, Randers).
class WeatherService {
  final FirebaseFirestore _firestore;

  // Langaa, Randers coordinates (8870)
  static const double latitude = 56.434269;
  static const double longitude = 9.945288;

  WeatherService(this._firestore);

  /// Global weather data collection
  CollectionReference<Map<String, dynamic>> get _weatherCollection =>
      _firestore.collection('weatherData');

  /// Fetch 7-day forecast from Open-Meteo API
  Future<List<WeatherData>> fetchForecast() async {
    final url = Uri.parse(
      'https://api.open-meteo.com/v1/forecast'
      '?latitude=$latitude'
      '&longitude=$longitude'
      '&daily=temperature_2m_mean,temperature_2m_max,temperature_2m_min,precipitation_sum,sunshine_duration'
      '&timezone=Europe/Copenhagen'
      '&forecast_days=7',
    );

    try {
      debugPrint('Weather API: Fetching Forecast $url');
      final response = await http.get(url);

      if (response.statusCode != 200) {
        debugPrint('Weather API: HTTP ${response.statusCode}');
        return [];
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final daily = data['daily'] as Map<String, dynamic>;
      final times = (daily['time'] as List).cast<String>();
      final tempMean = (daily['temperature_2m_mean'] as List).cast<num?>();
      final tempMax = (daily['temperature_2m_max'] as List).cast<num?>();
      final tempMin = (daily['temperature_2m_min'] as List).cast<num?>();
      final precipitation = (daily['precipitation_sum'] as List).cast<num?>();
      final sunshine = (daily['sunshine_duration'] as List).cast<num?>();

      final results = <WeatherData>[];
      for (var i = 0; i < times.length; i++) {
        if (tempMean[i] == null) continue;

        final date = DateTime.parse(times[i]);
        results.add(WeatherData.fromOpenMeteo(
          date: date,
          tempAvg: tempMean[i]?.toDouble() ?? 0,
          tempMin: tempMin[i]?.toDouble() ?? 0,
          tempMax: tempMax[i]?.toDouble() ?? 0,
          precipitation: precipitation[i]?.toDouble() ?? 0,
          sunshineDurationSeconds: sunshine[i]?.toDouble() ?? 0,
          latitude: latitude,
          longitude: longitude,
        ));
      }

      debugPrint('Weather API: Fetched ${results.length} forecast days');
      return results;
    } catch (e) {
      debugPrint('Weather API error: $e');
      return [];
    }
  }

  /// Fetch weather data from Open-Meteo Archive API for a date range
  Future<List<WeatherData>> fetchFromApi(DateTime startDate, DateTime endDate) async {
    final start = _formatDate(startDate);
    final end = _formatDate(endDate);

    final url = Uri.parse(
      'https://archive-api.open-meteo.com/v1/archive'
      '?latitude=$latitude'
      '&longitude=$longitude'
      '&start_date=$start'
      '&end_date=$end'
      '&daily=temperature_2m_mean,temperature_2m_max,temperature_2m_min,precipitation_sum,sunshine_duration'
      '&timezone=Europe/Copenhagen',
    );

    try {
      debugPrint('Weather API: Fetching $url');
      final response = await http.get(url);

      if (response.statusCode != 200) {
        debugPrint('Weather API: HTTP ${response.statusCode}');
        return [];
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (data['error'] == true) {
        debugPrint('Weather API error: ${data['reason']}');
        return [];
      }

      final daily = data['daily'] as Map<String, dynamic>;
      final times = (daily['time'] as List).cast<String>();
      final tempMean = (daily['temperature_2m_mean'] as List).cast<num?>();
      final tempMax = (daily['temperature_2m_max'] as List).cast<num?>();
      final tempMin = (daily['temperature_2m_min'] as List).cast<num?>();
      final precipitation = (daily['precipitation_sum'] as List).cast<num?>();
      final sunshine = (daily['sunshine_duration'] as List).cast<num?>();

      final results = <WeatherData>[];
      for (var i = 0; i < times.length; i++) {
        if (tempMean[i] == null) continue; // Skip invalid data

        final date = DateTime.parse(times[i]);
        results.add(WeatherData.fromOpenMeteo(
          date: date,
          tempAvg: tempMean[i]?.toDouble() ?? 0,
          tempMin: tempMin[i]?.toDouble() ?? 0,
          tempMax: tempMax[i]?.toDouble() ?? 0,
          precipitation: precipitation[i]?.toDouble() ?? 0,
          sunshineDurationSeconds: sunshine[i]?.toDouble() ?? 0,
          latitude: latitude,
          longitude: longitude,
        ));
      }

      debugPrint('Weather API: Fetched ${results.length} days');
      return results;
    } catch (e) {
      debugPrint('Weather API error: $e');
      return [];
    }
  }

  /// Get weather data from Firestore cache
  Future<WeatherData?> getCachedWeather(DateTime date) async {
    final id = WeatherData.dateToId(date);
    final doc = await _weatherCollection.doc(id).get();
    if (doc.exists) {
      return WeatherData.fromFirestore(doc);
    }
    return null;
  }

  /// Get weather data for a date range from cache
  Future<List<WeatherData>> getCachedWeatherRange(
      DateTime startDate, DateTime endDate) async {
    final startId = WeatherData.dateToId(startDate);
    final endId = WeatherData.dateToId(endDate);

    final snapshot = await _weatherCollection
        .where(FieldPath.documentId, isGreaterThanOrEqualTo: startId)
        .where(FieldPath.documentId, isLessThanOrEqualTo: endId)
        .orderBy(FieldPath.documentId)
        .get();

    return snapshot.docs.map((doc) => WeatherData.fromFirestore(doc)).toList();
  }

  /// Save weather data to Firestore cache
  Future<void> cacheWeatherData(List<WeatherData> weatherList) async {
    final batch = _firestore.batch();
    for (final weather in weatherList) {
      batch.set(_weatherCollection.doc(weather.id), weather.toFirestore());
    }
    await batch.commit();
    debugPrint('Weather: Cached ${weatherList.length} days');
  }

  /// Sync weather data: fetch missing days from API and cache them
  Future<List<WeatherData>> syncWeatherData(
      DateTime startDate, DateTime endDate) async {
    // Get cached data
    final cached = await getCachedWeatherRange(startDate, endDate);
    final cachedDates = cached.map((w) => w.id).toSet();
    
    debugPrint('Weather: Syncing ${startDate.toString().split(' ')[0]} to ${endDate.toString().split(' ')[0]}');
    debugPrint('Weather: Found ${cached.length} cached days');

    // Find missing dates
    final allDates = <String>[];
    var current = startDate;
    while (!current.isAfter(endDate)) {
      allDates.add(WeatherData.dateToId(current));
      current = current.add(const Duration(days: 1));
    }

    final missingDates = allDates.where((d) => !cachedDates.contains(d)).toList();

    if (missingDates.isEmpty) {
      debugPrint('Weather: All days cached. Returning ${cached.length} records.');
      return cached;
    }

    debugPrint('Weather: ${missingDates.length} days missing. Fetching from API...');

    // Fetch from yesterday (API has 5-day delay for most recent data)
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    final fetchEnd = endDate.isAfter(yesterday) ? yesterday : endDate;

    if (fetchEnd.isBefore(startDate)) {
      // All requested dates are too recent
      debugPrint('Weather: Requested dates are too recent for archive API. Returning cached.');
      return cached;
    }

    // Fetch from API
    final fetched = await fetchFromApi(startDate, fetchEnd);
    debugPrint('Weather: API returned ${fetched.length} records');

    if (fetched.isNotEmpty) {
      // Cache new data
      final toCache = fetched.where((w) => !cachedDates.contains(w.id)).toList();
      if (toCache.isNotEmpty) {
        debugPrint('Weather: Caching ${toCache.length} new records');
        await cacheWeatherData(toCache);
      }
    }

    // Return combined data
    final all = [...cached, ...fetched];
    all.sort((a, b) => a.date.compareTo(b.date));

    // Remove duplicates
    final seen = <String>{};
    final result = all.where((w) => seen.add(w.id)).toList();
    debugPrint('Weather: Returning total ${result.length} records');
    return result;
  }

  /// Stream weather data for a date range
  Stream<List<WeatherData>> watchWeatherRange(
      DateTime startDate, DateTime endDate) {
    final startId = WeatherData.dateToId(startDate);
    final endId = WeatherData.dateToId(endDate);

    return _weatherCollection
        .where(FieldPath.documentId, isGreaterThanOrEqualTo: startId)
        .where(FieldPath.documentId, isLessThanOrEqualTo: endId)
        .orderBy(FieldPath.documentId)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => WeatherData.fromFirestore(doc)).toList());
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}

// Provider
final weatherServiceProvider = Provider<WeatherService>((ref) {
  return WeatherService(FirebaseFirestore.instance);
});
