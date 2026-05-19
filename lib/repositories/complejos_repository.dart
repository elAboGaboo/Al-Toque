// repositories/complejos_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/constants/firestore_paths.dart';
import '../models/cancha_model.dart';
import '../models/complejo_model.dart';

class ComplejosRepository {
  final _db = FirebaseFirestore.instance;

  /// Stream de todos los complejos activos desde Firestore.
  /// Solo filtra por 'activo' (índice de campo único — sin índice compuesto).
  /// Ordena por rating en el cliente para evitar un orderBy compuesto.
  Stream<List<ComplejoModel>> streamComplejos() {
    return _db
        .collection(FirestorePaths.complejos)
        .where('activo', isEqualTo: true)
        .snapshots()
        .map((s) {
      final reales = s.docs.map(ComplejoModel.fromFirestore).toList();
      reales.sort((a, b) => b.rating.compareTo(a.rating));
      return reales;
    });
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

  /// Stream de canchas activas de un complejo.
  /// Filtra client-side para evitar necesidad de índice compuesto
  /// y comportamientos inesperados en subcollections vacías.
  Stream<List<CanchaModel>> streamCanchas(String complejoId) {
    return _db
        .collection(FirestorePaths.canchas(complejoId))
        .snapshots()
        .map((s) => s.docs
            .map((d) => CanchaModel.fromFirestore(d, complejoId: complejoId))
            .where((c) => c.activa)
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

  /// Crea un complejo nuevo con ID auto-generado por Firestore. Devuelve el ID.
  Future<String> crearComplejoNuevo(ComplejoModel complejo) async {
    final docRef = _db.collection(FirestorePaths.complejos).doc();
    await docRef.set({
      ...complejo.toMap(),
      'creadoEn': FieldValue.serverTimestamp(),
    });
    return docRef.id;
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

  /// Devuelve complejos activos que aún no tienen admin asignado.
  Future<List<ComplejoModel>> getComplejosLibres() async {
    final snap = await _db
        .collection(FirestorePaths.complejos)
        .where('activo', isEqualTo: true)
        .get();
    return snap.docs
        .map(ComplejoModel.fromFirestore)
        .where((c) => c.duenoUid.isEmpty)
        .toList();
  }

  /// Asigna un admin a un complejo existente.
  Future<void> asignarAdmin(String complejoId, String uid) async {
    await _db
        .doc(FirestorePaths.complejoDoc(complejoId))
        .update({'duenoUid': uid});
  }

  // ── CRUD Canchas ───────────────────────────────────────────────

  /// Crea una cancha nueva. Devuelve el ID generado.
  Future<String> crearCancha(
      String complejoId, CanchaModel cancha) async {
    final docRef =
        _db.collection(FirestorePaths.canchas(complejoId)).doc();
    await docRef.set({
      ...cancha.toMap(),
      'complejoId': complejoId, // redundancia explícita
      'creadoEn': FieldValue.serverTimestamp(),
    });
    return docRef.id;
  }

  /// Guarda cambios en una cancha existente.
  Future<void> guardarCancha(
      String complejoId, CanchaModel cancha) async {
    await _db
        .doc(FirestorePaths.canchaDoc(complejoId, cancha.id))
        .set(cancha.toMap(), SetOptions(merge: true));
  }

  /// Activa o desactiva una cancha.
  Future<void> toggleCanchaActiva(
      String complejoId, String canchaId, bool activa) async {
    await _db
        .doc(FirestorePaths.canchaDoc(complejoId, canchaId))
        .update({'activa': activa});
  }

  /// Elimina permanentemente una cancha.
  Future<void> eliminarCancha(
      String complejoId, String canchaId) async {
    await _db
        .doc(FirestorePaths.canchaDoc(complejoId, canchaId))
        .delete();
  }
}

