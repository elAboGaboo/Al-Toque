// repositories/flash_slots_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/constants/firestore_paths.dart';
import '../models/flash_slot_model.dart';

class FlashSlotsRepository {
  final _db = FirebaseFirestore.instance;

  /// Stream de flash slots activos (no expirados).
  Stream<List<FlashSlotModel>> streamSlotsActivos() {
    final now = Timestamp.fromDate(DateTime.now());
    return _db
        .collection(FirestorePaths.flashSlots)
        .where('estado', isEqualTo: 'activo')
        .where('expiraEn', isGreaterThan: now)
        .orderBy('expiraEn')
        .snapshots()
        .map((s) => s.docs.map(FlashSlotModel.fromFirestore).toList());
  }

  /// Stream de flash slots de un complejo (admin).
  Stream<List<FlashSlotModel>> streamSlotsComplejo(String complejoId) {
    return _db
        .collection(FirestorePaths.flashSlots)
        .where('complejoId', isEqualTo: complejoId)
        .orderBy('creadoEn', descending: true)
        .snapshots()
        .map((s) => s.docs.map(FlashSlotModel.fromFirestore).toList());
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
