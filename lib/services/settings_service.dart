import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';

class SettingsService extends ChangeNotifier {
  static final SettingsService _instance = SettingsService._();
  static SettingsService get instance => _instance;

  static const String themeClassic = 'classic';
  static const String themeNeon = 'neon';
  static const String themeAlbumArt = 'albumArt';

  // Color Palette - saturated accents tuned for the matte dark UI.
  static const Map<String, int> colorPresets = {
    'Imperial Red': 0xFFE21B2D,
    'Darth Vader Black': 0xFF050508,
    'Beskar Teal': 0xFF008C99,
    'Sith Crimson': 0xFFB11226,
    'Tatooine Amber': 0xFFE08A14,
    'Jedi Green': 0xFF00A862,
    'Hoth Blue': 0xFF2384C6,
    'Mace Violet': 0xFF7432A8,
    'Mustafar Ember': 0xFFE1461F,
    'Imperial Indigo': 0xFF263FA8,
  };

  SettingsService._();

  late SharedPreferences _prefs;
  bool _initialized = false;

  bool _batterySaver = false;
  bool _lowPerformanceMode = false;
  bool _showSpaceBackground = true;
  bool _highQualityBlur = true;
  bool _showWaveforms = true;
  bool _screensaverEnabled = false;
  int _screensaverIdleSeconds = 60;
  bool _keepScreenOn = false;
  String _audioFocusMode = 'pause'; // 'pause', 'duck', 'none'

  // Playback audio processing settings
  int _crossfadeSeconds = 0;
  int _sleepFadeSeconds = 10;
  bool _replayGainEnabled = false;
  bool _smartVolumeLimiterEnabled = false;
  int _accentColor = 0xFFE21B2D;
  String _themeMode = themeClassic;

  // Turntable settings
  int _turntablePerfTier = 2; // 0=off, 1=minimal, 2=full
  bool _turntableSlipmatEnabled = true;
  bool _turntableNeedleDropEnabled = true;
  String _librarySortType =
      'DATE_ADDED'; // 'TITLE', 'ARTIST', 'ALBUM', 'DATE_ADDED'
  int _librarySortOrder = 0; // 0: ASC, 1: DESC

  // Windows scan settings
  List<String> _windowsScanFolders = const <String>[];
  bool _windowsScanRecursive = true;
  List<String> _windowsScanExtensions = const <String>[
    'mp3',
    'm4a',
    'aac',
    'wav',
    'flac',
    'ogg',
    'opus',
    'wma',
    'aiff',
    'alac',
  ];

  // Control chips ordering
  List<String> _controlChipOrder = const <String>[
    'shuffle',
    'repeat',
    'neural_mix',
    'speed',
    'screensaver',
    'bookmark',
    'lyrics',
  ];

  // Theme customization colors
  int _glowColor = 0xFFE21B2D; // Default imperial red glow
  int _vinylColor = 0xFF07070A; // Vader-black vinyl
  int _plinthColor = 0xFF11131A; // Deep saturated plinth

  bool get batterySaver => _batterySaver;
  bool get lowPerformanceMode => _lowPerformanceMode;
  bool get showSpaceBackground => _showSpaceBackground;
  bool get highQualityBlur => _highQualityBlur;
  bool get showWaveforms => _showWaveforms;
  bool get screensaverEnabled => _screensaverEnabled;
  int get screensaverIdleSeconds => _screensaverIdleSeconds;
  bool get keepScreenOn => _keepScreenOn;
  String get audioFocusMode => _audioFocusMode;
  int get crossfadeSeconds => _crossfadeSeconds;
  int get sleepFadeSeconds => _sleepFadeSeconds;
  bool get replayGainEnabled => _replayGainEnabled;
  bool get smartVolumeLimiterEnabled => _smartVolumeLimiterEnabled;
  int get accentColor => _accentColor;
  String get themeMode => _themeMode;
  bool get isClassicTheme => _themeMode == themeClassic;
  bool get isNeonTheme => _themeMode == themeNeon;
  bool get isAlbumArtTheme => _themeMode == themeAlbumArt;
  int get turntablePerfTier => _turntablePerfTier;
  bool get turntableSlipmatEnabled => _turntableSlipmatEnabled;
  bool get turntableNeedleDropEnabled => _turntableNeedleDropEnabled;
  String get librarySortType => _librarySortType;
  int get librarySortOrder => _librarySortOrder;
  List<String> get windowsScanFolders => List.unmodifiable(_windowsScanFolders);
  bool get windowsScanRecursive => _windowsScanRecursive;
  List<String> get windowsScanExtensions =>
      List.unmodifiable(_windowsScanExtensions);
  List<String> get controlChipOrder => List.unmodifiable(_controlChipOrder);
  int get glowColor => _glowColor;
  int get vinylColor => _vinylColor;
  int get plinthColor => _plinthColor;

