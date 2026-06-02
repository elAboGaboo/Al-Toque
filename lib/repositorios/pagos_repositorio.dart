// repositorios/pagos_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';

import '../nucleo/constantes/firestore_rutas.dart';
import '../modelos/pago_modelo.dart';

class PagosRepository {
  final _db = FirebaseFirestore.instance;

  /// Registra un nuevo pago y devuelve su id.
  Future<String> crearPago(PagoModel pago) async {
    final ref = await _db.collection(FirestorePaths.pagos).add(pago.toMap());
    return ref.id;
  }

  /// Pago por id (one-shot).
  Future<PagoModel?> getPago(String pagoId) async {
    final doc = await _db.doc(FirestorePaths.pagoDoc(pagoId)).get();
    return doc.exists ? PagoModel.fromFirestore(doc) : null;
  }

  /// Pagos de un usuario, más recientes primero.
  Stream<List<PagoModel>> streamPagosUsuario(String userId) {
    return _db
        .collection(FirestorePaths.pagos)
        .where('userId', isEqualTo: userId)
        .orderBy('creadoEn', descending: true)
        .snapshots()
        .map((s) => s.docs.map(PagoModel.fromFirestore).toList());
  }

  /// Pago asociado a una reserva (suele haber uno).
  Future<PagoModel?> getPagoDeReserva(String reservaId) async {
    final snap = await _db
        .collection(FirestorePaths.pagos)
        .where('reservaId', isEqualTo: reservaId)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    return PagoModel.fromFirestore(snap.docs.first);
  }

  /// Actualiza el estado de un pago (pagado, fallido, reembolsado…).
  Future<void> actualizarEstado(String pagoId, String estado,
      {String? idTransaccion}) async {
    await _db.doc(FirestorePaths.pagoDoc(pagoId)).update({
      'estado': estado,
      if (estado == 'pagado') 'pagadoEn': FieldValue.serverTimestamp(),
      'idTransaccion': idTransaccion,
    });
  }
}
