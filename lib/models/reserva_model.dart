import 'package:cloud_firestore/cloud_firestore.dart';

class ReservaModel {
  final String id;
  final String complejoId;
  final String canchaId;
  final String userId;
  final DateTime fecha;
  final String horaInicio;
  final String horaFin;
  final double duracionHoras;
  final double precioTotal;
  final String estado;       // confirmada | pendiente | cancelada
  final String tipo;         // normal | flash | partido
  final String? flashSlotId;
  final String? partidoId;
  final String metodoPago;   // yape | plin | tarjeta | efectivo
  final String codigoAcceso; // UUID para QR
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
    required this.creadoEn,
  });

  bool get estaConfirmada => estado == 'confirmada';
  bool get estaPendiente => estado == 'pendiente';
  bool get estaCancelada => estado == 'cancelada';
  bool get esFlash => tipo == 'flash';
  bool get esPartido => tipo == 'partido';

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
        'creadoEn': Timestamp.fromDate(creadoEn),
      };
}
