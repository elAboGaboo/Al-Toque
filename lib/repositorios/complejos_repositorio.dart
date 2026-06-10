// repositories/complejos_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../nucleo/constantes/firestore_rutas.dart';
import '../nucleo/utilidades/future_utilidades.dart';
import '../modelos/cancha_modelo.dart';
import '../modelos/complejo_modelo.dart';

class ComplejosRepository {
  final _db = FirebaseFirestore.instance;

  /// Obtiene complejos activos (one-shot).
  Future<List<ComplejoModel>> getComplejos() async {
    try {
      final snap = await conTimeoutDuro(
        _db.collection(FirestorePaths.complejos).get(),
        const Duration(seconds: 10),
        error: Exception('timeout: el servidor no respondió en 10 s.'),
      );
      final lista = snap.docs
          .map(ComplejoModel.fromFirestore)
          .where((c) => c.activo)
          .toList();
      lista.sort((a, b) => a.nombre.compareTo(b.nombre));
      return lista;
    } on FirebaseException catch (e) {
      throw Exception('[${e.code}] ${e.message ?? "Error de Firestore"}');
    } catch (e) {
      throw Exception('Error cargando complejos: $e');
    }
  }

  /// Stream de todos los complejos activos desde Firestore (doc raíz).
  Stream<List<ComplejoModel>> streamComplejos() {
    return _db.collection(FirestorePaths.complejos).snapshots().map((s) {
      final reales = s.docs
          .map(ComplejoModel.fromFirestore)
          .where((c) => c.activo)
          .toList();
      reales.sort((a, b) => a.nombre.compareTo(b.nombre));
      return reales;
    });
  }

  /// Stream de un complejo específico (doc raíz — seguro en Android).
  Stream<ComplejoModel?> streamComplejo(String complejoId) {
    return _db
        .doc(FirestorePaths.complejoDoc(complejoId))
        .snapshots()
        .map((s) => s.exists ? ComplejoModel.fromFirestore(s) : null);
  }

  /// Obtiene un complejo por ID (doc raíz).
  Future<ComplejoModel?> getComplejo(String complejoId) async {
    debugPrint('[Repo] getComplejo($complejoId)');
    try {
      final doc = await conTimeoutDuro(
        _db.doc(FirestorePaths.complejoDoc(complejoId)).get(),
        const Duration(seconds: 8),
        error: Exception('timeout: Firestore no respondió en 8 s.'),
      );
      if (!doc.exists) return null;
      return ComplejoModel.fromFirestore(doc);
    } on Exception {
      rethrow;
    } catch (e) {
      throw Exception('Error al cargar complejo: $e');
    }
  }

  /// Carga robusta para la pantalla de detalle del jugador.
  ///
  /// 1. Lee el documento raíz con timeout duro.
  /// 2. Si `canchasActivas` ya existe, retorna de inmediato.
  /// 3. Si está vacío pero la subcolección sí tiene datos, la usa como fallback
  ///    y re-publica `canchasActivas` para reparar el documento raíz.
  Future<ComplejoModel?> getComplejoParaDetalleJugador(String complejoId) async {
    final complejo = await getComplejo(complejoId);
    if (complejo == null) return null;
    if (complejo.canchasActivas.isNotEmpty) return complejo;

    // IMPORTANTE (Android):
    // En algunos dispositivos/SDKs, leer la subcolección de canchas desde el
    // flujo del jugador puede provocar "congelamiento" (ANR) al abrir el detalle.
    // Por eso, para jugador devolvemos el doc raíz tal cual y dejamos la
    // publicación/migración de canchasActivas para el panel de dueño (botón
    // "Publicar canchas para jugadores").
    if (defaultTargetPlatform == TargetPlatform.android) {
      debugPrint(
        '[Repo] getComplejoParaDetalleJugador($complejoId) → Android: se omite fallback a subcolección',
      );
      return complejo;
    }

    debugPrint(
      '[Repo] getComplejoParaDetalleJugador($complejoId) → sin canchasActivas, probando fallback');

    try {
      final canchasFallback = await _getCanchasFallback(complejoId: complejoId);
      if (canchasFallback.isEmpty) return complejo;

      await publicarStatsCanchas(
        complejoId,
        canchasFallback,
        duenoUid: complejo.duenoUid,
      );

      final precioMin = canchasFallback
          .map((c) => c.precioBase)
          .reduce((a, b) => a < b ? a : b);

      return complejo.copyWith(
        numeroCanchas: canchasFallback.length,
        precioMin: precioMin,
        canchasActivas: canchasFallback,
      );
    } catch (e) {
      debugPrint(
        '[Repo] getComplejoParaDetalleJugador($complejoId) fallback error: $e');
      return complejo;
    }
  }

