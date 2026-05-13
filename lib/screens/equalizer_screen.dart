import 'dart:math';
import 'package:flutter/material.dart';
import 'package:playa_clean/ui/tokens.dart';
import '../ui/glass_panel.dart';
import '../services/equalizer_service.dart';
import '../services/player_controller.dart';

class EqualizerScreen extends StatefulWidget {
  final int sessionId;
  const EqualizerScreen({super.key, required this.sessionId});

  @override
  State<EqualizerScreen> createState() => _EqualizerScreenState();
}

class _EqualizerScreenState extends State<EqualizerScreen> {
  bool _isInitialized = false;
  bool _isEnabled = false;
  int _bands = 0;
  List<int> _levelRange = [0, 0];
  List<int> _bandLevels = [];
  List<int> _bandCenters = [];
  List<String> _presetNames = [];
  int _currentPreset = 0;
  int? _lastTouchedBand;

  @override
  void initState() {
    super.initState();
    _initializeEqualizer();
  }

  Future<void> _initializeEqualizer() async {
    final sessionId = await _resolveSessionId();
    if (sessionId == 0) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Audio session not ready. Play a song first.'),
          ),
        );
      }
      return;
    }

    try {
      await EqualizerService.initializeEqualizer(sessionId);
      _bandCenters = await EqualizerService.getBandCenterFrequencies();
      _bandLevels = await EqualizerService.getAllBandLevels();
      _bands =
          _bandCenters.isNotEmpty ? _bandCenters.length : _bandLevels.length;

      if (_bandLevels.length < _bands) {
        _bandLevels = List.filled(_bands, 0);
      }

      _levelRange = await EqualizerService.getBandLevelRange();
      _presetNames = await EqualizerService.getPresetNames();
      _currentPreset = await EqualizerService.getCurrentPreset();
      _isEnabled = await EqualizerService.isEnabled();
      if (!_isEnabled) {
        await EqualizerService.setEnabled(true);
        _isEnabled = true;
      }

      setState(() => _isInitialized = true);
    } catch (e) {
      debugPrint('Equalizer init error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to initialize equalizer: $e')),
        );
      }
    }
  }

  Future<int> _resolveSessionId() async {
    var sessionId = widget.sessionId;
    if (sessionId != 0) return sessionId;

    final player = PlayerController.ensure().player;
    for (int i = 0; i < 12; i++) {
      sessionId = player.androidAudioSessionId ?? 0;
      if (sessionId != 0) return sessionId;
      await Future.delayed(const Duration(milliseconds: 180));
    }
    return 0;
  }

  Future<void> _setBandLevel(int band, int level) async {
    try {
      if (!_isEnabled) {
        await EqualizerService.setEnabled(true);
        _isEnabled = true;
      }
      await EqualizerService.setBandLevel(band, level);
      setState(() {
        _bandLevels[band] = level;
        _currentPreset = -1; // Custom
      });
    } catch (e) {
      debugPrint('EQ Error: $e');
    }
  }

  Future<void> _resetFlat() async {
    if (_bands == 0) return;
    try {
      for (int i = 0; i < _bands; i++) {
        await EqualizerService.setBandLevel(i, 0);
      }
      setState(() {
        _bandLevels = List<int>.filled(_bands, 0);
        _currentPreset = -1; // Custom
      });
    } catch (e) {
      debugPrint('EQ Error: $e');
    }
  }

  String _formatDb(int milliBels) {
    final db = milliBels / 100.0;
    final prefix = db > 0 ? '+' : '';
    return '$prefix${db.toStringAsFixed(1)}';
  }

  String _formatHz(int hz) {
    if (hz >= 1000) {
      final v = hz / 1000.0;
      return v >= 10
          ? '${v.toStringAsFixed(0)}kHz'
          : '${v.toStringAsFixed(1)}kHz';
    }
    return '${hz}Hz';
  }

  String get _selectedBandLabel {
    final band = _lastTouchedBand;
    if (band == null || band < 0 || band >= _bandLevels.length) {
      return 'Drag the curve to tune bands';
    }
    final hz = band < _bandCenters.length ? _bandCenters[band] : 0;
    final freq = hz > 0 ? _formatHz(hz) : 'Band ${band + 1}';
    return '$freq  ${_formatDb(_bandLevels[band])} dB';
  }

  Future<void> _usePreset(int preset) async {
    try {
      await EqualizerService.usePreset(preset);
      setState(() => _currentPreset = preset);
      for (int i = 0; i < _bands; i++) {
        _bandLevels[i] = await EqualizerService.getBandLevel(i);
      }
      setState(() {});
    } catch (e) {
      debugPrint('EQ Error: $e');
    }
  }

  Future<void> _toggleEnabled() async {
    try {
      await EqualizerService.setEnabled(!_isEnabled);
      setState(() => _isEnabled = !_isEnabled);
    } catch (e) {
      debugPrint('EQ Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = Theme.of(context).colorScheme.primary;
    final presetLabel =
        _currentPreset >= 0 && _currentPreset < _presetNames.length
            ? _presetNames[_currentPreset]
            : 'Custom';
    final rangeText =
        _levelRange[1] == 0 && _levelRange[0] == 0
            ? ''
            : '${_formatDb(_levelRange[0])} to ${_formatDb(_levelRange[1])} dB';

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Equalizer'),
        backgroundColor: Colors.transparent,
      ),
      body:
          !_isInitialized
              ? const Center(child: CircularProgressIndicator())
              : SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    kSp * 1.5,
                    0,
                    kSp * 1.5,
                    kSp,
                  ),
                  child: Column(
                    children: [
                      GlassPanel(
                        borderRadius: BorderRadius.circular(14),
                        borderColor: Colors.white.withValues(alpha: 0.10),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 9,
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color:
                                      _isEnabled ? accentColor : Colors.white24,
                                  boxShadow:
                                      _isEnabled
                                          ? [
                                            BoxShadow(
                                              color: accentColor.withValues(
                                                alpha: 0.35,
                                              ),
                                              blurRadius: 10,
                                            ),
                                          ]
                                          : null,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      _isEnabled ? 'Live EQ' : 'EQ bypassed',
                                      style: const TextStyle(
                                        color: kColorOn,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '$presetLabel${rangeText.isNotEmpty ? '  |  $rangeText' : ''}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: kColorOn2,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                tooltip: 'Reset flat',
                                visualDensity: VisualDensity.compact,
                                iconSize: 18,
                                onPressed:
                                    _isInitialized && _isEnabled
                                        ? _resetFlat
                                        : null,
                                icon: const Icon(Icons.refresh),
                              ),
                              Switch(
                                value: _isEnabled,
                                onChanged:
                                    _isInitialized
                                        ? (_) => _toggleEnabled()
                                        : null,
                                activeThumbColor: accentColor,
                                activeTrackColor: accentColor.withValues(
                                  alpha: 0.28,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Expanded(
                        child: GlassPanel(
                          borderRadius: BorderRadius.circular(18),
                          borderColor: Colors.white.withValues(alpha: 0.09),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(18),
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                return GestureDetector(
                                  onPanUpdate:
                                      _isEnabled
                                          ? (details) =>
                                              _handleTouch(details, constraints)
                                          : null,
                                  onTapDown:
                                      _isEnabled
                                          ? (details) =>
                                              _handleTouch(details, constraints)
                                          : null,
                                  child: CustomPaint(
                                    size: Size(
                                      constraints.maxWidth,
                                      constraints.maxHeight,
                                    ),
                                    painter: _EQCurvePainter(
                                      bands: _bands,
                                      levels: _bandLevels,
                                      centersHz: _bandCenters,
                                      range: _levelRange,
                                      color: accentColor,
                                      selectedBand: _lastTouchedBand,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _selectedBandLabel,
                        style: const TextStyle(
                          color: kColorOn2,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (_presetNames.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 34,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: _presetNames.length,
                            separatorBuilder:
                                (_, __) => const SizedBox(width: 7),
                            itemBuilder: (context, i) {
                              final isSelected = _currentPreset == i;
                              return ChoiceChip(
                                visualDensity: VisualDensity.compact,
                                label: Text(_presetNames[i]),
                                selected: isSelected,
                                onSelected: (v) => v ? _usePreset(i) : null,
                                selectedColor: accentColor.withValues(
                                  alpha: 0.20,
                                ),
                                backgroundColor: Colors.white.withValues(
                                  alpha: 0.045,
                                ),
                                side: BorderSide(
                                  color:
                                      isSelected
                                          ? accentColor.withValues(alpha: 0.75)
                                          : Colors.white12,
                                ),
                                labelStyle: TextStyle(
                                  color: isSelected ? kColorOn : kColorOn2,
                                  fontSize: 12,
                                  fontWeight:
                                      isSelected
                                          ? FontWeight.w700
                                          : FontWeight.w600,
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
    );
  }

  void _handleTouch(dynamic details, BoxConstraints constraints) {
    if (_bands == 0) return;

    // We need local position relative to the container, which LayoutBuilder gives us implicitly via details.localPosition
    final Offset localPos = details.localPosition;

    final width = constraints.maxWidth;
    final height = constraints.maxHeight;

    // Find nearest band
    final bandWidth = width / (_bands - 1);
    int band = (localPos.dx / bandWidth).round().clamp(0, _bands - 1);
    _lastTouchedBand = band;

    // Calculate level from Y position
    // Y=0 is max level, Y=height is min level
    final t = 1.0 - (localPos.dy / height).clamp(0.0, 1.0);
    final range = _levelRange[1] - _levelRange[0];
    final newLevel = (_levelRange[0] + (t * range)).round();

    _setBandLevel(band, newLevel);
  }
}

class _EQCurvePainter extends CustomPainter {
  final int bands;
  final List<int> levels;
  final List<int> centersHz;
  final List<int> range;
  final Color color;
  final int? selectedBand;

  _EQCurvePainter({
    required this.bands,
    required this.levels,
    required this.centersHz,
    required this.range,
    required this.color,
    required this.selectedBand,
  });

  String _formatHz(int hz) {
    if (hz >= 1000) {
      final v = hz / 1000.0;
      return v >= 10 ? '${v.toStringAsFixed(0)}k' : '${v.toStringAsFixed(1)}k';
    }
    return hz.toString();
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (bands == 0) return;

    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF080A0E),
            Color.lerp(const Color(0xFF080A0E), color, 0.10)!,
            const Color(0xFF030407),
          ],
          stops: const [0.0, 0.52, 1.0],
        ).createShader(Offset.zero & size),
    );

    final paint =
        Paint()
          ..color = color
          ..strokeWidth = 2.6
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round;

    final fillPaint =
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              color.withValues(alpha: 0.18),
              color.withValues(alpha: 0.0),
            ],
          ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
          ..style = PaintingStyle.fill;

    final path = Path();
    final points = <Offset>[];

    final minLvl = range[0];
    final maxLvl = range[1];
    final lvlRange = maxLvl - minLvl;

    for (int i = 0; i < bands; i++) {
      final x = i * (size.width / (bands - 1));
      final level = i < levels.length ? levels[i] : 0;

      // Normalize level to 0.0 - 1.0
      final normalized = lvlRange == 0 ? 0.5 : (level - minLvl) / lvlRange;

      // Y is inverted (0 at top)
      final y = size.height - (normalized * size.height);
      points.add(Offset(x, y));
    }

    final gridPaint =
        Paint()
          ..color = Colors.white.withValues(alpha: 0.055)
          ..strokeWidth = 1.0;
    canvas.drawLine(
      Offset(0, size.height / 2),
      Offset(size.width, size.height / 2),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.12)
        ..strokeWidth = 1.0,
    );
    for (int i = 1; i < 4; i++) {
      final y = size.height * (i / 4);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
    for (final p in points) {
      canvas.drawLine(Offset(p.dx, 0), Offset(p.dx, size.height), gridPaint);
    }

    if (points.isNotEmpty) {
      path.moveTo(points[0].dx, points[0].dy);

      // Catmull-Rom Spline for smooth curve
      for (int i = 0; i < points.length - 1; i++) {
        final p0 = points[max(0, i - 1)];
        final p1 = points[i];
        final p2 = points[i + 1];
        final p3 = points[min(points.length - 1, i + 2)];

        for (double t = 0; t < 1.0; t += 0.1) {
          final pos = _catmullRom(p0, p1, p2, p3, t);
          path.lineTo(pos.dx, pos.dy);
        }
      }
      path.lineTo(points.last.dx, points.last.dy);
    }

    // Draw fill
    final fillPath = Path.from(path);
    fillPath.lineTo(size.width, size.height);
    fillPath.lineTo(0, size.height);
    fillPath.close();
    canvas.drawPath(fillPath, fillPaint);

    canvas.drawPath(
      path,
      Paint()
        ..color = color.withValues(alpha: 0.30)
        ..strokeWidth = 9
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );

    // Draw stroke
    canvas.drawPath(path, paint);

    final pointPaint = Paint()..color = const Color(0xFFEFE6D6);
    for (int i = 0; i < points.length; i++) {
      final p = points[i];
      if (selectedBand != null && selectedBand == i) {
        canvas.drawCircle(
          p,
          6.0,
          Paint()..color = Colors.white.withValues(alpha: 0.35),
        );
        canvas.drawCircle(
          p,
          3.5,
          Paint()..color = color.withValues(alpha: 0.85),
        );
      } else {
        canvas.drawCircle(p, 4.0, pointPaint);
      }
    }

    // Draw band labels
    if (centersHz.length == bands) {
      final labelStyle = TextStyle(
        color: Colors.white.withValues(alpha: 0.55),
        fontSize: 10,
        fontWeight: FontWeight.w600,
      );
      for (int i = 0; i < bands; i++) {
        final x = i * (size.width / (bands - 1));
        final tp = TextPainter(
          text: TextSpan(text: _formatHz(centersHz[i]), style: labelStyle),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, Offset(x - tp.width / 2, size.height - tp.height));
      }
    }
  }

  Offset _catmullRom(Offset p0, Offset p1, Offset p2, Offset p3, double t) {
    final t2 = t * t;
    final t3 = t2 * t;

    final v0 = (p2 - p0) * 0.5;
    final v1 = (p3 - p1) * 0.5;

    return (p1 * (2 * t3 - 3 * t2 + 1)) +
        (p2 * (-2 * t3 + 3 * t2)) +
        (v0 * (t3 - 2 * t2 + t)) +
        (v1 * (t3 - t2));
  }

  @override
  bool shouldRepaint(covariant _EQCurvePainter oldDelegate) => true;
}
