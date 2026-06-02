// repositories/complejos_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../nucleo/constantes/firestore_rutas.dart';
import '../modelos/cancha_modelo.dart';
import '../modelos/complejo_modelo.dart';

class ComplejosRepository {
  final _db = FirebaseFirestore.instance;

  /// Obtiene complejos activos (one-shot, con timeout de 8 s).
  ///
  /// Reemplaza al StreamProvider en pantallas donde no se necesitan
  /// actualizaciones en tiempo real (p.ej. InicioScreen). Evita que el
  /// Scaffold quede en loading infinito si Firestore no responde.
  Future<List<ComplejoModel>> getComplejos() async {
    try {
      final snap = await _db
          .collection(FirestorePaths.complejos)
          .where('activo', isEqualTo: true)
          .get(const GetOptions(source: Source.server))
          .timeout(
            const Duration(seconds: 8),
            onTimeout: () => throw Exception(
              'timeout: el servidor no respondió en 8 s.',
            ),
          );
      final lista = snap.docs.map(ComplejoModel.fromFirestore).toList();
      lista.sort((a, b) => a.nombre.compareTo(b.nombre));
      return lista;
    } on FirebaseException catch (e) {
      throw Exception('[${e.code}] ${e.message ?? "Error de Firestore"}');
    } catch (e) {
      throw Exception('Error cargando complejos: $e');
    }
  }

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
      reales.sort((a, b) => a.nombre.compareTo(b.nombre));
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

  /// Obtiene un complejo por ID (one-shot, directo al servidor).
  Future<ComplejoModel?> getComplejo(String complejoId) async {
    debugPrint('[Repo] getComplejo($complejoId)');
    try {
      final doc = await _db
          .doc(FirestorePaths.complejoDoc(complejoId))
          .get(const GetOptions(source: Source.server))
          .timeout(
            const Duration(seconds: 8),
            onTimeout: () => throw Exception(
              'timeout: Firestore no respondió en 8 s.',
            ),
          );
      if (!doc.exists) return null;
      return ComplejoModel.fromFirestore(doc);
    } on Exception {
      rethrow;
    } catch (e) {
      throw Exception('Error al cargar complejo: $e');
    }
  }

  /// Stream de canchas activas de un complejo.
  /// Filtra client-side para evitar necesidad de índice compuesto
  /// y comportamientos inesperados en subcollections vacías.
  Stream<List<CanchaModel>> streamCanchas(String complejoId) {
    debugPrint('[Repo] streamCanchas → path: ${FirestorePaths.canchas(complejoId)}');
    return _db
        .collection(FirestorePaths.canchas(complejoId))
        .snapshots()
        .map((s) {
          debugPrint('[Repo] streamCanchas($complejoId): ${s.docs.length} docs, '
              'activas: ${s.docs.where((d) => (d.data()['activa'] as bool?) ?? true).length}');
          return s.docs
              .map((d) => CanchaModel.fromFirestore(d, complejoId: complejoId))
              .where((c) => c.activa)
              .toList();
        });
  }

