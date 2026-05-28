// repositories/flash_slots_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/constants/firestore_paths.dart';
import '../models/flash_slot_model.dart';

class FlashSlotsRepository {
  final _db = FirebaseFirestore.instance;

  /// Stream de flash slots activos (no expirados).
  /// Filtra por estado y expiraEn client-side para evitar índice compuesto
  /// [estado, expiraEn]. Solo aplica .where() simple sobre 'estado'.
  Stream<List<FlashSlotModel>> streamSlotsActivos() {
    final now = DateTime.now();
    return _db
        .collection(FirestorePaths.flashSlots)
        .where('estado', isEqualTo: 'activo')
        .snapshots()
        .map((s) {
      final lista = s.docs
          .map(FlashSlotModel.fromFirestore)
          .where((sl) => sl.expiraEn.isAfter(now))
          .toList();
      lista.sort((a, b) => a.expiraEn.compareTo(b.expiraEn));
      return lista;
    });
  }

  /// Stream de flash slots de un complejo (admin).
  /// Ordena client-side para evitar índice compuesto [complejoId, creadoEn].
  Stream<List<FlashSlotModel>> streamSlotsComplejo(String complejoId) {
    return _db
        .collection(FirestorePaths.flashSlots)
        .where('complejoId', isEqualTo: complejoId)
        .snapshots()
        .map((s) {
      final lista = s.docs.map(FlashSlotModel.fromFirestore).toList();
      lista.sort((a, b) => b.creadoEn.compareTo(a.creadoEn));
      return lista;
    });
  }

  /// Crea un nuevo flash slot.
  Future<String> crearSlot(FlashSlotModel slot) async {
    final ref = _db.collection(FirestorePaths.flashSlots).doc();
    await ref.set({
      ...slot.toMap(),
      'creadoEn': FieldValue.serverTimestamp(),
      'vistasCount': 0,
    });
    return ref.id;
  }

  /// Incrementa el contador de vistas de un slot.
  Future<void> incrementarVistas(String slotId) async {
    await _db.doc(FirestorePaths.flashSlotDoc(slotId)).update({
      'vistasCount': FieldValue.increment(1),
    });
  }

  /// Marca un slot como reservado.
  Future<void> marcarReservado(String slotId) async {
    await _db.doc(FirestorePaths.flashSlotDoc(slotId)).update({
      'estado': 'reservado',
    });
  }

  /// Marca un slot como expirado.
  Future<void> marcarExpirado(String slotId) async {
    await _db.doc(FirestorePaths.flashSlotDoc(slotId)).update({
      'estado': 'expirado',
    });
  }

  /// Obtiene un slot por ID.
  Future<FlashSlotModel?> getSlot(String slotId) async {
    final doc = await _db.doc(FirestorePaths.flashSlotDoc(slotId)).get();
    if (!doc.exists) return null;
    return FlashSlotModel.fromFirestore(doc);
  }
}
