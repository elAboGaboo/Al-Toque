import 'package:cloud_firestore/cloud_firestore.dart';

class UsuarioModel {
  final String id;
  final String nombre;
  final String email;
  final String telefono;
  final String avatarUrl;
  final String rol; // jugador | admin
  final String? complejoId; // solo si rol == admin
  final String deporteFavorito;
  final int totalReservas;
  final double totalGastado;
  final String fcmToken;
  final double? ubicacionLat;
  final double? ubicacionLng;
  final DateTime creadoEn;

  const UsuarioModel({
    required this.id,
    required this.nombre,
    required this.email,
    required this.telefono,
    required this.avatarUrl,
    required this.rol,
    this.complejoId,
    required this.deporteFavorito,
    required this.totalReservas,
    required this.totalGastado,
    required this.fcmToken,
    this.ubicacionLat,
    this.ubicacionLng,
    required this.creadoEn,
  });

  bool get esAdmin => rol == 'admin';
  bool get esJugador => rol == 'jugador';

  /// Iniciales para avatar (ej: "Carlos Mamani" → "CM")
  String get iniciales {
    final parts = nombre.trim().split(' ');
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  factory UsuarioModel.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return UsuarioModel(
      id: doc.id,
      nombre: d['nombre'] as String? ?? '',
      email: d['email'] as String? ?? '',
      telefono: d['telefono'] as String? ?? '',
      avatarUrl: d['avatarUrl'] as String? ?? '',
      rol: d['rol'] as String? ?? 'jugador',
      complejoId: d['complejoId'] as String?,
      deporteFavorito: d['deporteFavorito'] as String? ?? 'futbol5',
      totalReservas: (d['totalReservas'] as num?)?.toInt() ?? 0,
      totalGastado: (d['totalGastado'] as num?)?.toDouble() ?? 0,
      fcmToken: d['fcmToken'] as String? ?? '',
      ubicacionLat: (d['ubicacionLat'] as num?)?.toDouble(),
      ubicacionLng: (d['ubicacionLng'] as num?)?.toDouble(),
      creadoEn: (d['creadoEn'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  factory UsuarioModel.fromFirestore(DocumentSnapshot doc) =>
      UsuarioModel.fromDoc(doc);

  Map<String, dynamic> toMap() => {
        'nombre': nombre,
        'email': email,
        'telefono': telefono,
        'avatarUrl': avatarUrl,
        'rol': rol,
        if (complejoId != null) 'complejoId': complejoId,
        'deporteFavorito': deporteFavorito,
        'totalReservas': totalReservas,
        'totalGastado': totalGastado,
        'fcmToken': fcmToken,
        if (ubicacionLat != null) 'ubicacionLat': ubicacionLat,
        if (ubicacionLng != null) 'ubicacionLng': ubicacionLng,
        'creadoEn': Timestamp.fromDate(creadoEn),
      };

  UsuarioModel copyWith({
    String? nombre,
    String? telefono,
    String? avatarUrl,
    String? deporteFavorito,
    String? fcmToken,
    double? ubicacionLat,
    double? ubicacionLng,
    int? totalReservas,
    double? totalGastado,
  }) =>
      UsuarioModel(
        id: id,
        nombre: nombre ?? this.nombre,
        email: email,
        telefono: telefono ?? this.telefono,
        avatarUrl: avatarUrl ?? this.avatarUrl,
        rol: rol,
        complejoId: complejoId,
        deporteFavorito: deporteFavorito ?? this.deporteFavorito,
        totalReservas: totalReservas ?? this.totalReservas,
        totalGastado: totalGastado ?? this.totalGastado,
        fcmToken: fcmToken ?? this.fcmToken,
        ubicacionLat: ubicacionLat ?? this.ubicacionLat,
        ubicacionLng: ubicacionLng ?? this.ubicacionLng,
        creadoEn: creadoEn,
      );
}
