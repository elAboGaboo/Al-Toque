// repositories/reservas_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/constants/firestore_paths.dart';
import '../models/reserva_model.dart';

class ReservasRepository {
  final _db = FirebaseFirestore.instance;

  /// Stream de reservas del día seleccionado para una cancha (tiempo real).
  /// Filtra por complejoId en Firestore, resto en cliente.
  Stream<List<ReservaModel>> streamReservasDelDia({
    required String complejoId,
    required String canchaId,
    required DateTime fecha,
  }) {
    final inicio = DateTime(fecha.year, fecha.month, fecha.day);
    final fin = DateTime(fecha.year, fecha.month, fecha.day, 23, 59, 59);

    return _db
        .collection(FirestorePaths.reservas)
        .where('complejoId', isEqualTo: complejoId)
        .snapshots()
        .map((s) => s.docs
            .map(ReservaModel.fromFirestore)
            .where((r) =>
                r.canchaId == canchaId &&
                !r.fecha.isBefore(inicio) &&
                !r.fecha.isAfter(fin) &&
                (r.estaConfirmada || r.estaPendiente))
            .toList());
  }

  /// Stream de reservas de un usuario — ordenadas client-side para evitar
  /// necesidad de índice compuesto (where + orderBy en campos distintos).
  Stream<List<ReservaModel>> streamMisReservas(String userId) {
    return _db
        .collection(FirestorePaths.reservas)
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((s) {
      final lista = s.docs.map(ReservaModel.fromFirestore).toList();
      lista.sort((a, b) => b.creadoEn.compareTo(a.creadoEn));
      return lista;
    });
  }

  /// Stream de reservas de un complejo (admin) — ordenadas client-side.
  Stream<List<ReservaModel>> streamReservasComplejo(String complejoId) {
    return _db
        .collection(FirestorePaths.reservas)
        .where('complejoId', isEqualTo: complejoId)
        .snapshots()
        .map((s) {
      final lista = s.docs.map(ReservaModel.fromFirestore).toList();
      lista.sort((a, b) => b.fecha.compareTo(a.fecha));
      return lista;
    });
  }

  /// Reservas del complejo para una fecha específica (admin).
  /// Filtra por complejoId en Firestore y por fecha en cliente
  /// para evitar requerir índices compuestos.
  Stream<List<ReservaModel>> streamReservasComplejoFecha({
    required String complejoId,
    required DateTime fecha,
  }) {
    final inicio = DateTime(fecha.year, fecha.month, fecha.day);
    final fin = DateTime(fecha.year, fecha.month, fecha.day, 23, 59, 59);

    return _db
        .collection(FirestorePaths.reservas)
        .where('complejoId', isEqualTo: complejoId)
        .snapshots()
        .map((s) => s.docs
            .map(ReservaModel.fromFirestore)
            .where((r) =>
                !r.fecha.isBefore(inicio) && !r.fecha.isAfter(fin))
            .toList());
  }

  /// Crea una reserva nueva. Retorna el ID de la reserva.
  Future<String> crearReserva(ReservaModel reserva) async {
    final ref = _db.collection(FirestorePaths.reservas).doc(reserva.id.isEmpty
        ? null
        : reserva.id);
    await ref.set({
      ...reserva.toMap(),
      'creadoEn': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  /// Obtiene una reserva por ID.
  Future<ReservaModel?> getReserva(String reservaId) async {
    final doc = await _db.doc(FirestorePaths.reservaDoc(reservaId)).get();
    if (!doc.exists) return null;
    return ReservaModel.fromFirestore(doc);
  }

  /// Stream de una reserva en tiempo real.
  Stream<ReservaModel?> streamReserva(String reservaId) {
    return _db
        .doc(FirestorePaths.reservaDoc(reservaId))
        .snapshots()
        .map((s) => s.exists ? ReservaModel.fromFirestore(s) : null);
  }

  /// Cancela una reserva (estado → cancelada).
  Future<void> cancelarReserva(String reservaId) async {
    await _db.doc(FirestorePaths.reservaDoc(reservaId)).update({
      'estado': 'cancelada',
    });
  }

  /// Confirma una reserva — usado tanto en modo instantáneo como por el dueño.
  Future<void> confirmarReserva(String reservaId) async {
    await _db.doc(FirestorePaths.reservaDoc(reservaId)).update({
      'estado': 'confirmada',
    });
  }

  /// El dueño rechaza una solicitud de reserva → estado cancelada + pago devuelto.
  Future<void> rechazarReserva(String reservaId) async {
    await _db.doc(FirestorePaths.reservaDoc(reservaId)).update({
      'estado': 'cancelada',
      'estadoPago': 'devuelto',
    });
  }

  /// Libera el pago al dueño tras confirmar que la sesión se realizó.
  Future<void> liberarPago(String reservaId) async {
    await _db.doc(FirestorePaths.reservaDoc(reservaId)).update({
      'estadoPago': 'liberado',
    });
  }

  /// El jugador califica al complejo tras la sesión.
  Future<void> calificarComplejo({
    required String reservaId,
    required double calificacion,
    String comentario = '',
  }) async {
    await _db.doc(FirestorePaths.reservaDoc(reservaId)).update({
      'calificacionAlComplejo': calificacion,
      'comentarioUsuario': comentario,
    });
  }

  /// El dueño califica al jugador tras la sesión.
  Future<void> calificarJugador({
    required String reservaId,
    required double calificacion,
  }) async {
    await _db.doc(FirestorePaths.reservaDoc(reservaId)).update({
      'calificacionAlJugador': calificacion,
    });
  }
}
