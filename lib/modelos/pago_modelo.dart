import 'package:cloud_firestore/cloud_firestore.dart';

/// Registro financiero de una transacción asociada a una reserva.
class PagoModel {
  final String id;
  final String reservaId;
  final String userId;
  final String metodoPago;    // tarjeta | yape | plin | efectivo
  final String proveedorPago; // mercadopago | stripe | culqi | manual
  final String estado;        // pendiente | pagado | fallido | reembolsado
  final double monto;
  final double comision;
  final double impuesto;
  final String idTransaccion;
  final DateTime? pagadoEn;
  final DateTime creadoEn;
  final bool esDemo;

  const PagoModel({
    required this.id,
    required this.reservaId,
    required this.userId,
    required this.metodoPago,
    this.proveedorPago = 'manual',
    required this.estado,
    required this.monto,
    this.comision = 0,
    this.impuesto = 0,
    this.idTransaccion = '',
    this.pagadoEn,
    required this.creadoEn,
    this.esDemo = false,
  });

  bool get estaPagado => estado == 'pagado';

  factory PagoModel.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return PagoModel(
      id: doc.id,
      reservaId: d['reservaId'] as String? ?? '',
      userId: d['userId'] as String? ?? '',
      metodoPago: d['metodoPago'] as String? ?? 'efectivo',
      proveedorPago: d['proveedorPago'] as String? ?? 'manual',
      estado: d['estado'] as String? ?? 'pendiente',
      monto: (d['monto'] as num?)?.toDouble() ?? 0,
      comision: (d['comision'] as num?)?.toDouble() ?? 0,
      impuesto: (d['impuesto'] as num?)?.toDouble() ?? 0,
      idTransaccion: d['idTransaccion'] as String? ?? '',
      pagadoEn: (d['pagadoEn'] as Timestamp?)?.toDate(),
      creadoEn: (d['creadoEn'] as Timestamp?)?.toDate() ?? DateTime.now(),
      esDemo: d['esDemo'] as bool? ?? false,
    );
  }

  factory PagoModel.fromFirestore(DocumentSnapshot doc) => PagoModel.fromDoc(doc);

  Map<String, dynamic> toMap() => {
        'reservaId': reservaId,
        'userId': userId,
        'metodoPago': metodoPago,
        'proveedorPago': proveedorPago,
        'estado': estado,
        'monto': monto,
        'comision': comision,
        'impuesto': impuesto,
        'idTransaccion': idTransaccion,
        if (pagadoEn != null) 'pagadoEn': Timestamp.fromDate(pagadoEn!),
        'creadoEn': Timestamp.fromDate(creadoEn),
        'esDemo': esDemo,
      };

  PagoModel copyWith({
    String? estado,
    String? idTransaccion,
    DateTime? pagadoEn,
  }) =>
      PagoModel(
        id: id,
        reservaId: reservaId,
        userId: userId,
        metodoPago: metodoPago,
        proveedorPago: proveedorPago,
        estado: estado ?? this.estado,
        monto: monto,
        comision: comision,
        impuesto: impuesto,
        idTransaccion: idTransaccion ?? this.idTransaccion,
        pagadoEn: pagadoEn ?? this.pagadoEn,
        creadoEn: creadoEn,
        esDemo: esDemo,
      );
}
