import 'package:cloud_firestore/cloud_firestore.dart';

/// Conversación entre jugador y dueño, normalmente ligada a una reserva.
class ChatModel {
  final String id;
  final String reservaId;
  final List<String> participantes; // uids de los participantes
  final String ultimoMensaje;
  final String ultimoRemitente;
  final int mensajesNoLeidos;
  final DateTime actualizadoEn;
  final bool esDemo;

  const ChatModel({
    required this.id,
    this.reservaId = '',
    required this.participantes,
    this.ultimoMensaje = '',
    this.ultimoRemitente = '',
    this.mensajesNoLeidos = 0,
    required this.actualizadoEn,
    this.esDemo = false,
  });

  factory ChatModel.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return ChatModel(
      id: doc.id,
      reservaId: d['reservaId'] as String? ?? '',
      participantes: List<String>.from(d['participantes'] as List? ?? []),
      ultimoMensaje: d['ultimoMensaje'] as String? ?? '',
      ultimoRemitente: d['ultimoRemitente'] as String? ?? '',
      mensajesNoLeidos: (d['mensajesNoLeidos'] as num?)?.toInt() ?? 0,
      actualizadoEn:
          (d['actualizadoEn'] as Timestamp?)?.toDate() ?? DateTime.now(),
      esDemo: d['esDemo'] as bool? ?? false,
    );
  }

  factory ChatModel.fromFirestore(DocumentSnapshot doc) => ChatModel.fromDoc(doc);

  Map<String, dynamic> toMap() => {
        'reservaId': reservaId,
        'participantes': participantes,
        'ultimoMensaje': ultimoMensaje,
        'ultimoRemitente': ultimoRemitente,
        'mensajesNoLeidos': mensajesNoLeidos,
        'actualizadoEn': Timestamp.fromDate(actualizadoEn),
        'esDemo': esDemo,
      };
}

/// Mensaje individual dentro de un chat (subcolección `mensajes`).
class MensajeModel {
  final String id;
  final String remitenteId;
  final String tipo; // texto | imagen | ubicacion | audio
  final String texto;
  final String urlImagen;
  final String urlAudio;
  final bool leido;
  final DateTime creadoEn;

  const MensajeModel({
    required this.id,
    required this.remitenteId,
    this.tipo = 'texto',
    this.texto = '',
    this.urlImagen = '',
    this.urlAudio = '',
    this.leido = false,
    required this.creadoEn,
  });

  factory MensajeModel.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return MensajeModel(
      id: doc.id,
      remitenteId: d['remitenteId'] as String? ?? '',
      tipo: d['tipo'] as String? ?? 'texto',
      texto: d['texto'] as String? ?? '',
      urlImagen: d['urlImagen'] as String? ?? '',
      urlAudio: d['urlAudio'] as String? ?? '',
      leido: d['leido'] as bool? ?? false,
      creadoEn: (d['creadoEn'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  factory MensajeModel.fromFirestore(DocumentSnapshot doc) =>
      MensajeModel.fromDoc(doc);

  Map<String, dynamic> toMap() => {
        'remitenteId': remitenteId,
        'tipo': tipo,
        'texto': texto,
        if (urlImagen.isNotEmpty) 'urlImagen': urlImagen,
        if (urlAudio.isNotEmpty) 'urlAudio': urlAudio,
        'leido': leido,
        'creadoEn': Timestamp.fromDate(creadoEn),
      };
}
