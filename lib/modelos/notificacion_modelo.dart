import 'package:cloud_firestore/cloud_firestore.dart';

/// Notificación push / in-app dirigida a un usuario.
class NotificacionModel {
  final String id;
  final String userId;
  final String tipo; // reserva_confirmada | recordatorio | pago_exitoso | resena_recibida | promocion
  final String titulo;
  final String mensaje;
  final bool leida;
  final String accionPantalla; // ruta de navegación destino
  final String accionRefId;    // id del recurso referenciado
  final DateTime creadoEn;
  final DateTime? enviadoEn;
  final bool esDemo;

  const NotificacionModel({
    required this.id,
    required this.userId,
    required this.tipo,
    required this.titulo,
    required this.mensaje,
    this.leida = false,
    this.accionPantalla = '',
    this.accionRefId = '',
    required this.creadoEn,
    this.enviadoEn,
    this.esDemo = false,
  });

  factory NotificacionModel.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return NotificacionModel(
      id: doc.id,
      userId: d['userId'] as String? ?? '',
      tipo: d['tipo'] as String? ?? 'promocion',
      titulo: d['titulo'] as String? ?? '',
      mensaje: d['mensaje'] as String? ?? '',
      leida: d['leida'] as bool? ?? false,
      accionPantalla: d['accionPantalla'] as String? ?? '',
      accionRefId: d['accionRefId'] as String? ?? '',
      creadoEn: (d['creadoEn'] as Timestamp?)?.toDate() ?? DateTime.now(),
      enviadoEn: (d['enviadoEn'] as Timestamp?)?.toDate(),
      esDemo: d['esDemo'] as bool? ?? false,
    );
  }

  factory NotificacionModel.fromFirestore(DocumentSnapshot doc) =>
      NotificacionModel.fromDoc(doc);

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'tipo': tipo,
        'titulo': titulo,
        'mensaje': mensaje,
        'leida': leida,
        'accionPantalla': accionPantalla,
        'accionRefId': accionRefId,
        'creadoEn': Timestamp.fromDate(creadoEn),
        if (enviadoEn != null) 'enviadoEn': Timestamp.fromDate(enviadoEn!),
        'esDemo': esDemo,
      };

  NotificacionModel copyWith({bool? leida}) => NotificacionModel(
        id: id,
        userId: userId,
        tipo: tipo,
        titulo: titulo,
        mensaje: mensaje,
        leida: leida ?? this.leida,
        accionPantalla: accionPantalla,
        accionRefId: accionRefId,
        creadoEn: creadoEn,
        enviadoEn: enviadoEn,
        esDemo: esDemo,
      );
}
