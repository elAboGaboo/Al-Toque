import 'package:cloud_firestore/cloud_firestore.dart';

class CanchaModel {
  final String id;
  final String complejoId;
  final String nombre;
  final String deporte;      // futbol5 | futbol7 | basquet | voley
  final String superficie;   // sintetico | cemento | grass
  final int capacidad;
  final double precioBase;
  final bool activa;
  final bool techada;        // cubierta / indoor
  final bool iluminacion;    // iluminación nocturna
  final String descripcion;

  const CanchaModel({
    required this.id,
    required this.complejoId,
    required this.nombre,
    required this.deporte,
    required this.superficie,
    required this.capacidad,
    required this.precioBase,
    required this.activa,
    this.techada = false,
    this.iluminacion = false,
    this.descripcion = '',
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
      techada: d['techada'] as bool? ?? false,
      iluminacion: d['iluminacion'] as bool? ?? false,
      descripcion: d['descripcion'] as String? ?? '',
    );
  }

  factory CanchaModel.fromFirestore(DocumentSnapshot doc, {String? complejoId}) =>
      CanchaModel.fromDoc(doc, complejoId: complejoId);

  Map<String, dynamic> toMap() => {
        'complejoId': complejoId,
        'nombre': nombre,
        'deporte': deporte,
        'superficie': superficie,
        'capacidad': capacidad,
        'precioBase': precioBase,
        'activa': activa,
        'techada': techada,
        'iluminacion': iluminacion,
        'descripcion': descripcion,
      };

  CanchaModel copyWith({
    String? nombre,
    double? precioBase,
    bool? activa,
    bool? techada,
    bool? iluminacion,
    String? descripcion,
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
        techada: techada ?? this.techada,
        iluminacion: iluminacion ?? this.iluminacion,
        descripcion: descripcion ?? this.descripcion,
      );
}
