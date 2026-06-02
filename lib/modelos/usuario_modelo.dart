import 'package:cloud_firestore/cloud_firestore.dart';

class UsuarioModel {
  final String id;
  final String nombre;
  final String email;
  final String iniciales;
  final String telefono;
  final String genero;    // "masculino" | "femenino" | "otro" | ""
  final String dni;       // 8 dígitos — solo jugadores
  final String avatarUrl;
  final String rol; // "jugador" | "dueno"

  // Solo dueños
  final String? complejoId;
  final String? nombreComplejo;
  final int numeroCanchas;
  final double? ubicacionLat;
  final double? ubicacionLng;

  const UsuarioModel({
    required this.id,
    required this.nombre,
    required this.email,
    required this.iniciales,
    required this.telefono,
    this.genero = '',
    this.dni = '',
    required this.avatarUrl,
    required this.rol,
    this.complejoId,
    this.nombreComplejo,
    this.numeroCanchas = 0,
    this.ubicacionLat,
    this.ubicacionLng,
  });

  bool get esDueno  => rol == 'dueno';
  bool get esJugador => rol == 'jugador';

  factory UsuarioModel.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return UsuarioModel(
      id:             doc.id,
      nombre:         d['nombre']         as String? ?? '',
      email:          d['email']          as String? ?? '',
      iniciales:      d['iniciales']      as String? ?? '',
      telefono:       d['telefono']       as String? ?? '',
      genero:         d['genero']         as String? ?? '',
      dni:            d['dni']            as String? ?? '',
      avatarUrl:      d['avatarUrl']      as String? ?? '',
      rol:            d['rol']            as String? ?? 'jugador',
      complejoId:     d['complejoId']     as String?,
      nombreComplejo: d['nombreComplejo'] as String?,
      numeroCanchas:  (d['numeroCanchas'] as num?)?.toInt() ?? 0,
      ubicacionLat:   (d['ubicacionLat']  as num?)?.toDouble(),
      ubicacionLng:   (d['ubicacionLng']  as num?)?.toDouble(),
    );
  }

  factory UsuarioModel.fromFirestore(DocumentSnapshot doc) =>
      UsuarioModel.fromDoc(doc);

  Map<String, dynamic> toMap() => {
    'nombre':         nombre,
    'email':          email,
    'iniciales':      iniciales,
    'telefono':       telefono,
    'genero':         genero,
    'dni':            dni,
    'avatarUrl':      avatarUrl,
    'rol':            rol,
    'complejoId':     complejoId,
    'nombreComplejo': nombreComplejo,
    'numeroCanchas':  numeroCanchas,
    if (ubicacionLat != null) 'ubicacionLat': ubicacionLat,
    if (ubicacionLng != null) 'ubicacionLng': ubicacionLng,
  };

  UsuarioModel copyWith({
    String? nombre,
    String? email,
    String? iniciales,
    String? telefono,
    String? genero,
    String? dni,
    String? avatarUrl,
    String? complejoId,
    String? nombreComplejo,
    int?    numeroCanchas,
    double? ubicacionLat,
    double? ubicacionLng,
  }) => UsuarioModel(
    id:             id,
    nombre:         nombre         ?? this.nombre,
    email:          email          ?? this.email,
    iniciales:      iniciales      ?? this.iniciales,
    telefono:       telefono       ?? this.telefono,
    genero:         genero         ?? this.genero,
    dni:            dni            ?? this.dni,
    avatarUrl:      avatarUrl      ?? this.avatarUrl,
    rol:            rol,
    complejoId:     complejoId     ?? this.complejoId,
    nombreComplejo: nombreComplejo ?? this.nombreComplejo,
    numeroCanchas:  numeroCanchas  ?? this.numeroCanchas,
    ubicacionLat:   ubicacionLat   ?? this.ubicacionLat,
    ubicacionLng:   ubicacionLng   ?? this.ubicacionLng,
  );
}
