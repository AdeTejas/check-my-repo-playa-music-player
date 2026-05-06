import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Performance telemetry for tracking app metrics
class TelemetryService {
  static final TelemetryService _instance = TelemetryService._internal();

  factory TelemetryService() => _instance;

  TelemetryService._internal();

  static TelemetryService get instance => _instance;

  final Map<String, List<int>> _timings = {};
  final Map<String, int> _counters = {};
  late SharedPreferences _prefs;
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    _prefs = await SharedPreferences.getInstance();
    _initialized = true;
    debugPrint('[TELEMETRY] Service initialized');
  }

  /// Start tracking a metric
  final Map<String, Stopwatch> _stopwatches = {};

  void startTimer(String metricName) {
    _stopwatches[metricName] = Stopwatch()..start();
  }

  /// Stop tracking and record the metric
  int? stopTimer(String metricName) {
    final sw = _stopwatches.remove(metricName);
    if (sw == null) return null;
    sw.stop();
    final ms = sw.elapsedMilliseconds;
    _recordTiming(metricName, ms);
    return ms;
  }

  void _recordTiming(String metricName, int ms) {
    if (!_timings.containsKey(metricName)) {
      _timings[metricName] = [];
    }
    _timings[metricName]!.add(ms);
    debugPrint('[TELEMETRY] $metricName: ${ms}ms');
  }

  /// Increment a counter metric
  void incrementCounter(String metricName, {int amount = 1}) {
    _counters[metricName] = (_counters[metricName] ?? 0) + amount;
    debugPrint('[TELEMETRY] $metricName count: ${_counters[metricName]}');
  }

  /// Get average time for a metric
  double? getAverageTime(String metricName) {
    final timings = _timings[metricName];
    if (timings == null || timings.isEmpty) return null;
    return timings.reduce((a, b) => a + b) / timings.length;
  }

  /// Get all metrics as a summary
  Map<String, dynamic> getSummary() {
    final summary = <String, dynamic>{};

    for (final entry in _timings.entries) {
      final timings = entry.value;
      summary[entry.key] = {
        'count': timings.length,
        'avg_ms': (timings.reduce((a, b) => a + b) / timings.length).toStringAsFixed(2),
        'min_ms': timings.reduce((a, b) => a < b ? a : b),
        'max_ms': timings.reduce((a, b) => a > b ? a : b),
      };
    }

    for (final entry in _counters.entries) {
      summary[entry.key] = {'count': entry.value};
    }

    return summary;
  }

  /// Save summary to SharedPreferences
  Future<void> saveSummary() async {
    if (!_initialized) return;
    final summary = getSummary();
    await _prefs.setString('telemetry_summary', jsonEncode(summary));
    debugPrint('[TELEMETRY] Summary saved: $summary');
  }

  /// Clear all metrics
  void clear() {
    _timings.clear();
    _counters.clear();
    debugPrint('[TELEMETRY] Metrics cleared');
  }

  /// Print diagnostics
  void printDiagnostics() {
    debugPrint('=== TELEMETRY DIAGNOSTICS ===');
    final summary = getSummary();
    summary.forEach((key, value) {
      debugPrint('  $key: $value');
    });
    debugPrint('==============================');
  }
}