  /// Obtiene canchas activas (one-shot).
  ///
  /// Usa .get() en lugar de .snapshots().first porque .first no cancela
  /// la suscripción al stream cuando el timeout dispara: cada reintento
  /// acumula listeners abiertos → ANR en Android → crash.
  /// Con .get() no hay suscripción de stream que cancelar.
  Future<List<CanchaModel>> getCanchas(String complejoId) async {
    debugPrint('[Repo] getCanchas($complejoId)');
    try {
      final snap = await _db
          .collection(FirestorePaths.canchas(complejoId))
          .get()
          .timeout(
            const Duration(seconds: 8),
            onTimeout: () => throw Exception(
              'timeout: el servidor no respondió en 8 s.',
            ),
          );
      debugPrint('[Repo] getCanchas → ${snap.docs.length} docs');
      return snap.docs
          .map((d) => CanchaModel.fromFirestore(d, complejoId: complejoId))
          .where((c) => c.activa)
          .toList();
    } on FirebaseException catch (e) {
      debugPrint('[Repo] getCanchas FirebaseException: code=${e.code} msg=${e.message}');
      throw Exception('[${e.code}] ${e.message ?? "Error de Firestore"}');
    } catch (e) {
      debugPrint('[Repo] getCanchas error: $e');
      throw Exception('Error cargando canchas: $e');
    }
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
  ///
  /// Usa .get() para evitar el stream-leak que ocurre con .snapshots().first
  /// cuando el timeout dispara sin cancelar la suscripción subyacente.
  Future<CanchaModel?> getCancha(String complejoId, String canchaId) async {
    try {
      final doc = await _db
          .doc(FirestorePaths.canchaDoc(complejoId, canchaId))
          .get()
          .timeout(
            const Duration(seconds: 8),
            onTimeout: () =>
                throw Exception('timeout: Firestore no respondió en 8 s.'),
          );
      if (!doc.exists) return null;
      return CanchaModel.fromFirestore(doc, complejoId: complejoId);
    } on FirebaseException catch (e) {
      throw Exception('[${e.code}] ${e.message ?? "Error de Firestore"}');
    } catch (e) {
      throw Exception('Error cargando cancha: $e');
    }
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
  /// Sincroniza automáticamente nombre y ubicación en el doc del dueño.
  Future<void> guardarComplejo(ComplejoModel complejo) async {
    await _db
        .doc(FirestorePaths.complejoDoc(complejo.id))
        .set(complejo.toMap(), SetOptions(merge: true));

    // Sincronizar campos desnormalizados en el doc del dueño
    if (complejo.duenoUid.isNotEmpty) {
      await _db.collection('usuarios').doc(complejo.duenoUid).update({
        'nombreComplejo': complejo.nombre,
        'ubicacionLat': complejo.lat,
        'ubicacionLng': complejo.lng,
      });
      debugPrint('[Repo] guardarComplejo → sync dueño ${complejo.duenoUid}');
    }
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
  /// Actualiza automáticamente `numeroCanchas` en el doc del dueño.
  Future<String> crearCancha(
      String complejoId, CanchaModel cancha) async {
    final docRef =
        _db.collection(FirestorePaths.canchas(complejoId)).doc();
    await docRef.set({
      ...cancha.toMap(),
      'complejoId': complejoId,
      'creadoEn': FieldValue.serverTimestamp(),
    });
    await _syncNumeroCanchas(complejoId);
    return docRef.id;
  }

  /// Guarda cambios en una cancha existente.
  /// Si cambia `activa`, recalcula `numeroCanchas`.
  Future<void> guardarCancha(
      String complejoId, CanchaModel cancha) async {
    await _db
        .doc(FirestorePaths.canchaDoc(complejoId, cancha.id))
        .set(cancha.toMap(), SetOptions(merge: true));
    await _syncNumeroCanchas(complejoId);
  }

  /// Activa o desactiva una cancha — recalcula `numeroCanchas`.
  Future<void> toggleCanchaActiva(
      String complejoId, String canchaId, bool activa) async {
    await _db
        .doc(FirestorePaths.canchaDoc(complejoId, canchaId))
        .update({'activa': activa});
    await _syncNumeroCanchas(complejoId);
  }

  /// Elimina permanentemente una cancha — recalcula `numeroCanchas`.
  Future<void> eliminarCancha(
      String complejoId, String canchaId) async {
    await _db
        .doc(FirestorePaths.canchaDoc(complejoId, canchaId))
        .delete();
    await _syncNumeroCanchas(complejoId);
  }

  /// Recalcula y escribe `numeroCanchas` (activas) en el doc del dueño.
  Future<void> _syncNumeroCanchas(String complejoId) async {
    try {
      final complejo = await getComplejo(complejoId);
      if (complejo == null || complejo.duenoUid.isEmpty) return;

      final snap = await _db
          .collection(FirestorePaths.canchas(complejoId))
          .where('activa', isEqualTo: true)
          .get();

      await _db.collection('usuarios').doc(complejo.duenoUid).update({
        'numeroCanchas': snap.docs.length,
      });
      debugPrint('[Repo] _syncNumeroCanchas($complejoId) → ${snap.docs.length} activas');
    } catch (e) {
      debugPrint('[Repo] _syncNumeroCanchas error: $e');
    }
  }
}

