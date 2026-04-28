import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/partido_model.dart';

class PartidosService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('partidos');

  Stream<List<PartidoModel>> streamPartidosAbiertos() {
    return _col
        .where('estado', isEqualTo: 'abierto')
        .orderBy('creadoEn', descending: true)
        .snapshots()
        .map((s) => s.docs.map(PartidoModel.fromDoc).toList());
  }

  Stream<PartidoModel?> streamPartido(String partidoId) {
    return _col
        .doc(partidoId)
        .snapshots()
        .map((d) => d.exists ? PartidoModel.fromDoc(d) : null);
  }

  Future<String> crearPartido(PartidoModel partido) async {
    final ref = await _col.add(partido.toMap());
    return ref.id;
  }

  /// Unirse a un partido con transacción atómica
  Future<bool> unirseAPartido({
    required String partidoId,
    required JugadorPartido jugador,
  }) async {
    bool joined = false;
    await _db.runTransaction((tx) async {
      final snap = await tx.get(_col.doc(partidoId));
      if (!snap.exists) throw Exception('Partido no encontrado');
      final partido = PartidoModel.fromDoc(snap);

      if (partido.estaCompleto) throw Exception('Partido completo');
      if (partido.jugadores.any((j) => j.userId == jugador.userId)) {
        throw Exception('Ya eres parte de este partido');
      }

      final nuevosJugadores = [...partido.jugadores, jugador];
      final updates = <String, dynamic>{
        'jugadores': nuevosJugadores.map((j) => j.toMap()).toList(),
      };

      if (nuevosJugadores.length >= partido.jugadoresNecesarios) {
        updates['estado'] = 'completo';
        updates['completadoEn'] = Timestamp.now();
      }

      tx.update(_col.doc(partidoId), updates);
      joined = true;
    });
    return joined;
  }

  Future<void> salirDePartido({
    required String partidoId,
    required String userId,
  }) async {
    await _db.runTransaction((tx) async {
      final snap = await tx.get(_col.doc(partidoId));
      if (!snap.exists) return;
      final partido = PartidoModel.fromDoc(snap);
      final actualizados =
          partido.jugadores.where((j) => j.userId != userId).toList();
      tx.update(_col.doc(partidoId), {
        'jugadores': actualizados.map((j) => j.toMap()).toList(),
        'estado': 'abierto',
      });
    });
  }
}