  bool get expensiveEffectsEnabled => !_batterySaver && !_lowPerformanceMode;
  bool get effectiveShowSpaceBackground =>
      _showSpaceBackground && expensiveEffectsEnabled;
  bool get effectiveHighQualityBlur =>
      _highQualityBlur && expensiveEffectsEnabled;
  bool get effectiveShowWaveforms => _showWaveforms && expensiveEffectsEnabled;
  bool get effectiveScreensaverEnabled =>
      _screensaverEnabled && expensiveEffectsEnabled;

  Future<void> init() async {
    if (_initialized) return;
    _prefs = await SharedPreferences.getInstance();
    _batterySaver = _prefs.getBool('batterySaver') ?? false;
    _showSpaceBackground = _prefs.getBool('showSpaceBackground') ?? true;
    _highQualityBlur = _prefs.getBool('highQualityBlur') ?? true;
    _showWaveforms = _prefs.getBool('showWaveforms') ?? true;
    _screensaverEnabled = _prefs.getBool('screensaverEnabled') ?? false;
    _screensaverIdleSeconds = (_prefs.getInt('screensaverIdleSeconds') ?? 60)
        .clamp(15, 600);
    _keepScreenOn = _prefs.getBool('keepScreenOn') ?? false;
    if (_keepScreenOn) {
      WakelockPlus.enable();
    }
    _audioFocusMode = _prefs.getString('audioFocusMode') ?? 'pause';

    _crossfadeSeconds = _prefs.getInt('crossfadeSeconds') ?? 0;
    _sleepFadeSeconds = (_prefs.getInt('sleepFadeSeconds') ?? 10).clamp(0, 30);
    _replayGainEnabled = _prefs.getBool('replayGainEnabled') ?? false;
    _smartVolumeLimiterEnabled =
        _prefs.getBool('smartVolumeLimiterEnabled') ?? false;
    final savedAccentColor = _prefs.getInt('accentColor');
    _accentColor = savedAccentColor ?? 0xFFE21B2D;
    if (_accentColor == 0xFF00E5FF ||
        _accentColor == 0xFF00B8D9 ||
        _accentColor == 0xFF007A8A) {
      _accentColor = 0xFFE21B2D;
      await _prefs.setInt('accentColor', _accentColor);
    }
    _themeMode = _prefs.getString('themeMode') ?? themeClassic;

    _turntablePerfTier = (_prefs.getInt('turntablePerfTier') ?? 2).clamp(0, 2);
    _turntableSlipmatEnabled =
        _prefs.getBool('turntableSlipmatEnabled') ?? true;
    _turntableNeedleDropEnabled =
        _prefs.getBool('turntableNeedleDropEnabled') ?? true;
    _librarySortType = _prefs.getString('librarySortType') ?? 'DATE_ADDED';
    _librarySortOrder =
        _prefs.getInt('librarySortOrder') ?? 1; // Default DESC for Date Added

    _windowsScanFolders =
        _prefs.getStringList('windowsScanFolders') ?? const <String>[];
    _windowsScanRecursive = _prefs.getBool('windowsScanRecursive') ?? true;
    _windowsScanExtensions =
        _prefs.getStringList('windowsScanExtensions') ?? _windowsScanExtensions;

    _controlChipOrder =
        _prefs.getStringList('controlChipOrder') ??
        const <String>[
          'shuffle',
          'repeat',
          'neural_mix',
          'speed',
          'screensaver',
          'bookmark',
          'lyrics',
        ];
    final savedGlowColor = _prefs.getInt('glowColor');
    _glowColor = savedGlowColor ?? 0xFFE21B2D;
    if (_glowColor == 0xFF00E5FF ||
        _glowColor == 0xFF00B8D9 ||
        _glowColor == 0xFF007A8A) {
      _glowColor = 0xFFE21B2D;
      await _prefs.setInt('glowColor', _glowColor);
    }
    _vinylColor = _prefs.getInt('vinylColor') ?? 0xFF07070A;
    _plinthColor = _prefs.getInt('plinthColor') ?? 0xFF11131A;

    // Check for low performance mode preference, or auto-detect if not set
    if (_prefs.containsKey('lowPerformanceMode')) {
      _lowPerformanceMode = _prefs.getBool('lowPerformanceMode')!;
    } else {
      await _detectDeviceCapabilities();
    }

    _initialized = true;
    notifyListeners();
  }

