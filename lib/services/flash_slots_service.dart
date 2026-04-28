import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/flash_slot_model.dart';

class FlashSlotsService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('flashSlots');

  /// Stream de flash slots activos (estado==activo Y expiraEn > now)
  Stream<List<FlashSlotModel>> streamSlotsActivos() {
    return _col
        .where('estado', isEqualTo: 'activo')
        .where('expiraEn', isGreaterThan: Timestamp.now())
        .snapshots()
        .map((s) => s.docs.map(FlashSlotModel.fromDoc).toList());
  }

  Stream<FlashSlotModel?> streamSlot(String slotId) {
    return _col.doc(slotId).snapshots().map(
          (d) => d.exists ? FlashSlotModel.fromDoc(d) : null,
        );
  }

  Future<void> incrementarVistas(String slotId) async {
    await _col.doc(slotId).update({
      'vistasCount': FieldValue.increment(1),
    });
  }

  Future<void> marcarReservado(String slotId) async {
    await _col.doc(slotId).update({'estado': 'reservado'});
  }

  Future<void> marcarExpirado(String slotId) async {
    await _col.doc(slotId).update({'estado': 'expirado'});
  }

  Future<String> crearFlashSlot(FlashSlotModel slot) async {
    final ref = await _col.add(slot.toMap());
    return ref.id;
  }

  Future<void> actualizarPrecio(String slotId, double nuevoPrecio) async {
    await _col.doc(slotId).update({'precioFlash': nuevoPrecio});
  }
}
