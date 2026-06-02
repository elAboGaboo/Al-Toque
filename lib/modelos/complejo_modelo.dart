import 'package:cloud_firestore/cloud_firestore.dart';

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
  });

  factory ComplejoModel.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return ComplejoModel(
      id:              doc.id,
      nombre:          d['nombre']          as String? ?? '',
      descripcion:     d['descripcion']     as String? ?? '',
      direccion:       d['direccion']       as String? ?? '',
      ciudad:          d['ciudad']          as String? ?? 'Huancayo',
      lat:             (d['lat']            as num?)?.toDouble() ?? 0,
      lng:             (d['lng']            as num?)?.toDouble() ?? 0,
      horarioApertura: d['horarioApertura'] as String? ?? '07:00',
      horarioCierre:   d['horarioCierre']   as String? ?? '23:00',
      imagenes:        List<String>.from(d['imagenes'] as List? ?? []),
      duenoUid:        d['duenoUid']        as String? ?? '',
      activo:          d['activo']          as bool?   ?? true,
      numeroCanchas:   (d['numeroCanchas']  as num?)?.toInt() ?? 0,
      precioMin:       (d['precioMin']      as num?)?.toDouble() ?? 0,
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
      );
}
