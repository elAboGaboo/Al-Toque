import 'package:cloud_firestore/cloud_firestore.dart';

class ConfigIA {
  final bool preciosDinamicosActivo;
  final bool flashAutomaticoActivo;
  final double precioTechoMax;
  final bool notificarJugadores;

  const ConfigIA({
    this.preciosDinamicosActivo = false,
    this.flashAutomaticoActivo = false,
    this.precioTechoMax = 200,
    this.notificarJugadores = true,
  });

  factory ConfigIA.fromMap(Map<String, dynamic> d) => ConfigIA(
        preciosDinamicosActivo: d['preciosDinamicosActivo'] as bool? ?? false,
        flashAutomaticoActivo: d['flashAutomaticoActivo'] as bool? ?? false,
        precioTechoMax: (d['precioTechoMax'] as num?)?.toDouble() ?? 200,
        notificarJugadores: d['notificarJugadores'] as bool? ?? true,
      );

  Map<String, dynamic> toMap() => {
        'preciosDinamicosActivo': preciosDinamicosActivo,
        'flashAutomaticoActivo': flashAutomaticoActivo,
        'precioTechoMax': precioTechoMax,
        'notificarJugadores': notificarJugadores,
      };
}

class ComplejoModel {
  final String id;
  final String nombre;
  final String descripcion;
  final String direccion;
  final String ciudad;
  final double lat;
  final double lng;
  final double rating;
  final int totalResenias;
  final String horarioApertura;
  final String horarioCierre;
  final List<String> imagenes;
  // Servicios: 'vestuarios', 'duchas', 'cafeteria', 'estacionamiento', 'wifi', 'tribuna'
  final List<String> servicios;
  // Modo reserva: 'instantanea' | 'solicitud'
  final String modoReserva;
  final String reglas;
  final String duenoUid;
  final bool activo;
  final ConfigIA configIA;

  const ComplejoModel({
    required this.id,
    required this.nombre,
    this.descripcion = '',
    required this.direccion,
    required this.ciudad,
    required this.lat,
    required this.lng,
    required this.rating,
    required this.totalResenias,
    required this.horarioApertura,
    required this.horarioCierre,
    required this.imagenes,
    this.servicios = const [],
    this.modoReserva = 'instantanea',
    this.reglas = '',
    required this.duenoUid,
    required this.activo,
    this.configIA = const ConfigIA(),
  });

  factory ComplejoModel.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return ComplejoModel(
      id: doc.id,
      nombre: d['nombre'] as String? ?? '',
      descripcion: d['descripcion'] as String? ?? '',
      direccion: d['direccion'] as String? ?? '',
      ciudad: d['ciudad'] as String? ?? 'Huancayo',
      lat: (d['lat'] as num?)?.toDouble() ?? 0,
      lng: (d['lng'] as num?)?.toDouble() ?? 0,
      rating: (d['rating'] as num?)?.toDouble() ?? 0,
      totalResenias: (d['totalReseñas'] as num?)?.toInt() ?? 0,
      horarioApertura: d['horarioApertura'] as String? ?? '07:00',
      horarioCierre: d['horarioCierre'] as String? ?? '23:00',
      imagenes: List<String>.from(d['imagenes'] as List? ?? []),
      servicios: List<String>.from(d['servicios'] as List? ?? []),
      modoReserva: d['modoReserva'] as String? ?? 'instantanea',
      reglas: d['reglas'] as String? ?? '',
      duenoUid: d['duenoUid'] as String? ?? d['adminUid'] as String? ?? '',
      activo: d['activo'] as bool? ?? true,
      configIA: d['configIA'] != null
          ? ConfigIA.fromMap(d['configIA'] as Map<String, dynamic>)
          : const ConfigIA(),
    );
  }

  factory ComplejoModel.fromFirestore(DocumentSnapshot doc) =>
      ComplejoModel.fromDoc(doc);

  Map<String, dynamic> toMap() => {
        'nombre': nombre,
        'descripcion': descripcion,
        'direccion': direccion,
        'ciudad': ciudad,
        'lat': lat,
        'lng': lng,
        'rating': rating,
        'totalReseñas': totalResenias,
        'horarioApertura': horarioApertura,
        'horarioCierre': horarioCierre,
        'imagenes': imagenes,
        'servicios': servicios,
        'modoReserva': modoReserva,
        'reglas': reglas,
        'duenoUid': duenoUid,
        'activo': activo,
        'configIA': configIA.toMap(),
      };

  String get imagenPrincipal => imagenes.isNotEmpty ? imagenes.first : '';
  String get ratingLabel => '${rating.toStringAsFixed(1)} ★';
  bool get esInstantanea => modoReserva == 'instantanea';
  bool tieneServicio(String s) => servicios.contains(s);

  ComplejoModel copyWith({
    String? nombre,
    String? descripcion,
    String? direccion,
    String? ciudad,
    double? lat,
    double? lng,
    double? rating,
    int? totalResenias,
    String? horarioApertura,
    String? horarioCierre,
    List<String>? imagenes,
    List<String>? servicios,
    String? modoReserva,
    String? reglas,
    bool? activo,
    ConfigIA? configIA,
  }) =>
      ComplejoModel(
        id: id,
        nombre: nombre ?? this.nombre,
        descripcion: descripcion ?? this.descripcion,
        direccion: direccion ?? this.direccion,
        ciudad: ciudad ?? this.ciudad,
        lat: lat ?? this.lat,
        lng: lng ?? this.lng,
        rating: rating ?? this.rating,
        totalResenias: totalResenias ?? this.totalResenias,
        horarioApertura: horarioApertura ?? this.horarioApertura,
        horarioCierre: horarioCierre ?? this.horarioCierre,
        imagenes: imagenes ?? this.imagenes,
        servicios: servicios ?? this.servicios,
        modoReserva: modoReserva ?? this.modoReserva,
        reglas: reglas ?? this.reglas,
        duenoUid: duenoUid,
        activo: activo ?? this.activo,
        configIA: configIA ?? this.configIA,
      );
}
