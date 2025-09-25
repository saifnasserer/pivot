import 'package:flutter/foundation.dart';

/// Service for managing smart refresh logic to reduce unnecessary Firebase calls
class SmartRefreshService {
  static final SmartRefreshService _instance = SmartRefreshService._internal();
  factory SmartRefreshService() => _instance;
  SmartRefreshService._internal();

  // Track last refresh times for different data types
  final Map<String, DateTime> _lastRefreshTimes = {};

  // Default refresh intervals (in minutes)
  static const Map<String, int> _defaultRefreshIntervals = {
    'announcements': 10, // 10 minutes
    'tasks': 5, // 5 minutes
    'schedule': 15, // 15 minutes
    'users': 30, // 30 minutes
    'subjects': 120, // 2 hours
    'sections': 60, // 1 hour
  };

  /// Check if data should be refreshed based on last refresh time
  bool shouldRefresh(String dataType, {int? customIntervalMinutes}) {
    final lastRefresh = _lastRefreshTimes[dataType];
    if (lastRefresh == null) return true;

    final intervalMinutes =
        customIntervalMinutes ?? _defaultRefreshIntervals[dataType] ?? 30;
    final nextRefreshTime = lastRefresh.add(Duration(minutes: intervalMinutes));

    return DateTime.now().isAfter(nextRefreshTime);
  }

  /// Mark data as refreshed
  void markRefreshed(String dataType) {
    _lastRefreshTimes[dataType] = DateTime.now();
  }

  /// Force refresh (bypasses interval check)
  void forceRefresh(String dataType) {
    _lastRefreshTimes[dataType] = DateTime(1970); // Very old timestamp
  }

  /// Get time since last refresh
  Duration? getTimeSinceLastRefresh(String dataType) {
    final lastRefresh = _lastRefreshTimes[dataType];
    if (lastRefresh == null) return null;
    return DateTime.now().difference(lastRefresh);
  }

  /// Get refresh statistics
  Map<String, dynamic> getRefreshStats() {
    final stats = <String, dynamic>{};

    for (final entry in _lastRefreshTimes.entries) {
      final dataType = entry.key;
      final lastRefresh = entry.value;
      final timeSince = DateTime.now().difference(lastRefresh);
      final interval = _defaultRefreshIntervals[dataType] ?? 30;
      final shouldRefreshNow = shouldRefresh(dataType);

      stats[dataType] = {
        'lastRefresh': lastRefresh.toIso8601String(),
        'timeSinceMinutes': timeSince.inMinutes,
        'intervalMinutes': interval,
        'shouldRefresh': shouldRefreshNow,
        'nextRefreshIn': shouldRefreshNow ? 0 : interval - timeSince.inMinutes,
      };
    }

    return stats;
  }

  /// Clear all refresh timestamps
  void clearAll() {
    _lastRefreshTimes.clear();
  }

  /// Smart refresh with automatic interval management
  Future<T> smartRefresh<T>(
    String dataType,
    Future<T> Function() refreshFunction, {
    int? customIntervalMinutes,
    bool force = false,
  }) async {
    if (!force &&
        !shouldRefresh(
          dataType,
          customIntervalMinutes: customIntervalMinutes,
        )) {
      // Return cached data or null if no cache available
      return Future.value(null as T);
    }

    try {
      final result = await refreshFunction();
      markRefreshed(dataType);
      return result;
    } catch (e) {
      if (kDebugMode) {
        print('SmartRefreshService: Error refreshing $dataType: $e');
      }
      rethrow;
    }
  }

  /// Batch refresh multiple data types
  Future<Map<String, dynamic>> batchRefresh(
    List<String> dataTypes,
    Map<String, Future<dynamic> Function()> refreshFunctions, {
    bool force = false,
  }) async {
    final results = <String, dynamic>{};

    for (final dataType in dataTypes) {
      if (refreshFunctions.containsKey(dataType)) {
        try {
          final result = await smartRefresh(
            dataType,
            refreshFunctions[dataType]!,
            force: force,
          );
          results[dataType] = result;
        } catch (e) {
          results[dataType] = {'error': e.toString()};
        }
      }
    }

    return results;
  }

  /// Get optimal refresh schedule based on usage patterns
  Map<String, int> getOptimalRefreshSchedule() {
    // This could be enhanced with machine learning or usage analytics
    return Map.from(_defaultRefreshIntervals);
  }

  /// Update refresh interval for a data type
  void updateRefreshInterval(String dataType, int intervalMinutes) {
    // This would be used to dynamically adjust intervals based on usage
    // For now, we keep the static intervals
  }
}
