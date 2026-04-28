import 'package:cloud_firestore/cloud_firestore.dart';

class JugadorPartido {
  final String userId;
  final String nombre;
  final String avatarUrl;
  final String iniciales;
  final bool pagado;
  final DateTime unidoEn;

  const JugadorPartido({
    required this.userId,
    required this.nombre,
    required this.avatarUrl,
    required this.iniciales,
    required this.pagado,
    required this.unidoEn,
  });

  factory JugadorPartido.fromMap(Map<String, dynamic> m) {
    final nombre = m['nombre'] as String? ?? '';
    final iniciales = m['iniciales'] as String? ??
        _calcularIniciales(nombre);
    return JugadorPartido(
      userId: m['userId'] as String? ?? '',
      nombre: nombre,
      avatarUrl: m['avatarUrl'] as String? ?? '',
      iniciales: iniciales,
      pagado: m['pagado'] as bool? ?? false,
      unidoEn: (m['unidoEn'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'nombre': nombre,
        'avatarUrl': avatarUrl,
        'iniciales': iniciales,
        'pagado': pagado,
        'unidoEn': Timestamp.fromDate(unidoEn),
      };

  static String _calcularIniciales(String nombre) {
    final parts = nombre.trim().split(' ');
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }
}

class PartidoModel {
  final String id;
  final String organizadorId;
  final String? complejoId;    // null hasta que se asigne cancha automática
  final String? canchaId;
  final String deporte;        // futbol5 | futbol7 | basquet | voley
  final DateTime fecha;
  final String horaInicio;
  final String horaFin;
  final int jugadoresNecesarios;
  final double precioMaxPorJugador;
  final double? precioFinalPorJugador;
  final String estado;         // abierto | completo | cancelado | pendiente_cancha
  final List<JugadorPartido> jugadores;
  final String? reservaId;
  final DateTime? completadoEn;
  final DateTime creadoEn;

  const PartidoModel({
    required this.id,
    required this.organizadorId,
    this.complejoId,
    this.canchaId,
    required this.deporte,
    required this.fecha,
    required this.horaInicio,
    required this.horaFin,
    required this.jugadoresNecesarios,
    required this.precioMaxPorJugador,
    this.precioFinalPorJugador,
    required this.estado,
    required this.jugadores,
    this.reservaId,
    this.completadoEn,
    required this.creadoEn,
  });

  factory PartidoModel.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return PartidoModel(
      id: doc.id,
      organizadorId: d['organizadorId'] as String? ?? '',
      complejoId: d['complejoId'] as String?,
      canchaId: d['canchaId'] as String?,
      deporte: d['deporte'] as String? ?? 'futbol5',
      fecha: (d['fecha'] as Timestamp?)?.toDate() ?? DateTime.now(),
      horaInicio: d['horaInicio'] as String? ?? '00:00',
      horaFin: d['horaFin'] as String? ?? '01:00',
      jugadoresNecesarios:
          (d['jugadoresNecesarios'] as num?)?.toInt() ?? 10,
      precioMaxPorJugador:
          (d['precioMaxPorJugador'] as num?)?.toDouble() ?? 0,
      precioFinalPorJugador:
          (d['precioFinalPorJugador'] as num?)?.toDouble(),
      estado: d['estado'] as String? ?? 'abierto',
      jugadores: (d['jugadores'] as List? ?? [])
          .map((j) => JugadorPartido.fromMap(j as Map<String, dynamic>))
          .toList(),
      reservaId: d['reservaId'] as String?,
      completadoEn: (d['completadoEn'] as Timestamp?)?.toDate(),
      creadoEn:
          (d['creadoEn'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  factory PartidoModel.fromFirestore(DocumentSnapshot doc) =>
      PartidoModel.fromDoc(doc);

  Map<String, dynamic> toMap() => {
        'organizadorId': organizadorId,
        if (complejoId != null) 'complejoId': complejoId,
        if (canchaId != null) 'canchaId': canchaId,
        'deporte': deporte,
        'fecha': Timestamp.fromDate(fecha),
        'horaInicio': horaInicio,
        'horaFin': horaFin,
        'jugadoresNecesarios': jugadoresNecesarios,
        'precioMaxPorJugador': precioMaxPorJugador,
        if (precioFinalPorJugador != null)
          'precioFinalPorJugador': precioFinalPorJugador,
        'estado': estado,
        'jugadores': jugadores.map((j) => j.toMap()).toList(),
        if (reservaId != null) 'reservaId': reservaId,
        if (completadoEn != null)
          'completadoEn': Timestamp.fromDate(completadoEn!),
        'creadoEn': Timestamp.fromDate(creadoEn),
      };

  int get jugadoresActuales => jugadores.length;
  int get cuposDisponibles => jugadoresNecesarios - jugadoresActuales;
  double get progreso => jugadoresActuales / jugadoresNecesarios;
  bool get estaCompleto => jugadoresActuales >= jugadoresNecesarios;
  bool get estaAbierto => estado == 'abierto';
  bool get estaCancelado => estado == 'cancelado';

  String get deporteLabel => switch (deporte) {
        'futbol5' => 'Fútbol 5',
        'futbol7' => 'Fútbol 7',
        'basquet' => 'Básquet',
        'voley' => 'Voley',
        _ => deporte,
      };

  String get deporteEmoji => switch (deporte) {
        'futbol5' || 'futbol7' => '⚽',
        'basquet' => '🏀',
        'voley' => '🏐',
        _ => '🏅',
      };
}
