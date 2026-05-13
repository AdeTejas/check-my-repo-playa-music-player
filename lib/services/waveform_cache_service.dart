import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

class WaveformCacheService {
  WaveformCacheService._();
  static final WaveformCacheService instance = WaveformCacheService._();

  static const int _maxMemoryEntries = 120;
  static const int _maxDiskFiles = 350;
  static const int _samples = 100;

  final Map<String, List<double>> _memory = <String, List<double>>{};
  final Map<String, Future<List<double>>> _inflight =
      <String, Future<List<double>>>{};

  Directory? _diskDir;
  int _writes = 0;

  Future<List<double>> getWaveform(String path) {
    final key = _keyForPath(path);
    final cached = _memory.remove(key);
    if (cached != null) {
      _memory[key] = cached;
      return Future.value(cached);
    }

    final inflight = _inflight[key];
    if (inflight != null) return inflight;

    final future = () async {
      final disk = await _readDisk(key);
      if (disk != null) {
        _putMemory(key, disk);
        return disk;
      }

      final data = _generateOrganicWaveform(path);
      _putMemory(key, data);
      unawaited(_writeDisk(key, data));
      return data;
    }();

    _inflight[key] = future;
    return future.whenComplete(() => _inflight.remove(key));
  }

  String _keyForPath(String path) => base64UrlEncode(utf8.encode(path));

  void _putMemory(String key, List<double> data) {
    _memory[key] = List<double>.unmodifiable(data);
    while (_memory.length > _maxMemoryEntries) {
      _memory.remove(_memory.keys.first);
    }
  }

  Future<Directory?> _ensureDiskDir() async {
    if (kIsWeb) return null;
    if (_diskDir != null) return _diskDir;
    try {
      final base = await getTemporaryDirectory();
      final dir = Directory(
        '${base.path}${Platform.pathSeparator}waveform_cache',
      );
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      _diskDir = dir;
      return dir;
    } catch (_) {
      return null;
    }
  }

  Future<List<double>?> _readDisk(String key) async {
    final dir = await _ensureDiskDir();
    if (dir == null) return null;
    try {
      final file = File('${dir.path}${Platform.pathSeparator}$key.json');
      if (!await file.exists()) return null;
      final decoded = json.decode(await file.readAsString());
      if (decoded is! List) return null;
      final data = decoded
          .map((v) => v is num ? v.toDouble().clamp(0.05, 1.0) : 0.05)
          .toList(growable: false);
      return data.length == _samples ? data : null;
    } catch (_) {
      return null;
    }
  }

  Future<void> _writeDisk(String key, List<double> data) async {
    final dir = await _ensureDiskDir();
    if (dir == null) return;
    try {
      final file = File('${dir.path}${Platform.pathSeparator}$key.json');
      if (await file.exists()) return;
      await file.writeAsString(json.encode(data), flush: false);
      _writes++;
      if (_writes % 30 == 0) unawaited(_pruneDisk(dir));
    } catch (_) {
      // Best-effort cache.
    }
  }

  Future<void> _pruneDisk(Directory dir) async {
    try {
      final files =
          await dir
              .list(followLinks: false)
              .where((e) => e is File)
              .cast<File>()
              .toList();
      if (files.length <= _maxDiskFiles) return;
      files.sort(
        (a, b) => a.lastModifiedSync().compareTo(b.lastModifiedSync()),
      );
      for (var i = 0; i < files.length - _maxDiskFiles; i++) {
        try {
          await files[i].delete();
        } catch (_) {}
      }
    } catch (_) {}
  }

  List<double> _generateOrganicWaveform(String path) {
    final rnd = Random(path.hashCode);
    final data = <double>[];

    for (var i = 0; i < _samples; i++) {
      final t = i / _samples;
      var envelope = 1.0;
      if (t < 0.1) {
        envelope = t * 10.0;
      } else if (t > 0.9) {
        envelope = (1.0 - t) * 10.0;
      }

      var val = 0.3;
      val += 0.2 * sin(t * 15 + rnd.nextDouble());
      val += 0.1 * sin(t * 40 + rnd.nextDouble());
      val += 0.05 * sin(t * 80 + rnd.nextDouble());
      if (i % 4 == 0) val += 0.15 * rnd.nextDouble();
      if ((t > 0.3 && t < 0.45) || (t > 0.7 && t < 0.85)) {
        val *= 1.4;
      }

      data.add((val * envelope).clamp(0.05, 1.0));
    }

    return List<double>.unmodifiable(data);
  }
}
