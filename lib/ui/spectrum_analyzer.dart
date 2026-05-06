// ignore_for_file: prefer_const_declarations, prefer_const_constructors

import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:ui' as ui;

/// Spectrum analyzer visualization widget that displays frequency bands
class SpectrumAnalyzer extends StatefulWidget {
  final double height;
  final Color barColor;
  final Color peakColor;
  final double? playbackPosition; // 0.0 to 1.0
  final bool isPlaying;
  final bool showLoadingState;

  const SpectrumAnalyzer({
    required this.height,
    this.barColor = Colors.cyan,
    this.peakColor = Colors.purple,
    this.playbackPosition,
    this.isPlaying = false,
    this.showLoadingState = false,
    super.key,
  });

  @override
  State<SpectrumAnalyzer> createState() => _SpectrumAnalyzerState();
}

class _SpectrumAnalyzerState extends State<SpectrumAnalyzer>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late List<double> _barHeights;
  late List<double> _peakHeights;
  late math.Random _random;

  static const int _bandCount = 20;

  @override
  void initState() {
    super.initState();
    _random = math.Random(42); // Stable seed for consistent animation
    _barHeights = List.filled(_bandCount, 0.0);
    _peakHeights = List.filled(_bandCount, 0.0);

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );

    if (widget.isPlaying) {
      _animationController.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant SpectrumAnalyzer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isPlaying != widget.isPlaying) {
      if (widget.isPlaying) {
        _animationController.repeat();
      } else {
        _animationController.stop();
      }
    }
  }

  void _updateBars() {
    // Simulate spectrum data based on playback position
    final baseIntensity = widget.playbackPosition ?? 0.5;

    for (int i = 0; i < _bandCount; i++) {
      // Create frequency-like variation
      final frequencyFactor = 1.0 - (i / _bandCount);
      final noise = _random.nextDouble();

      // Generate smooth random values for bars
      final targetHeight =
          (baseIntensity * frequencyFactor + noise * 0.4).clamp(0.0, 1.0);

      // Smooth interpolation
      _barHeights[i] =
          _barHeights[i] * 0.7 + targetHeight * 0.3;

      // Peak tracking (decaying)
      if (_barHeights[i] > _peakHeights[i]) {
        _peakHeights[i] = _barHeights[i];
      } else {
        _peakHeights[i] = _peakHeights[i] * 0.95;
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, _) {
        if (widget.isPlaying) {
          _updateBars();
        }

        // Show shimmer effect when not playing or loading
        if (!widget.isPlaying || widget.showLoadingState) {
          return CustomPaint(
            painter: _ShimmerPainter(
              progress: _animationController.value,
              barColor: widget.barColor.withValues(alpha: 0.3),
            ),
            size: Size(double.infinity, widget.height),
          );
        }

        return CustomPaint(
          painter: _SpectrumPainter(
            barHeights: _barHeights,
            peakHeights: _peakHeights,
            barColor: widget.barColor,
            peakColor: widget.peakColor,
          ),
          size: Size(double.infinity, widget.height),
        );
      },
    );
  }
}

class _SpectrumPainter extends CustomPainter {
  final List<double> barHeights;
  final List<double> peakHeights;
  final Color barColor;
  final Color peakColor;

  _SpectrumPainter({
    required this.barHeights,
    required this.peakHeights,
    required this.barColor,
    required this.peakColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final bandWidth = w / barHeights.length;

    // Draw background gradient
    canvas.drawRect(
      Rect.fromLTWH(0, 0, w, h),
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(0, 0),
          Offset(0, h),
          [
            Colors.black.withValues(alpha: 0.3),
            Colors.black.withValues(alpha: 0.0),
          ],
        ),
    );

    for (int i = 0; i < barHeights.length; i++) {
      final barHeight = barHeights[i] * h;
      final peakHeight = peakHeights[i] * h;

      final x = i * bandWidth;

      // Bar gradient
      final barPaint = Paint()
        ..shader = ui.Gradient.linear(
          Offset(x, h),
          Offset(x, h - barHeight),
          [
            barColor.withValues(alpha: 0.3),
            barColor.withValues(alpha: 0.8),
          ],
        );

      // Draw bar
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            x + bandWidth * 0.15,
            h - barHeight,
            bandWidth * 0.7,
            barHeight,
          ),
          Radius.circular(bandWidth * 0.25),
        ),
        barPaint,
      );

      // Draw peak indicator
      if (peakHeight > 1) {
        final peakPaint = Paint()
          ..color = peakColor.withValues(alpha: 0.9)
          ..strokeWidth = 2;

        canvas.drawLine(
          Offset(x + bandWidth * 0.15, h - peakHeight),
          Offset(x + bandWidth * 0.85, h - peakHeight),
          peakPaint,
        );
      }
    }

    // Draw center line for reference
    canvas.drawLine(
      Offset(0, h / 2),
      Offset(w, h / 2),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.1)
        ..strokeWidth = 1,
    );
  }

  @override
  bool shouldRepaint(_SpectrumPainter oldDelegate) {
    return oldDelegate.barHeights != barHeights ||
        oldDelegate.peakHeights != peakHeights;
  }
}

class _ShimmerPainter extends CustomPainter {
  final double progress;
  final Color barColor;

  _ShimmerPainter({
    required this.progress,
    required this.barColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final bandCount = 20;
    final bandWidth = w / bandCount;

    // Create shimmer wave effect
    for (int i = 0; i < bandCount; i++) {
      final x = i * bandWidth;
      final wavePosition = (i / bandCount + progress) % 1.0;
      final barHeight = h * 0.3 * (0.5 + 0.5 * math.sin(wavePosition * math.pi * 2));

      final barPaint = Paint()
        ..color = barColor.withValues(alpha: 0.4 + 0.3 * math.sin(wavePosition * math.pi * 4))
        ..style = PaintingStyle.fill;

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            x + bandWidth * 0.2,
            h - barHeight,
            bandWidth * 0.6,
            barHeight,
          ),
          Radius.circular(bandWidth * 0.2),
        ),
        barPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_ShimmerPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
