// repositorios/notificaciones_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';

import '../nucleo/constantes/firestore_rutas.dart';
import '../modelos/notificacion_modelo.dart';

class NotificacionesRepository {
  final _db = FirebaseFirestore.instance;

  /// Crea una notificación para un usuario.
  Future<void> crear(NotificacionModel notif) async {
    await _db.collection(FirestorePaths.notificaciones).add(notif.toMap());
  }

  /// Notificaciones del usuario, más recientes primero.
  Stream<List<NotificacionModel>> streamNotificaciones(String userId) {
    return _db
        .collection(FirestorePaths.notificaciones)
        .where('userId', isEqualTo: userId)
        .orderBy('creadoEn', descending: true)
        .snapshots()
        .map((s) => s.docs.map(NotificacionModel.fromFirestore).toList());
  }

  /// Cantidad de notificaciones sin leer.
  Stream<int> streamNoLeidas(String userId) {
    return _db
        .collection(FirestorePaths.notificaciones)
        .where('userId', isEqualTo: userId)
        .where('leida', isEqualTo: false)
        .snapshots()
        .map((s) => s.docs.length);
  }

  /// Marca una notificación como leída.
  Future<void> marcarLeida(String notifId) async {
    await _db
        .doc(FirestorePaths.notificacionDoc(notifId))
        .update({'leida': true});
  }

  /// Marca todas las notificaciones del usuario como leídas.
  Future<void> marcarTodasLeidas(String userId) async {
    final snap = await _db
        .collection(FirestorePaths.notificaciones)
        .where('userId', isEqualTo: userId)
        .where('leida', isEqualTo: false)
        .get();
    final batch = _db.batch();
    for (final d in snap.docs) {
      batch.update(d.reference, {'leida': true});
    }
    await batch.commit();
  }
}
