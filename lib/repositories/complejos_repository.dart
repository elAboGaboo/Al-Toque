// repositories/complejos_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/constants/firestore_paths.dart';
import '../models/cancha_model.dart';
import '../models/complejo_model.dart';

class ComplejosRepository {
  final _db = FirebaseFirestore.instance;

  /// Stream de todos los complejos activos.
  Stream<List<ComplejoModel>> streamComplejos() {
    return _db
        .collection(FirestorePaths.complejos)
        .where('activo', isEqualTo: true)
        .snapshots()
        .map((s) => s.docs.map(ComplejoModel.fromFirestore).toList());
  }

  /// Stream de un complejo específico.
  Stream<ComplejoModel?> streamComplejo(String complejoId) {
    return _db
        .doc(FirestorePaths.complejoDoc(complejoId))
        .snapshots()
        .map((s) => s.exists ? ComplejoModel.fromFirestore(s) : null);
  }

  /// Obtiene un complejo por ID (one-shot).
  Future<ComplejoModel?> getComplejo(String complejoId) async {
    final doc = await _db.doc(FirestorePaths.complejoDoc(complejoId)).get();
    if (!doc.exists) return null;
    return ComplejoModel.fromFirestore(doc);
  }

  /// Stream de canchas de un complejo.
  Stream<List<CanchaModel>> streamCanchas(String complejoId) {
    return _db
        .collection(FirestorePaths.canchas(complejoId))
        .where('activa', isEqualTo: true)
        .snapshots()
        .map((s) => s.docs
            .map((d) => CanchaModel.fromFirestore(d, complejoId: complejoId))
            .toList());
  }

  /// Obtiene todas las canchas (incluyendo inactivas) — para admin.
  Stream<List<CanchaModel>> streamCanchasAdmin(String complejoId) {
    return _db
        .collection(FirestorePaths.canchas(complejoId))
        .snapshots()
        .map((s) => s.docs
            .map((d) => CanchaModel.fromFirestore(d, complejoId: complejoId))
            .toList());
  }

  /// Obtiene una cancha por ID (one-shot).
  Future<CanchaModel?> getCancha(String complejoId, String canchaId) async {
    final doc = await _db
        .doc(FirestorePaths.canchaDoc(complejoId, canchaId))
        .get();
    if (!doc.exists) return null;
    return CanchaModel.fromFirestore(doc, complejoId: complejoId);
  }

  /// Crea o actualiza un complejo (admin).
  Future<void> guardarComplejo(ComplejoModel complejo) async {
    await _db
        .doc(FirestorePaths.complejoDoc(complejo.id))
        .set(complejo.toMap(), SetOptions(merge: true));
  }

  /// Actualiza la configuración IA de un complejo.
  Future<void> actualizarConfigIA(
      String complejoId, ConfigIA config) async {
    await _db.doc(FirestorePaths.complejoDoc(complejoId)).update({
      'configIA': config.toMap(),
    });
  }

  /// Actualiza el rating del complejo (llamado después de nueva reseña).
  Future<void> actualizarRating(
      String complejoId, double nuevoRating, int totalResenias) async {
    await _db.doc(FirestorePaths.complejoDoc(complejoId)).update({
      'rating': nuevoRating,
      'totalReseñas': totalResenias,
    });
  }
}