  /// Canchas para jugadores — SOLO lee el doc raíz (canchasActivas).
  /// Nunca consulta la subcolección: en Android bloquea el hilo y cuelga la app.
  Future<List<CanchaModel>> getCanchasParaDetalle(String complejoId) async {
    debugPrint('[Repo] getCanchasParaDetalle($complejoId)');
    final complejo = await getComplejo(complejoId);
    if (complejo == null) return [];
    debugPrint(
        '[Repo] getCanchasParaDetalle → ${complejo.canchasActivas.length} (doc raíz)');
    return complejo.canchasActivas;
  }

  /// Stream de canchas activas — solo para admin (puede ser lento en Android).
  Stream<List<CanchaModel>> streamCanchas(String complejoId) {
    return streamCanchasAdmin(complejoId).map(
      (lista) => lista.where((c) => c.activa).toList(),
    );
  }

  /// Obtiene canchas desde subcolección — SOLO admin / migración manual.
  Future<List<CanchaModel>> getCanchas(String complejoId) async {
    debugPrint('[Repo] getCanchas subcolección ($complejoId)');
    try {
      final snap = await conTimeoutDuro(
        _db.collection(FirestorePaths.canchas(complejoId)).get(),
        const Duration(seconds: 10),
        error: Exception('timeout: el servidor no respondió en 10 s.'),
      );
      return snap.docs
          .map((d) => CanchaModel.fromFirestore(d, complejoId: complejoId))
          .where((c) => c.activa)
          .toList();
    } on FirebaseException catch (e) {
      throw Exception('[${e.code}] ${e.message ?? "Error de Firestore"}');
    } catch (e) {
      throw Exception('Error cargando canchas: $e');
    }
  }

  /// Fallback puntual para detalle del jugador cuando `canchasActivas`
  /// todavía no fue publicado en el doc raíz.
  Future<List<CanchaModel>> _getCanchasFallback({
    required String complejoId,
  }) async {
    final snap = await conTimeoutDuro(
      _db.collection(FirestorePaths.canchas(complejoId)).get(),
      const Duration(seconds: 4),
      error: Exception('timeout: fallback de canchas no respondió en 4 s.'),
    );

    return snap.docs
        .map((d) => CanchaModel.fromFirestore(d, complejoId: complejoId))
        .where((c) => c.activa)
        .toList();
  }

  /// Stream admin de canchas — incluye activas E inactivas.
  Stream<List<CanchaModel>> streamCanchasAdmin(String complejoId) {
    return _db
        .collection(FirestorePaths.canchas(complejoId))
        .snapshots()
        .map((s) => s.docs
            .map((d) => CanchaModel.fromFirestore(d, complejoId: complejoId))
            .toList());
  }

  /// Obtiene una cancha por ID (doc individual en subcolección).
  Future<CanchaModel?> getCancha(String complejoId, String canchaId) async {
    try {
      // Primero: canchasActivas del doc raíz (rápido, no cuelga).
      final complejo = await getComplejo(complejoId);
      if (complejo != null) {
        for (final c in complejo.canchasActivas) {
          if (c.id == canchaId) return c;
        }
      }
      // Fallback admin/deep-link: doc individual.
      final doc = await conTimeoutDuro(
        _db.doc(FirestorePaths.canchaDoc(complejoId, canchaId)).get(),
        const Duration(seconds: 8),
        error: Exception('timeout: Firestore no respondió en 8 s.'),
      );
      if (!doc.exists) return null;
      return CanchaModel.fromFirestore(doc, complejoId: complejoId);
    } on FirebaseException catch (e) {
      throw Exception('[${e.code}] ${e.message ?? "Error de Firestore"}');
    } catch (e) {
      throw Exception('Error cargando cancha: $e');
    }
  }

  Future<String> crearComplejoNuevo(ComplejoModel complejo) async {
    final docRef = _db.collection(FirestorePaths.complejos).doc();
    await docRef.set({
      ...complejo.toMap(),
      'numeroCanchas': 0,
      'precioMin': 0,
      'canchasActivas': <Map<String, dynamic>>[],
      'creadoEn': FieldValue.serverTimestamp(),
    });
    return docRef.id;
  }

  Future<void> guardarComplejo(ComplejoModel complejo) async {
    await _db
        .doc(FirestorePaths.complejoDoc(complejo.id))
        .set(complejo.toMap(), SetOptions(merge: true));

    if (complejo.duenoUid.isNotEmpty) {
      await _db.collection('usuarios').doc(complejo.duenoUid).update({
        'nombreComplejo': complejo.nombre,
        'ubicacionLat': complejo.lat,
        'ubicacionLng': complejo.lng,
      });
    }
  }

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

  Future<void> asignarAdmin(String complejoId, String uid) async {
    await _db
        .doc(FirestorePaths.complejoDoc(complejoId))
        .update({'duenoUid': uid});
  }

  // ── CRUD Canchas ───────────────────────────────────────────────

