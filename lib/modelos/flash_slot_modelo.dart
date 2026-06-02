import 'package:cloud_firestore/cloud_firestore.dart';

/// Representa una oferta relampago (flash) de una cancha.
///
/// Los flash slots son ofertas con descuento por tiempo limitado
/// que pueden ser creadas manualmente por admins o automáticamente
/// por el sistema de IA para aumentar ocupación.
class FlashSlotModel {
  /// ID único del flash slot
  final String id;

  /// ID del complejo deportivo
  final String complejoId;

  /// ID de la cancha en oferta
  final String canchaId;

  /// Fecha de la oferta
  final DateTime fecha;

  /// Hora de inicio en formato HH:MM
  final String horaInicio;

  /// Hora de fin en formato HH:MM
  final String horaFin;

  /// Precio original sin descuento
  final double precioOriginal;

  /// Precio con descuento aplicado
  final double precioFlash;

  /// Porcentaje de descuento (1-99%)
  final int descuentoPct;

  /// Fecha y hora de expiración de la oferta
  final DateTime expiraEn;

  /// Estado: "activo", "reservado", "expirado"
  final String estado;

  /// Contador de vistas (usuarios que vieron la oferta)
  final int vistasCount;

  /// Quién creó la oferta: "admin" o "ia_automatico"
  final String creadoPor;

  /// Timestamp de creación del flash slot
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

  /// Crea una copia de este flash slot con campos opcionales reemplazados
  FlashSlotModel copyWith({
    String? complejoId,
    String? canchaId,
    DateTime? fecha,
    String? horaInicio,
    String? horaFin,
    double? precioOriginal,
    double? precioFlash,
    int? descuentoPct,
    DateTime? expiraEn,
    String? estado,
    int? vistasCount,
    String? creadoPor,
    DateTime? creadoEn,
  }) =>
      FlashSlotModel(
        id: id,
        complejoId: complejoId ?? this.complejoId,
        canchaId: canchaId ?? this.canchaId,
        fecha: fecha ?? this.fecha,
        horaInicio: horaInicio ?? this.horaInicio,
        horaFin: horaFin ?? this.horaFin,
        precioOriginal: precioOriginal ?? this.precioOriginal,
        precioFlash: precioFlash ?? this.precioFlash,
        descuentoPct: descuentoPct ?? this.descuentoPct,
        expiraEn: expiraEn ?? this.expiraEn,
        estado: estado ?? this.estado,
        vistasCount: vistasCount ?? this.vistasCount,
        creadoPor: creadoPor ?? this.creadoPor,
        creadoEn: creadoEn ?? this.creadoEn,
      );
}
