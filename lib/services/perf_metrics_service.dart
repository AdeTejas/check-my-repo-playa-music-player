import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';

class PerfMetricsService extends ChangeNotifier {
  static final PerfMetricsService instance = PerfMetricsService._();
  PerfMetricsService._();

  DateTime? _appStartAt;
  Duration? _coldStartToFirstFrame;
  bool _frameTelemetryStarted = false;
  int _frameCount = 0;
  int _jankyFrameCount = 0;
  int _severeFrameCount = 0;
  int _totalFrameMicros = 0;
  Duration _worstFrame = Duration.zero;

  DateTime? get appStartAt => _appStartAt;
  Duration? get coldStartToFirstFrame => _coldStartToFirstFrame;
  int get frameCount => _frameCount;
  int get jankyFrameCount => _jankyFrameCount;
  int get severeFrameCount => _severeFrameCount;
  Duration get worstFrame => _worstFrame;
  double get averageFrameMs =>
      _frameCount == 0 ? 0 : (_totalFrameMicros / _frameCount) / 1000.0;
  double get jankRate => _frameCount == 0 ? 0 : _jankyFrameCount / _frameCount;

  void markAppStart() {
    _appStartAt ??= DateTime.now();
  }

  void startFrameTelemetry() {
    if (_frameTelemetryStarted) return;
    _frameTelemetryStarted = true;
    SchedulerBinding.instance.addTimingsCallback(_handleFrameTimings);
  }

  void markFirstFrame() {
    final start = _appStartAt;
    if (start == null) return;
    if (_coldStartToFirstFrame != null) return;

    _coldStartToFirstFrame = DateTime.now().difference(start);
    notifyListeners();
  }

  void _handleFrameTimings(List<FrameTiming> timings) {
    var changed = false;
    for (final timing in timings) {
      final total = timing.totalSpan;
      _frameCount++;
      _totalFrameMicros += total.inMicroseconds;
      if (total > const Duration(milliseconds: 16)) _jankyFrameCount++;
      if (total > const Duration(milliseconds: 32)) _severeFrameCount++;
      if (total > _worstFrame) _worstFrame = total;
      changed = true;
    }
    if (changed && _frameCount % 30 == 0) notifyListeners();
  }

  String frameSummary() {
    if (_frameCount == 0) return 'no frames captured';
    final jankPct = (jankRate * 100).toStringAsFixed(1);
    return '${averageFrameMs.toStringAsFixed(1)} ms avg, '
        '${_worstFrame.inMilliseconds} ms worst, '
        '$jankPct% janky';
  }
}
