import 'package:cloud_firestore/cloud_firestore.dart';

/// Representa una reserva de cancha en Al Toque.
///
/// Una reserva puede ser:
/// - **Normal**: Reserva directa de una cancha
/// - **Flash**: Reserva de una oferta relampago con descuento
/// - **Partido**: Reserva automática cuando un partido llena
class ReservaModel {
  /// ID único de la reserva
  final String id;

  /// ID del complejo deportivo donde está la cancha
  final String complejoId;

  /// ID de la cancha reservada
  final String canchaId;

  /// ID del usuario que realizó la reserva
  final String userId;

  /// Fecha de la reserva
  final DateTime fecha;

  /// Hora de inicio en formato HH:MM (ej: "14:00")
  final String horaInicio;

  /// Hora de fin en formato HH:MM (ej: "15:00")
  final String horaFin;

  /// Duración de la reserva en horas
  final double duracionHoras;

  /// Precio total a pagar en soles
  final double precioTotal;

  /// Estado de la reserva: "confirmada", "pendiente", "cancelada"
  final String estado;

  /// Tipo de reserva: "normal", "flash", "partido"
  final String tipo;

  /// ID del flash slot si es una reserva flash (opcional)
  final String? flashSlotId;

  /// ID del partido si es una reserva de partido (opcional)
  final String? partidoId;

  /// Método de pago: "yape", "plin", "tarjeta", "transferencia"
  final String metodoPago;

  /// Código de acceso UUID para generar QR de check-in
  final String codigoAcceso;

  /// Modo: "instantanea" (auto-confirmada) | "solicitud" (requiere aprobación del dueño)
  final String modoReserva;

  /// Estado del pago: "retenido" | "liberado" | "devuelto"
  final String estadoPago;

  /// Calificación que el jugador le da al complejo (1-5), nulo hasta post-partido
  final double? calificacionAlComplejo;

  /// Calificación que el complejo le da al jugador (1-5), nulo hasta post-partido
  final double? calificacionAlJugador;

  /// Comentario del jugador al calificar
  final String? comentarioUsuario;

  /// Timestamp de creación de la reserva
  final DateTime creadoEn;

  const ReservaModel({
    required this.id,
    required this.complejoId,
    required this.canchaId,
    required this.userId,
    required this.fecha,
    required this.horaInicio,
    required this.horaFin,
    required this.duracionHoras,
    required this.precioTotal,
    required this.estado,
    required this.tipo,
    this.flashSlotId,
    this.partidoId,
    required this.metodoPago,
    required this.codigoAcceso,
    this.modoReserva = 'instantanea',
    this.estadoPago = 'retenido',
    this.calificacionAlComplejo,
    this.calificacionAlJugador,
    this.comentarioUsuario,
    required this.creadoEn,
  });

  bool get estaConfirmada => estado == 'confirmada';
  bool get estaPendiente => estado == 'pendiente';
  bool get estaCancelada => estado == 'cancelada';
  bool get esFlash => tipo == 'flash';
  bool get esPartido => tipo == 'partido';
  bool get yaCalificada => calificacionAlComplejo != null;
  bool get pagoLiberado => estadoPago == 'liberado';

  factory ReservaModel.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return ReservaModel(
      id: doc.id,
      complejoId: d['complejoId'] as String? ?? '',
      canchaId: d['canchaId'] as String? ?? '',
      userId: d['userId'] as String? ?? '',
      fecha: (d['fecha'] as Timestamp?)?.toDate() ?? DateTime.now(),
      horaInicio: d['horaInicio'] as String? ?? '',
      horaFin: d['horaFin'] as String? ?? '',
      duracionHoras: (d['duracionHoras'] as num?)?.toDouble() ?? 1,
      precioTotal: (d['precioTotal'] as num?)?.toDouble() ?? 0,
      estado: d['estado'] as String? ?? 'pendiente',
      tipo: d['tipo'] as String? ?? 'normal',
      flashSlotId: d['flashSlotId'] as String?,
      partidoId: d['partidoId'] as String?,
      metodoPago: d['metodoPago'] as String? ?? 'yape',
      codigoAcceso: d['codigoAcceso'] as String? ?? '',
      modoReserva: d['modoReserva'] as String? ?? 'instantanea',
      estadoPago: d['estadoPago'] as String? ?? 'retenido',
      calificacionAlComplejo:
          (d['calificacionAlComplejo'] as num?)?.toDouble(),
      calificacionAlJugador:
          (d['calificacionAlJugador'] as num?)?.toDouble(),
      comentarioUsuario: d['comentarioUsuario'] as String?,
      creadoEn: (d['creadoEn'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  factory ReservaModel.fromFirestore(DocumentSnapshot doc) =>
      ReservaModel.fromDoc(doc);

  Map<String, dynamic> toMap() => {
        'complejoId': complejoId,
        'canchaId': canchaId,
        'userId': userId,
        'fecha': Timestamp.fromDate(fecha),
        'horaInicio': horaInicio,
        'horaFin': horaFin,
        'duracionHoras': duracionHoras,
        'precioTotal': precioTotal,
        'estado': estado,
        'tipo': tipo,
        if (flashSlotId != null) 'flashSlotId': flashSlotId,
        if (partidoId != null) 'partidoId': partidoId,
        'metodoPago': metodoPago,
        'codigoAcceso': codigoAcceso,
        'modoReserva': modoReserva,
        'estadoPago': estadoPago,
        if (calificacionAlComplejo != null)
          'calificacionAlComplejo': calificacionAlComplejo,
        if (calificacionAlJugador != null)
          'calificacionAlJugador': calificacionAlJugador,
        if (comentarioUsuario != null) 'comentarioUsuario': comentarioUsuario,
        'creadoEn': Timestamp.fromDate(creadoEn),
      };

  ReservaModel copyWith({
    String? complejoId,
    String? canchaId,
    String? userId,
    DateTime? fecha,
    String? horaInicio,
    String? horaFin,
    double? duracionHoras,
    double? precioTotal,
    String? estado,
    String? tipo,
    String? flashSlotId,
    String? partidoId,
    String? metodoPago,
    String? codigoAcceso,
    String? modoReserva,
    String? estadoPago,
    double? calificacionAlComplejo,
    double? calificacionAlJugador,
    String? comentarioUsuario,
    DateTime? creadoEn,
  }) =>
      ReservaModel(
        id: id,
        complejoId: complejoId ?? this.complejoId,
        canchaId: canchaId ?? this.canchaId,
        userId: userId ?? this.userId,
        fecha: fecha ?? this.fecha,
        horaInicio: horaInicio ?? this.horaInicio,
        horaFin: horaFin ?? this.horaFin,
        duracionHoras: duracionHoras ?? this.duracionHoras,
        precioTotal: precioTotal ?? this.precioTotal,
        estado: estado ?? this.estado,
        tipo: tipo ?? this.tipo,
        flashSlotId: flashSlotId ?? this.flashSlotId,
        partidoId: partidoId ?? this.partidoId,
        metodoPago: metodoPago ?? this.metodoPago,
        codigoAcceso: codigoAcceso ?? this.codigoAcceso,
        modoReserva: modoReserva ?? this.modoReserva,
        estadoPago: estadoPago ?? this.estadoPago,
        calificacionAlComplejo:
            calificacionAlComplejo ?? this.calificacionAlComplejo,
        calificacionAlJugador:
            calificacionAlJugador ?? this.calificacionAlJugador,
        comentarioUsuario: comentarioUsuario ?? this.comentarioUsuario,
        creadoEn: creadoEn ?? this.creadoEn,
      );
}
