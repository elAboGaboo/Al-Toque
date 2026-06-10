import 'package:cloud_firestore/cloud_firestore.dart';

import 'cancha_modelo.dart';

class ComplejoModel {
  final String id;
  final String nombre;
  final String descripcion;
  final String direccion;
  final String ciudad;
  final double lat;
  final double lng;
  final String horarioApertura;
  final String horarioCierre;
  final List<String> imagenes;
  final String duenoUid;
  final bool activo;
  /// Número de canchas activas — guardado en el documento para no
  /// tener que cargar la subcolección en el listado.
  final int numeroCanchas;
  /// Precio mínimo entre todas las canchas (S/) — guardado para
  /// mostrar "Desde S/X" en el home sin cargar la subcolección.
  final double precioMin;
  /// Canchas activas desnormalizadas — evita leer la subcolección en detalle.
  final List<CanchaModel> canchasActivas;

  const ComplejoModel({
    required this.id,
    required this.nombre,
    this.descripcion = '',
    required this.direccion,
    required this.ciudad,
    required this.lat,
    required this.lng,
    required this.horarioApertura,
    required this.horarioCierre,
    required this.imagenes,
    required this.duenoUid,
    required this.activo,
    this.numeroCanchas = 0,
    this.precioMin = 0,
    this.canchasActivas = const [],
  });

  static List<CanchaModel> _parseCanchasActivas(
    Map<String, dynamic> d,
    String complejoId,
  ) {
    final raw = d['canchasActivas'] as List?;
    if (raw == null) return const [];
    return raw
        .whereType<Map>()
        .map(
          (e) => CanchaModel.fromMap(
            Map<String, dynamic>.from(e),
            complejoId: complejoId,
          ),
        )
        .where((c) => c.activa && c.id.isNotEmpty)
        .toList();
  }

  factory ComplejoModel.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;

    // Tolerancia a datos inconsistentes en Firestore:
    // - `imagenes` a veces llega como null / string / mapa (datos antiguos).
    // - `lat`/`lng` podrían estar como num o GeoPoint según migraciones.
    final rawImgs = d['imagenes'];
    final imagenesParsed = (rawImgs is List)
        ? rawImgs.whereType<String>().toList()
        : const <String>[];

    double parseNumOrGeo(dynamic v) {
      if (v is num) return v.toDouble();
      // GeoPoint (cloud_firestore)
      try {
        final lat = (v as dynamic).latitude;
        if (lat is num) return lat.toDouble();
      } catch (_) {}
      return 0;
    }

    return ComplejoModel(
      id:              doc.id,
      nombre:          d['nombre']          as String? ?? '',
      descripcion:     d['descripcion']     as String? ?? '',
      direccion:       d['direccion']       as String? ?? '',
      ciudad:          d['ciudad']          as String? ?? 'Huancayo',
      lat:             parseNumOrGeo(d['lat']),
      lng:             parseNumOrGeo(d['lng']),
      horarioApertura: d['horarioApertura'] as String? ?? '07:00',
      horarioCierre:   d['horarioCierre']   as String? ?? '23:00',
      imagenes:        imagenesParsed,
      duenoUid:        d['duenoUid']        as String? ?? '',
      activo:          d['activo']          as bool?   ?? true,
      numeroCanchas:   (d['numeroCanchas']  as num?)?.toInt() ?? 0,
      precioMin:       (d['precioMin']      as num?)?.toDouble() ?? 0,
      canchasActivas:  _parseCanchasActivas(d, doc.id),
    );
  }

  factory ComplejoModel.fromFirestore(DocumentSnapshot doc) =>
      ComplejoModel.fromDoc(doc);

  Map<String, dynamic> toMap() => {
    'nombre':          nombre,
    'descripcion':     descripcion,
    'direccion':       direccion,
    'ciudad':          ciudad,
    'lat':             lat,
    'lng':             lng,
    'horarioApertura': horarioApertura,
    'horarioCierre':   horarioCierre,
    'imagenes':        imagenes,
    'duenoUid':        duenoUid,
    'activo':          activo,
    'numeroCanchas':   numeroCanchas,
    'precioMin':       precioMin,
    'canchasActivas':  canchasActivas.map((c) => c.toResumenMap()).toList(),
  };

  String get imagenPrincipal => imagenes.isNotEmpty ? imagenes.first : '';

  ComplejoModel copyWith({
    String?       nombre,
    String?       descripcion,
    String?       direccion,
    String?       ciudad,
    double?       lat,
    double?       lng,
    String?       horarioApertura,
    String?       horarioCierre,
    List<String>? imagenes,
    String?       duenoUid,
    bool?         activo,
    int?          numeroCanchas,
    double?       precioMin,
    List<CanchaModel>? canchasActivas,
  }) =>
      ComplejoModel(
        id:              id,
        nombre:          nombre          ?? this.nombre,
        descripcion:     descripcion     ?? this.descripcion,
        direccion:       direccion       ?? this.direccion,
        ciudad:          ciudad          ?? this.ciudad,
        lat:             lat             ?? this.lat,
        lng:             lng             ?? this.lng,
        horarioApertura: horarioApertura ?? this.horarioApertura,
        horarioCierre:   horarioCierre   ?? this.horarioCierre,
        imagenes:        imagenes        ?? this.imagenes,
        duenoUid:        duenoUid        ?? this.duenoUid,
        activo:          activo          ?? this.activo,
        numeroCanchas:   numeroCanchas   ?? this.numeroCanchas,
        precioMin:       precioMin       ?? this.precioMin,
        canchasActivas:  canchasActivas  ?? this.canchasActivas,
      );
}
