import 'package:flutter/foundation.dart';
import 'package:on_audio_query/on_audio_query.dart' as oaq;

/// Lightweight cache layer for song metadata and artwork
class MetadataCacheService {
  static final MetadataCacheService _instance = MetadataCacheService._internal();

  factory MetadataCacheService() => _instance;

  MetadataCacheService._internal();

  static MetadataCacheService get instance => _instance;

  // Cache storage with TTL
  final Map<int, _CacheEntry<oaq.SongModel>> _songCache = {};
  final Map<int, _CacheEntry<oaq.ArtistModel>> _artistCache = {};
  final Map<int, _CacheEntry<oaq.AlbumModel>> _albumCache = {};

  static const Duration _defaultTtl = Duration(hours: 1);
  static const int _maxCacheSize = 500;

  /// Cache a song
  void cacheSong(oaq.SongModel song) {
    _songCache[song.id] = _CacheEntry(
      data: song,
      expiresAt: DateTime.now().add(_defaultTtl),
    );
    _pruneIfNeeded(_songCache);
  }

  /// Get a cached song
  oaq.SongModel? getCachedSong(int id) {
    final entry = _songCache[id];
    if (entry == null) return null;
    if (entry.isExpired) {
      _songCache.remove(id);
      return null;
    }
    return entry.data;
  }

  /// Batch cache songs
  void cacheSongs(List<oaq.SongModel> songs) {
    for (final song in songs) {
      cacheSong(song);
    }
  }

  /// Cache an artist
  void cacheArtist(oaq.ArtistModel artist) {
    _artistCache[artist.id] = _CacheEntry(
      data: artist,
      expiresAt: DateTime.now().add(_defaultTtl),
    );
    _pruneIfNeeded(_artistCache);
  }

  /// Get a cached artist
  oaq.ArtistModel? getCachedArtist(int id) {
    final entry = _artistCache[id];
    if (entry == null) return null;
    if (entry.isExpired) {
      _artistCache.remove(id);
      return null;
    }
    return entry.data;
  }

  /// Cache an album
  void cacheAlbum(oaq.AlbumModel album) {
    _albumCache[album.id] = _CacheEntry(
      data: album,
      expiresAt: DateTime.now().add(_defaultTtl),
    );
    _pruneIfNeeded(_albumCache);
  }

  /// Get a cached album
  oaq.AlbumModel? getCachedAlbum(int id) {
    final entry = _albumCache[id];
    if (entry == null) return null;
    if (entry.isExpired) {
      _albumCache.remove(id);
      return null;
    }
    return entry.data;
  }

  /// Get cache statistics
  Map<String, int> getCacheStats() {
    return {
      'songs': _songCache.length,
      'artists': _artistCache.length,
      'albums': _albumCache.length,
    };
  }

  /// Prune cache if it exceeds max size
  void _pruneIfNeeded<T>(Map<int, _CacheEntry<T>> cache) {
    if (cache.length > _maxCacheSize) {
      // Remove oldest entries
      final toRemove = cache.length - _maxCacheSize;
      final entries = cache.entries.toList()
        ..sort((a, b) => a.value.expiresAt.compareTo(b.value.expiresAt));
      for (int i = 0; i < toRemove; i++) {
        cache.remove(entries[i].key);
      }
      debugPrint('[METADATA_CACHE] Pruned $toRemove entries from cache');
    }
  }

  /// Clear all caches
  void clear() {
    _songCache.clear();
    _artistCache.clear();
    _albumCache.clear();
    debugPrint('[METADATA_CACHE] All caches cleared');
  }

  /// Print cache statistics
  void printStats() {
    final stats = getCacheStats();
    debugPrint('=== METADATA CACHE STATS ===');
    debugPrint('Songs: ${stats['songs']}');
    debugPrint('Artists: ${stats['artists']}');
    debugPrint('Albums: ${stats['albums']}');
    debugPrint('============================');
  }
}

/// Internal cache entry with TTL
class _CacheEntry<T> {
  final T data;
  final DateTime expiresAt;

  _CacheEntry({required this.data, required this.expiresAt});

  bool get isExpired => DateTime.now().isAfter(expiresAt);
}
