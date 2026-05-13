import 'dart:convert';

class SongMetadata {
  final String id;
  final int? rating;
  final String? lyrics;
  final int playCount;
  final DateTime? lastPlayed;
  final double? bpm;
  final String? key;
  final String? dnaSignature;
  final String? bpmSource;
  final double? bpmConfidence;
  final String? keySource;
  final bool isManualDna;

  const SongMetadata({
    required this.id,
    this.rating,
    this.lyrics,
    this.playCount = 0,
    this.lastPlayed,
    this.bpm,
    this.key,
    this.dnaSignature,
    this.bpmSource,
    this.bpmConfidence,
    this.keySource,
    this.isManualDna = false,
  });

  SongMetadata copyWith({
    int? rating,
    String? lyrics,
    int? playCount,
    DateTime? lastPlayed,
    double? bpm,
    String? key,
    String? dnaSignature,
    String? bpmSource,
    double? bpmConfidence,
    String? keySource,
    bool? isManualDna,
  }) {
    return SongMetadata(
      id: id,
      rating: rating ?? this.rating,
      lyrics: lyrics ?? this.lyrics,
      playCount: playCount ?? this.playCount,
      lastPlayed: lastPlayed ?? this.lastPlayed,
      bpm: bpm ?? this.bpm,
      key: key ?? this.key,
      dnaSignature: dnaSignature ?? this.dnaSignature,
      bpmSource: bpmSource ?? this.bpmSource,
      bpmConfidence: bpmConfidence ?? this.bpmConfidence,
      keySource: keySource ?? this.keySource,
      isManualDna: isManualDna ?? this.isManualDna,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'rating': rating,
      'lyrics': lyrics,
      'playCount': playCount,
      'lastPlayed': lastPlayed?.toIso8601String(),
      'bpm': bpm,
      'key': key,
      'dnaSignature': dnaSignature,
      'bpmSource': bpmSource,
      'bpmConfidence': bpmConfidence,
      'keySource': keySource,
      'isManualDna': isManualDna,
    };
  }

  factory SongMetadata.fromMap(Map<String, dynamic> map) {
    double? asDouble(Object? value) {
      if (value is num) return value.toDouble();
      return null;
    }

    return SongMetadata(
      id: map['id'] as String,
      rating: map['rating'] as int?,
      lyrics: map['lyrics'] as String?,
      playCount: (map['playCount'] as int?) ?? 0,
      lastPlayed:
          map['lastPlayed'] != null
              ? DateTime.tryParse(map['lastPlayed'] as String)
              : null,
      bpm: asDouble(map['bpm']),
      key: map['key'] as String?,
      dnaSignature: map['dnaSignature'] as String?,
      bpmSource: map['bpmSource'] as String?,
      bpmConfidence: asDouble(map['bpmConfidence']),
      keySource: map['keySource'] as String?,
      isManualDna: (map['isManualDna'] as bool?) ?? false,
    );
  }

  String toJson() => json.encode(toMap());

  factory SongMetadata.fromJson(String source) =>
      SongMetadata.fromMap(json.decode(source) as Map<String, dynamic>);
}
