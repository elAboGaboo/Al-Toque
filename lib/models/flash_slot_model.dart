import 'package:cloud_firestore/cloud_firestore.dart';

class FlashSlotModel {
  final String id;
  final String complejoId;
  final String canchaId;
  final DateTime fecha;
  final String horaInicio;
  final String horaFin;
  final double precioOriginal;
  final double precioFlash;
  final int descuentoPct;
  final DateTime expiraEn;
  final String estado;        // activo | reservado | expirado
  final int vistasCount;
  final String creadoPor;     // admin | ia_automatico
  final DateTime creadoEn;

  const FlashSlotModel({
    required this.id,
    required this.complejoId,
    required this.canchaId,
    required this.fecha,
    required this.horaInicio,
    required this.horaFin,
    required this.precioOriginal,
    required this.precioFlash,
    required this.descuentoPct,
    required this.expiraEn,
    required this.estado,
    required this.vistasCount,
    required this.creadoPor,
    required this.creadoEn,
  });

  factory FlashSlotModel.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return FlashSlotModel(
      id: doc.id,
      complejoId: d['complejoId'] as String? ?? '',
      canchaId: d['canchaId'] as String? ?? '',
      fecha: (d['fecha'] as Timestamp?)?.toDate() ?? DateTime.now(),
      horaInicio: d['horaInicio'] as String? ?? '00:00',
      horaFin: d['horaFin'] as String? ?? '01:00',
      precioOriginal: (d['precioOriginal'] as num?)?.toDouble() ?? 0,
      precioFlash: (d['precioFlash'] as num?)?.toDouble() ?? 0,
      descuentoPct: (d['descuentoPct'] as num?)?.toInt() ?? 20,
      expiraEn: (d['expiraEn'] as Timestamp?)?.toDate() ?? DateTime.now(),
      estado: d['estado'] as String? ?? 'activo',
      vistasCount: (d['vistasCount'] as num?)?.toInt() ?? 0,
      creadoPor: d['creadoPor'] as String? ?? 'admin',
      creadoEn: (d['creadoEn'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  factory FlashSlotModel.fromFirestore(DocumentSnapshot doc) =>
      FlashSlotModel.fromDoc(doc);

  Map<String, dynamic> toMap() => {
        'complejoId': complejoId,
        'canchaId': canchaId,
        'fecha': Timestamp.fromDate(fecha),
        'horaInicio': horaInicio,
        'horaFin': horaFin,
        'precioOriginal': precioOriginal,
        'precioFlash': precioFlash,
        'descuentoPct': descuentoPct,
        'expiraEn': Timestamp.fromDate(expiraEn),
        'estado': estado,
        'vistasCount': vistasCount,
        'creadoPor': creadoPor,
        'creadoEn': Timestamp.fromDate(creadoEn),
      };

  bool get isActivo => estado == 'activo' && expiraEn.isAfter(DateTime.now());

  Duration get tiempoRestante => expiraEn.difference(DateTime.now());

  String get tiempoRestanteLabel {
    final dur = tiempoRestante;
    if (dur.isNegative) return 'Expirado';
    if (dur.inHours > 0) return '${dur.inHours}h ${dur.inMinutes.remainder(60)}m';
    return '${dur.inMinutes}m';
  }
}
