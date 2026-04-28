import 'package:cloud_firestore/cloud_firestore.dart';

class CanchaModel {
  final String id;
  final String complejoId;
  final String nombre;
  final String deporte;    // futbol5 | futbol7 | basquet | voley
  final String superficie; // sintetico | cemento | grass
  final int capacidad;
  final double precioBase;
  final bool activa;

  const CanchaModel({
    required this.id,
    required this.complejoId,
    required this.nombre,
    required this.deporte,
    required this.superficie,
    required this.capacidad,
    required this.precioBase,
    required this.activa,
  });

  String get deporteLabel {
    const labels = {
      'futbol5': 'Fútbol 5',
      'futbol7': 'Fútbol 7',
      'basquet': 'Básquet',
      'voley': 'Voley',
    };
    return labels[deporte] ?? deporte;
  }

  String get superficieLabel {
    const labels = {
      'sintetico': 'Sintético',
      'cemento': 'Cemento',
      'grass': 'Grass natural',
    };
    return labels[superficie] ?? superficie;
  }

  String get deporteEmoji {
    const emojis = {
      'futbol5': '⚽',
      'futbol7': '⚽',
      'basquet': '🏀',
      'voley': '🏐',
    };
    return emojis[deporte] ?? '🏟️';
  }

  factory CanchaModel.fromDoc(DocumentSnapshot doc, {String? complejoId}) {
    final d = doc.data() as Map<String, dynamic>;
    return CanchaModel(
      id: doc.id,
      complejoId: complejoId ?? d['complejoId'] as String? ?? '',
      nombre: d['nombre'] as String? ?? '',
      deporte: d['deporte'] as String? ?? 'futbol5',
      superficie: d['superficie'] as String? ?? 'sintetico',
      capacidad: (d['capacidad'] as num?)?.toInt() ?? 10,
      precioBase: (d['precioBase'] as num?)?.toDouble() ?? 0,
      activa: d['activa'] as bool? ?? true,
    );
  }

  factory CanchaModel.fromFirestore(DocumentSnapshot doc, {String? complejoId}) =>
      CanchaModel.fromDoc(doc, complejoId: complejoId);

  Map<String, dynamic> toMap() => {
        'nombre': nombre,
        'deporte': deporte,
        'superficie': superficie,
        'capacidad': capacidad,
        'precioBase': precioBase,
        'activa': activa,
      };

  CanchaModel copyWith({
    String? nombre,
    double? precioBase,
    bool? activa,
  }) =>
      CanchaModel(
        id: id,
        complejoId: complejoId,
        nombre: nombre ?? this.nombre,
        deporte: deporte,
        superficie: superficie,
        capacidad: capacidad,
        precioBase: precioBase ?? this.precioBase,
        activa: activa ?? this.activa,
      );
}