  Future<void> setCrossfadeSeconds(int seconds) async {
    final v = seconds.clamp(0, 12);
    _crossfadeSeconds = v;
    await _prefs.setInt('crossfadeSeconds', v);
    notifyListeners();
  }

  Future<void> setSleepFadeSeconds(int seconds) async {
    final v = seconds.clamp(0, 30);
    _sleepFadeSeconds = v;
    await _prefs.setInt('sleepFadeSeconds', v);
    notifyListeners();
  }

  Future<void> setReplayGainEnabled(bool value) async {
    _replayGainEnabled = value;
    await _prefs.setBool('replayGainEnabled', value);
    notifyListeners();
  }

  Future<void> setSmartVolumeLimiterEnabled(bool value) async {
    _smartVolumeLimiterEnabled = value;
    await _prefs.setBool('smartVolumeLimiterEnabled', value);
    notifyListeners();
  }

  Future<void> _detectDeviceCapabilities() async {
    try {
      if (Platform.isAndroid) {
        final deviceInfo = DeviceInfoPlugin();
        final androidInfo = await deviceInfo.androidInfo;

        // Heuristic: Android SDK < 29 (Android 10) often implies older hardware
        final isOldAndroid = androidInfo.version.sdkInt < 29;

        if (isOldAndroid) {
          debugPrint(
            'Low performance device detected (SDK: ${androidInfo.version.sdkInt})',
          );
          await setLowPerformanceMode(true);
        }
      }
    } catch (e) {
      debugPrint('Error detecting device capabilities: $e');
    }
  }

  Future<void> setLowPerformanceMode(bool value) async {
    _lowPerformanceMode = value;
    await _prefs.setBool('lowPerformanceMode', value);

    if (value) {
      // Auto-disable heavy features
      _showSpaceBackground = false;
      _highQualityBlur = false;
      _showWaveforms = false;
      _screensaverEnabled = false;
      await _prefs.setBool('showSpaceBackground', false);
      await _prefs.setBool('highQualityBlur', false);
      await _prefs.setBool('showWaveforms', false);
      await _prefs.setBool('screensaverEnabled', false);
    } else {
      // Restore features when disabling low performance mode
      // We default to true for a better experience, or we could store previous state
      // For now, let's re-enable them as that's the expected behavior
      _showSpaceBackground = true;
      _highQualityBlur = true;
      _showWaveforms = true;
      await _prefs.setBool('showSpaceBackground', true);
      await _prefs.setBool('highQualityBlur', true);
      await _prefs.setBool('showWaveforms', true);
    }
    notifyListeners();
  }

  Future<void> setKeepScreenOn(bool value) async {
    _keepScreenOn = value;
    await _prefs.setBool('keepScreenOn', value);
    notifyListeners();
  }

  Future<void> setAudioFocusMode(String value) async {
    _audioFocusMode = value;
    await _prefs.setString('audioFocusMode', value);
    notifyListeners();
  }

  Future<void> setAccentColor(int value) async {
    _accentColor = value;
    await _prefs.setInt('accentColor', value);
    notifyListeners();
  }

  Future<void> setThemeMode(String value) async {
    final normalized =
        (value == themeNeon || value == themeAlbumArt) ? value : themeClassic;
    _themeMode = normalized;
    await _prefs.setString('themeMode', normalized);
    notifyListeners();
  }

  Future<void> setTurntablePerfTier(int value) async {
    final v = value.clamp(0, 2);
    _turntablePerfTier = v;
    await _prefs.setInt('turntablePerfTier', v);
    notifyListeners();
  }

