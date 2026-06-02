// repositorios/chats_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';

import '../nucleo/constantes/firestore_rutas.dart';
import '../modelos/chat_modelo.dart';

class ChatsRepository {
  final _db = FirebaseFirestore.instance;

  /// Chats en los que participa el usuario, ordenados por actividad.
  Stream<List<ChatModel>> streamChats(String userId) {
    return _db
        .collection(FirestorePaths.chats)
        .where('participantes', arrayContains: userId)
        .orderBy('actualizadoEn', descending: true)
        .snapshots()
        .map((s) => s.docs.map(ChatModel.fromFirestore).toList());
  }

  /// Crea (o reutiliza) un chat para una reserva entre dos participantes.
  Future<String> crearOObtenerChat({
    required String reservaId,
    required List<String> participantes,
  }) async {
    final existentes = await _db
        .collection(FirestorePaths.chats)
        .where('reservaId', isEqualTo: reservaId)
        .limit(1)
        .get();
    if (existentes.docs.isNotEmpty) return existentes.docs.first.id;

    final ref = await _db.collection(FirestorePaths.chats).add(
      ChatModel(
        id: '',
        reservaId: reservaId,
        participantes: participantes,
        actualizadoEn: DateTime.now(),
      ).toMap(),
    );
    return ref.id;
  }

  /// Mensajes de un chat en orden cronológico.
  Stream<List<MensajeModel>> streamMensajes(String chatId) {
    return _db
        .collection(FirestorePaths.mensajes(chatId))
        .orderBy('creadoEn')
        .snapshots()
        .map((s) => s.docs.map(MensajeModel.fromFirestore).toList());
  }

  /// Envía un mensaje y actualiza el resumen del chat.
  Future<void> enviarMensaje(String chatId, MensajeModel mensaje) async {
    final batch = _db.batch();
    final msgRef = _db.collection(FirestorePaths.mensajes(chatId)).doc();
    batch.set(msgRef, mensaje.toMap());
    batch.update(_db.doc(FirestorePaths.chatDoc(chatId)), {
      'ultimoMensaje': mensaje.texto,
      'ultimoRemitente': mensaje.remitenteId,
      'actualizadoEn': FieldValue.serverTimestamp(),
      'mensajesNoLeidos': FieldValue.increment(1),
    });
    await batch.commit();
  }
}
