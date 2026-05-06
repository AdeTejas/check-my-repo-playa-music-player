import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'analytics_service.dart';
import 'logger_service.dart';
import 'telemetry_service.dart';

/// Dedicated controller for bookmark operations
/// Separates bookmark logic from main PlayerController
class BookmarkController extends ChangeNotifier {
  late SharedPreferences _prefs;
  bool _initialized = false;
  final List<Map<String, dynamic>> bookmarks = [];
  String? _lastLoadedId;

  Future<void> init() async {
    if (_initialized) return;
    _prefs = await SharedPreferences.getInstance();
    _initialized = true;
    debugPrint('[BookmarkController] Initialized');
  }

  /// Load bookmarks for a specific track ID
  Future<void> loadBookmarks(String trackId) async {
    if (!_initialized) {
      await init();
    }

    if (trackId == _lastLoadedId) {
      debugPrint('[BookmarkController] Already loaded for $trackId, skipping');
      return;
    }

    _lastLoadedId = trackId;
    TelemetryService.instance.startTimer('bookmark_load');

    try {
      final key = 'bookmarks_$trackId';
      final saved = _prefs.getStringList(key) ?? [];
      bookmarks.clear();

      for (final s in saved) {
        try {
          final map = jsonDecode(s) as Map<String, dynamic>;
          if (!map.containsKey('pos') || map['pos'] is! int) {
            continue;
          }
          bookmarks.add(map);
        } catch (e) {
          final ms = int.tryParse(s);
          if (ms != null && ms >= 0) {
            bookmarks.add({'pos': ms, 'note': ''});
          }
        }
      }

      final loadTimeMs = TelemetryService.instance.stopTimer('bookmark_load');
      debugPrint('[BookmarkController] ✓ Loaded ${bookmarks.length} bookmarks in ${loadTimeMs}ms');
      AnalyticsService.logEvent('bookmarks_loaded', {
        'track_id': trackId,
        'count': bookmarks.length,
        'load_time_ms': loadTimeMs ?? 0,
      });

      notifyListeners();
    } catch (e, st) {
      LoggerService.instance.warning('Error loading bookmarks', e, st);
      debugPrint('[BookmarkController] ❌ Error loading bookmarks: $e');
      await AnalyticsService.instance.logException(e, st, context: {
        'operation': 'loadBookmarks',
        'track_id': trackId,
      });
      bookmarks.clear();
      notifyListeners();
    }
  }

  /// Add a bookmark at specified position
  Future<void> addBookmark(int positionMs, {String note = ''}) async {
    if (!_initialized) await init();

    try {
      if (positionMs < 0) {
        throw ArgumentError('Position cannot be negative');
      }

      bookmarks.add({'pos': positionMs, 'note': note});

      // Limit bookmarks to prevent memory issues
      if (bookmarks.length > 500) {
        bookmarks.removeRange(0, bookmarks.length - 500);
        debugPrint('[BookmarkController] Trimmed bookmarks to 500');
      }

      await _save();
      debugPrint('[BookmarkController] ✓ Bookmark added at ${positionMs}ms');
      AnalyticsService.logEvent('bookmark_added', {
        'pos_ms': positionMs,
        'note_length': note.length,
      });
      notifyListeners();
    } catch (e, st) {
      LoggerService.instance.warning('Error adding bookmark', e, st);
      await AnalyticsService.instance.logException(e, st);
    }
  }

  /// Remove bookmark at index
  Future<void> removeBookmark(int index) async {
    if (!_initialized) await init();
    if (index < 0 || index >= bookmarks.length) return;

    try {
      bookmarks.removeAt(index);
      await _save();
      debugPrint('[BookmarkController] ✓ Bookmark removed at index $index');
      AnalyticsService.logEvent('bookmark_removed', {'index': index});
      notifyListeners();
    } catch (e, st) {
      LoggerService.instance.warning('Error removing bookmark', e, st);
      await AnalyticsService.instance.logException(e, st);
    }
  }

  /// Update bookmark note at index
  Future<void> updateNote(int index, String newNote) async {
    if (!_initialized) await init();
    if (index < 0 || index >= bookmarks.length) return;

    try {
      bookmarks[index]['note'] = newNote;
      await _save();
      debugPrint('[BookmarkController] ✓ Bookmark note updated at index $index');
      AnalyticsService.logEvent('bookmark_updated', {'index': index});
      notifyListeners();
    } catch (e, st) {
      LoggerService.instance.warning('Error updating bookmark', e, st);
      await AnalyticsService.instance.logException(e, st);
    }
  }

  /// Save bookmarks to SharedPreferences
  Future<void> _save() async {
    if (!_initialized || _lastLoadedId == null) return;

    TelemetryService.instance.startTimer('bookmark_save');
    try {
      final key = 'bookmarks_$_lastLoadedId';
      final encoded = bookmarks.map((b) => jsonEncode(b)).toList();
      await _prefs.setStringList(key, encoded);

      final saveTimeMs = TelemetryService.instance.stopTimer('bookmark_save');
      debugPrint('[BookmarkController] ✓ Saved ${encoded.length} bookmarks in ${saveTimeMs}ms');
    } catch (e, st) {
      LoggerService.instance.warning('Error saving bookmarks', e, st);
      TelemetryService.instance.stopTimer('bookmark_save');
      await AnalyticsService.instance.logException(e, st, context: {
        'operation': '_save',
        'bookmark_count': bookmarks.length,
      });
    }
  }

  /// Clear all bookmarks
  void clear() {
    bookmarks.clear();
    _lastLoadedId = null;
    notifyListeners();
  }

  /// Get bookmark at index
  Map<String, dynamic>? getBookmark(int index) {
    if (index < 0 || index >= bookmarks.length) return null;
    return bookmarks[index];
  }

  /// Get all bookmarks
  List<Map<String, dynamic>> getAll() => List.unmodifiable(bookmarks);
}
