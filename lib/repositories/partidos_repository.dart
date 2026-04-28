// repositories/partidos_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/constants/firestore_paths.dart';
import '../models/partido_model.dart';

class PartidosRepository {
  final _db = FirebaseFirestore.instance;

  /// Stream de partidos abiertos (buscando jugadores).
  Stream<List<PartidoModel>> streamPartidosAbiertos() {
    return _db
        .collection(FirestorePaths.partidos)
        .where('estado', isEqualTo: 'abierto')
        .orderBy('fecha')
        .snapshots()
        .map((s) => s.docs.map(PartidoModel.fromFirestore).toList());
  }

  /// Stream de un partido específico (tiempo real).
  Stream<PartidoModel?> streamPartido(String partidoId) {
    return _db
        .doc(FirestorePaths.partidoDoc(partidoId))
        .snapshots()
        .map((s) => s.exists ? PartidoModel.fromFirestore(s) : null);
  }

  /// Stream de partidos de un usuario (como jugador u organizador).
  Stream<List<PartidoModel>> streamMisPartidos(String userId) {
    return _db
        .collection(FirestorePaths.partidos)
        .orderBy('creadoEn', descending: true)
        .snapshots()
        .map((s) => s.docs
            .map(PartidoModel.fromFirestore)
            .where((p) =>
                p.organizadorId == userId ||
                p.jugadores.any((j) => j.userId == userId))
            .toList());
  }

  /// Stream de partidos de un complejo (admin).
  Stream<List<PartidoModel>> streamPartidosComplejo(String complejoId) {
    return _db
        .collection(FirestorePaths.partidos)
        .where('complejoId', isEqualTo: complejoId)
        .orderBy('fecha', descending: true)
        .snapshots()
        .map((s) => s.docs.map(PartidoModel.fromFirestore).toList());
  }

  /// Crea un nuevo partido.
  Future<String> crearPartido(PartidoModel partido) async {
    final ref = _db.collection(FirestorePaths.partidos).doc();
    await ref.set({
      ...partido.toMap(),
      'creadoEn': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  /// Unirse a un partido (transacción atómica).
  Future<void> unirseAlPartido({
    required String partidoId,
    required JugadorPartido jugador,
  }) async {
    await _db.runTransaction((tx) async {
      final ref = _db.doc(FirestorePaths.partidoDoc(partidoId));
      final snap = await tx.get(ref);

      if (!snap.exists) throw Exception('Partido no encontrado');

      final partido = PartidoModel.fromFirestore(snap);

      if (partido.estaCompleto) {
        throw Exception('El partido ya está completo');
      }

      if (partido.jugadores.any((j) => j.userId == jugador.userId)) {
        throw Exception('Ya estás en este partido');
      }

      final nuevosJugadores = [
        ...partido.jugadores.map((j) => j.toMap()),
        {
          ...jugador.toMap(),
          'unidoEn': FieldValue.serverTimestamp(),
        },
      ];

      final nuevoTotal = nuevosJugadores.length;
      final nuevoEstado = nuevoTotal >= partido.jugadoresNecesarios
          ? 'completo'
          : 'abierto';

      tx.update(ref, {
        'jugadores': nuevosJugadores,
        'estado': nuevoEstado,
        if (nuevoEstado == 'completo')
          'completadoEn': FieldValue.serverTimestamp(),
      });
    });
  }

  /// Salir de un partido.
  Future<void> salirDelPartido({
    required String partidoId,
    required String userId,
  }) async {
    await _db.runTransaction((tx) async {
      final ref = _db.doc(FirestorePaths.partidoDoc(partidoId));
      final snap = await tx.get(ref);
      if (!snap.exists) return;

      final partido = PartidoModel.fromFirestore(snap);
      final nuevosJugadores = partido.jugadores
          .where((j) => j.userId != userId)
          .map((j) => j.toMap())
          .toList();

      tx.update(ref, {
        'jugadores': nuevosJugadores,
        'estado': 'abierto',
      });
    });
  }

  /// Cancela un partido.
  Future<void> cancelarPartido(String partidoId) async {
    await _db.doc(FirestorePaths.partidoDoc(partidoId)).update({
      'estado': 'cancelado',
    });
  }

  /// Asigna cancha y reserva a un partido completo.
  Future<void> asignarCanchaAPartido({
    required String partidoId,
    required String canchaId,
    required String complejoId,
    required String reservaId,
    required double precioPorJugador,
  }) async {
    await _db.doc(FirestorePaths.partidoDoc(partidoId)).update({
      'canchaId': canchaId,
      'complejoId': complejoId,
      'reservaId': reservaId,
      'precioFinalPorJugador': precioPorJugador,
      'estado': 'completo',
    });
  }
}