  Future<void> setTurntableSlipmatEnabled(bool value) async {
    _turntableSlipmatEnabled = value;
    await _prefs.setBool('turntableSlipmatEnabled', value);
    notifyListeners();
  }

  Future<void> setTurntableNeedleDropEnabled(bool value) async {
    _turntableNeedleDropEnabled = value;
    await _prefs.setBool('turntableNeedleDropEnabled', value);
    notifyListeners();
  }

  Future<void> setBatterySaver(bool value) async {
    _batterySaver = value;
    await _prefs.setBool('batterySaver', value);
    // Auto-disable high quality stuff if battery saver is on
    if (value) {
      _showSpaceBackground = false;
      _highQualityBlur = false;
      _showWaveforms = false;
      _screensaverEnabled = false;
      _keepScreenOn = false; // Disable wakelock for battery saving
      await _prefs.setBool('showSpaceBackground', false);
      await _prefs.setBool('highQualityBlur', false);
      await _prefs.setBool('showWaveforms', false);
      await _prefs.setBool('screensaverEnabled', false);
      await _prefs.setBool('keepScreenOn', false);
      WakelockPlus.disable(); // Immediately disable if active
    } else {
      // Restore defaults or keep as is? Let's restore defaults for convenience
      _showSpaceBackground = true;
      _highQualityBlur = true;
      _showWaveforms = true;
      await _prefs.setBool('showSpaceBackground', true);
      await _prefs.setBool('highQualityBlur', true);
      await _prefs.setBool('showWaveforms', true);
    }
    notifyListeners();
  }

  Future<void> setShowWaveforms(bool value) async {
    _showWaveforms = value;
    await _prefs.setBool('showWaveforms', value);
    notifyListeners();
  }

  Future<void> setScreensaverEnabled(bool value) async {
    _screensaverEnabled = value;
    await _prefs.setBool('screensaverEnabled', value);
    notifyListeners();
  }

  Future<void> setScreensaverIdleSeconds(int seconds) async {
    final v = seconds.clamp(15, 600);
    _screensaverIdleSeconds = v;
    await _prefs.setInt('screensaverIdleSeconds', v);
    notifyListeners();
  }

  Future<void> setShowSpaceBackground(bool value) async {
    _showSpaceBackground = value;
    await _prefs.setBool('showSpaceBackground', value);
    notifyListeners();
  }

  Future<void> setHighQualityBlur(bool value) async {
    _highQualityBlur = value;
    await _prefs.setBool('highQualityBlur', value);
    notifyListeners();
  }

  Future<void> setLibrarySort(String type, int order) async {
    _librarySortType = type;
    _librarySortOrder = order;
    await _prefs.setString('librarySortType', type);
    await _prefs.setInt('librarySortOrder', order);
    notifyListeners();
  }

  Future<void> setWindowsScanFolders(List<String> folders) async {
    _windowsScanFolders = folders
        .where((p) => p.trim().isNotEmpty)
        .toList(growable: false);
    await _prefs.setStringList('windowsScanFolders', _windowsScanFolders);
    notifyListeners();
  }

  Future<void> setWindowsScanRecursive(bool value) async {
    _windowsScanRecursive = value;
    await _prefs.setBool('windowsScanRecursive', value);
    notifyListeners();
  }

  Future<void> setWindowsScanExtensions(List<String> exts) async {
    _windowsScanExtensions = exts
        .map((e) => e.trim().toLowerCase())
        .where((e) => e.isNotEmpty)
        .toSet()
        .toList(growable: false);
    await _prefs.setStringList('windowsScanExtensions', _windowsScanExtensions);
    notifyListeners();
  }

  Future<void> setControlChipOrder(List<String> order) async {
    _controlChipOrder = List.unmodifiable(order);
    await _prefs.setStringList('controlChipOrder', order);
    notifyListeners();
  }

  Future<void> setGlowColor(int color) async {
    _glowColor = color;
    await _prefs.setInt('glowColor', color);
    notifyListeners();
  }

  Future<void> setVinylColor(int color) async {
    _vinylColor = color;
    await _prefs.setInt('vinylColor', color);
    notifyListeners();
  }

  Future<void> setPlinthColor(int color) async {
    _plinthColor = color;
    await _prefs.setInt('plinthColor', color);
    notifyListeners();
  }
}
