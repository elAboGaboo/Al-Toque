// repositories/reservas_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/constants/firestore_paths.dart';
import '../models/reserva_model.dart';

class ReservasRepository {
  final _db = FirebaseFirestore.instance;

  /// Stream de reservas del día seleccionado para una cancha (tiempo real).
  Stream<List<ReservaModel>> streamReservasDelDia({
    required String complejoId,
    required String canchaId,
    required DateTime fecha,
  }) {
    final inicio = Timestamp.fromDate(
        DateTime(fecha.year, fecha.month, fecha.day));
    final fin = Timestamp.fromDate(
        DateTime(fecha.year, fecha.month, fecha.day, 23, 59, 59));

    return _db
        .collection(FirestorePaths.reservas)
        .where('complejoId', isEqualTo: complejoId)
        .where('canchaId', isEqualTo: canchaId)
        .where('fecha', isGreaterThanOrEqualTo: inicio)
        .where('fecha', isLessThanOrEqualTo: fin)
        .where('estado', whereIn: ['confirmada', 'pendiente'])
        .snapshots()
        .map((s) => s.docs.map(ReservaModel.fromFirestore).toList());
  }

  /// Stream de reservas de un usuario.
  Stream<List<ReservaModel>> streamMisReservas(String userId) {
    return _db
        .collection(FirestorePaths.reservas)
        .where('userId', isEqualTo: userId)
        .orderBy('creadoEn', descending: true)
        .snapshots()
        .map((s) => s.docs.map(ReservaModel.fromFirestore).toList());
  }

  /// Stream de reservas de un complejo (admin).
  Stream<List<ReservaModel>> streamReservasComplejo(String complejoId) {
    return _db
        .collection(FirestorePaths.reservas)
        .where('complejoId', isEqualTo: complejoId)
        .orderBy('fecha', descending: true)
        .snapshots()
        .map((s) => s.docs.map(ReservaModel.fromFirestore).toList());
  }

  /// Reservas del complejo para una fecha específica (admin).
  Stream<List<ReservaModel>> streamReservasComplejoFecha({
    required String complejoId,
    required DateTime fecha,
  }) {
    final inicio = Timestamp.fromDate(
        DateTime(fecha.year, fecha.month, fecha.day));
    final fin = Timestamp.fromDate(
        DateTime(fecha.year, fecha.month, fecha.day, 23, 59, 59));

    return _db
        .collection(FirestorePaths.reservas)
        .where('complejoId', isEqualTo: complejoId)
        .where('fecha', isGreaterThanOrEqualTo: inicio)
        .where('fecha', isLessThanOrEqualTo: fin)
        .snapshots()
        .map((s) => s.docs.map(ReservaModel.fromFirestore).toList());
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

  /// Confirma una reserva (estado → confirmada).
  Future<void> confirmarReserva(String reservaId) async {
    await _db.doc(FirestorePaths.reservaDoc(reservaId)).update({
      'estado': 'confirmada',
    });
  }
}
