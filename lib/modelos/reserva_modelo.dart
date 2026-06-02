import 'package:cloud_firestore/cloud_firestore.dart';

/// Representa una reserva de cancha en Al Toque.
class ReservaModel {
  final String id;
  final String userId;
  final String userName;
  final String complejoId;
  final String canchaId;
  final DateTime fecha;
  final String horaInicio;   // "HH:MM"
  final String horaFin;      // "HH:MM"
  final double duracionHoras;
  final double precioTotal;
  final String estado;       // "confirmada" | "pendiente" | "cancelada"
  final String metodoPago;   // "yape" | "plin" | "tarjeta" | "transferencia"
  final String? partidoId;
  final String codigoAcceso;
  final DateTime creadoEn;

  const ReservaModel({
    required this.id,
    required this.userId,
    this.userName = '',
    required this.complejoId,
    required this.canchaId,
    required this.fecha,
    required this.horaInicio,
    required this.horaFin,
    required this.duracionHoras,
    required this.precioTotal,
    required this.estado,
    required this.metodoPago,
    this.partidoId,
    required this.codigoAcceso,
    required this.creadoEn,
  });

  bool get estaConfirmada => estado == 'confirmada';
  bool get estaPendiente  => estado == 'pendiente';
  bool get estaCancelada  => estado == 'cancelada';
  bool get esPartido      => partidoId != null;

  factory ReservaModel.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return ReservaModel(
      id:             doc.id,
      userId:         d['userId']         as String?    ?? '',
      userName:       d['userName']       as String?    ?? '',
      complejoId:     d['complejoId']     as String?    ?? '',
      canchaId:       d['canchaId']       as String?    ?? '',
      fecha:          (d['fecha']         as Timestamp?)?.toDate() ?? DateTime.now(),
      horaInicio:     d['horaInicio']     as String?    ?? '',
      horaFin:        d['horaFin']        as String?    ?? '',
      duracionHoras:  (d['duracionHoras'] as num?)?.toDouble() ?? 1,
      precioTotal:    (d['precioTotal']   as num?)?.toDouble() ?? 0,
      estado:         d['estado']         as String?    ?? 'pendiente',
      metodoPago:     d['metodoPago']     as String?    ?? 'yape',
      partidoId:      d['partidoId']      as String?,
      codigoAcceso:   d['codigoAcceso']   as String?    ?? '',
      creadoEn:       (d['creadoEn']      as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  factory ReservaModel.fromFirestore(DocumentSnapshot doc) =>
      ReservaModel.fromDoc(doc);

  Map<String, dynamic> toMap() => {
    'userId':        userId,
    'userName':      userName,
    'complejoId':    complejoId,
    'canchaId':      canchaId,
    'fecha':         Timestamp.fromDate(fecha),
    'horaInicio':    horaInicio,
    'horaFin':       horaFin,
    'duracionHoras': duracionHoras,
    'precioTotal':   precioTotal,
    'estado':        estado,
    'metodoPago':    metodoPago,
    if (partidoId != null) 'partidoId': partidoId,
    'codigoAcceso':  codigoAcceso,
    'creadoEn':      Timestamp.fromDate(creadoEn),
  };

  ReservaModel copyWith({
    String?   id,
    String?   userId,
    String?   userName,
    String?   complejoId,
    String?   canchaId,
    DateTime? fecha,
    String?   horaInicio,
    String?   horaFin,
    double?   duracionHoras,
    double?   precioTotal,
    String?   estado,
    String?   metodoPago,
    String?   partidoId,
    String?   codigoAcceso,
    DateTime? creadoEn,
  }) =>
      ReservaModel(
        id:             id             ?? this.id,
        userId:         userId         ?? this.userId,
        userName:       userName       ?? this.userName,
        complejoId:     complejoId     ?? this.complejoId,
        canchaId:       canchaId       ?? this.canchaId,
        fecha:          fecha          ?? this.fecha,
        horaInicio:     horaInicio     ?? this.horaInicio,
        horaFin:        horaFin        ?? this.horaFin,
        duracionHoras:  duracionHoras  ?? this.duracionHoras,
        precioTotal:    precioTotal    ?? this.precioTotal,
        estado:         estado         ?? this.estado,
        metodoPago:     metodoPago     ?? this.metodoPago,
        partidoId:      partidoId      ?? this.partidoId,
        codigoAcceso:   codigoAcceso   ?? this.codigoAcceso,
        creadoEn:       creadoEn       ?? this.creadoEn,
      );
}