  /// Crea cancha y actualiza canchasActivas en el doc raíz sin re-leer subcolección.
  Future<String> crearCancha(String complejoId, CanchaModel cancha) async {
    final docRef = _db.collection(FirestorePaths.canchas(complejoId)).doc();
    final id = docRef.id;

    await docRef.set({
      ...cancha.toMap(),
      'complejoId': complejoId,
      'creadoEn': FieldValue.serverTimestamp(),
    });

    final nueva = CanchaModel(
      id: id,
      complejoId: complejoId,
      nombre: cancha.nombre,
      deporte: cancha.deporte,
      superficie: cancha.superficie,
      capacidad: cancha.capacidad,
      precioBase: cancha.precioBase,
      activa: cancha.activa,
      techada: cancha.techada,
      iluminacion: cancha.iluminacion,
      descripcion: cancha.descripcion,
    );
    await _upsertCanchaEnDoc(complejoId, nueva);
    return id;
  }

  Future<void> guardarCancha(String complejoId, CanchaModel cancha) async {
    await _db
        .doc(FirestorePaths.canchaDoc(complejoId, cancha.id))
        .set(cancha.toMap(), SetOptions(merge: true));
    await _upsertCanchaEnDoc(complejoId, cancha);
  }

  Future<void> toggleCanchaActiva(
      String complejoId, String canchaId, bool activa) async {
    await _db
        .doc(FirestorePaths.canchaDoc(complejoId, canchaId))
        .update({'activa': activa});

    final complejo = await getComplejo(complejoId);
    if (complejo == null) return;
    final existente = complejo.canchasActivas
        .where((c) => c.id == canchaId)
        .firstOrNull;
    if (existente != null) {
      await _upsertCanchaEnDoc(complejoId, existente.copyWith(activa: activa));
    }
  }

  Future<void> eliminarCancha(String complejoId, String canchaId) async {
    await _db.doc(FirestorePaths.canchaDoc(complejoId, canchaId)).delete();
    await _eliminarCanchaDelDoc(complejoId, canchaId);
  }

  /// Migración manual (admin): lee subcolección y publica canchasActivas.
  /// Solo para complejos antiguos sin datos desnormalizados.
  Future<void> sincronizarCanchasComplejo(String complejoId) async {
    debugPrint('[Repo] sincronizarCanchasComplejo($complejoId)');
    try {
      final canchas = await getCanchas(complejoId);
      await publicarStatsCanchas(complejoId, canchas);
    } catch (e) {
      debugPrint('[Repo] sincronizarCanchasComplejo error: $e');
      rethrow;
    }
  }

  Future<void> publicarStatsCanchas(
    String complejoId,
    List<CanchaModel> canchasActivas, {
    String? duenoUid,
  }) async {
    final count = canchasActivas.length;
    final precioMin = canchasActivas.isEmpty
        ? 0.0
        : canchasActivas
            .map((c) => c.precioBase)
            .reduce((a, b) => a < b ? a : b);

    await _db.doc(FirestorePaths.complejoDoc(complejoId)).set({
      'numeroCanchas': count,
      'precioMin': precioMin,
      'canchasActivas': canchasActivas.map((c) => c.toResumenMap()).toList(),
    }, SetOptions(merge: true));

    final uid = duenoUid ??
        (await getComplejo(complejoId))?.duenoUid ??
        '';
    if (uid.isNotEmpty) {
      await _db.collection('usuarios').doc(uid).set({
        'numeroCanchas': count,
      }, SetOptions(merge: true));
    }
  }

  /// Agrega o actualiza una cancha en canchasActivas del doc raíz.
  Future<void> _upsertCanchaEnDoc(String complejoId, CanchaModel cancha) async {
    final complejo = await getComplejo(complejoId);
    if (complejo == null) return;

    final lista = List<CanchaModel>.from(complejo.canchasActivas)
      ..removeWhere((c) => c.id == cancha.id);
    if (cancha.activa) lista.add(cancha);

    await publicarStatsCanchas(
      complejoId,
      lista,
      duenoUid: complejo.duenoUid,
    );
    debugPrint('[Repo] _upsertCanchaEnDoc($complejoId) → ${lista.length} activas');
  }

  /// Elimina una cancha de canchasActivas del doc raíz.
  Future<void> _eliminarCanchaDelDoc(String complejoId, String canchaId) async {
    final complejo = await getComplejo(complejoId);
    if (complejo == null) return;

    final lista = complejo.canchasActivas
        .where((c) => c.id != canchaId)
        .toList();
    await publicarStatsCanchas(
      complejoId,
      lista,
      duenoUid: complejo.duenoUid,
    );
    debugPrint('[Repo] _eliminarCanchaDelDoc($complejoId) → ${lista.length} activas');
  }
}

extension _FirstOrNull<E> on Iterable<E> {
  E? get firstOrNull {
    final it = iterator;
    return it.moveNext() ? it.current : null;
  }
}
