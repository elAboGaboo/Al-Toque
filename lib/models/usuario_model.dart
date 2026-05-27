import 'package:cloud_firestore/cloud_firestore.dart';

/// Representa un usuario de la aplicación Al Toque.
///
/// Un usuario puede ser un [jugador] que reserva canchas y crea partidos,
/// o un [admin] que gestiona un complejo deportivo.
class UsuarioModel {
  /// ID único de Firebase Authentication
  final String id;

  /// Nombre completo del usuario (máximo 200 caracteres)
  final String nombre;

  /// Email registrado en Firebase Auth
  final String email;

  /// Teléfono de contacto (WhatsApp/Llamadas)
  final String telefono;

  /// URL de foto de perfil en Firebase Storage
  final String avatarUrl;

  /// Rol del usuario: "jugador" o "admin"
  final String rol;

  /// ID del complejo que gestiona (solo si rol == "dueno")
  final String? complejoId;

  /// Lista de IDs de todos los complejos que administra
  final List<String> complejosIds;

  /// Deporte favorito: "futbol5", "futbol7", "basquet", "voley"
  final String deporteFavorito;

  /// Nivel de juego: "principiante", "intermedio", "avanzado"
  final String nivel;

  /// Total de reservas realizadas (actualizado después de cada reserva)
  final int totalReservas;

  /// Total gastado en soles (actualizado después de cada pago confirmado)
  final double totalGastado;

  /// Calificación promedio recibida de los complejos (1.0 - 5.0)
  final double calificacion;

  /// Total de calificaciones recibidas
  final int totalCalificaciones;

  /// Token FCM para notificaciones push en este dispositivo
  final String fcmToken;

  /// Latitud de última ubicación conocida (obtenida de geolocation)
  final double? ubicacionLat;

  /// Longitud de última ubicación conocida (obtenida de geolocation)
  final double? ubicacionLng;

  /// Timestamp de creación de cuenta
  final DateTime creadoEn;

  const UsuarioModel({
    required this.id,
    required this.nombre,
    required this.email,
    required this.telefono,
    required this.avatarUrl,
    required this.rol,
    this.complejoId,
    this.complejosIds = const [],
    required this.deporteFavorito,
    this.nivel = 'principiante',
    required this.totalReservas,
    required this.totalGastado,
    this.calificacion = 0,
    this.totalCalificaciones = 0,
    required this.fcmToken,
    this.ubicacionLat,
    this.ubicacionLng,
    required this.creadoEn,
  });

  bool get esDueno => rol == 'dueno';
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
      complejosIds: List<String>.from(d['complejosIds'] as List? ?? []),
      deporteFavorito: d['deporteFavorito'] as String? ?? 'futbol5',
      nivel: d['nivel'] as String? ?? 'principiante',
      totalReservas: (d['totalReservas'] as num?)?.toInt() ?? 0,
      totalGastado: (d['totalGastado'] as num?)?.toDouble() ?? 0,
      calificacion: (d['calificacion'] as num?)?.toDouble() ?? 0,
      totalCalificaciones: (d['totalCalificaciones'] as num?)?.toInt() ?? 0,
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
        'complejosIds': complejosIds,
        'deporteFavorito': deporteFavorito,
        'nivel': nivel,
        'totalReservas': totalReservas,
        'totalGastado': totalGastado,
        'calificacion': calificacion,
        'totalCalificaciones': totalCalificaciones,
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
    String? nivel,
    String? fcmToken,
    double? ubicacionLat,
    double? ubicacionLng,
    int? totalReservas,
    double? totalGastado,
    double? calificacion,
    int? totalCalificaciones,
    String? complejoId,
    List<String>? complejosIds,
  }) =>
      UsuarioModel(
        id: id,
        nombre: nombre ?? this.nombre,
        email: email,
        telefono: telefono ?? this.telefono,
        avatarUrl: avatarUrl ?? this.avatarUrl,
        rol: rol,
        complejoId: complejoId ?? this.complejoId,
        complejosIds: complejosIds ?? this.complejosIds,
        deporteFavorito: deporteFavorito ?? this.deporteFavorito,
        nivel: nivel ?? this.nivel,
        totalReservas: totalReservas ?? this.totalReservas,
        totalGastado: totalGastado ?? this.totalGastado,
        calificacion: calificacion ?? this.calificacion,
        totalCalificaciones: totalCalificaciones ?? this.totalCalificaciones,
        fcmToken: fcmToken ?? this.fcmToken,
        ubicacionLat: ubicacionLat ?? this.ubicacionLat,
        ubicacionLng: ubicacionLng ?? this.ubicacionLng,
        creadoEn: creadoEn,
      );
}
