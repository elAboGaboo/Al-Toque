// repositorios/reportes_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';

import '../nucleo/constantes/firestore_rutas.dart';
import '../modelos/reporte_modelo.dart';

class ReportesRepository {
  final _db = FirebaseFirestore.instance;

  /// Envía un reporte y devuelve su id.
  Future<String> crearReporte(ReporteModel reporte) async {
    final ref =
        await _db.collection(FirestorePaths.reportes).add(reporte.toMap());
    return ref.id;
  }

  /// Reportes filtrados por estado (para moderación), más recientes primero.
  Stream<List<ReporteModel>> streamPorEstado(String estado) {
    return _db
        .collection(FirestorePaths.reportes)
        .where('estado', isEqualTo: estado)
        .orderBy('creadoEn', descending: true)
        .snapshots()
        .map((s) => s.docs.map(ReporteModel.fromFirestore).toList());
  }

  /// Cambia el estado de un reporte (revisando / resuelto).
  Future<void> actualizarEstado(String reporteId, String estado) async {
    await _db.doc(FirestorePaths.reporteDoc(reporteId)).update({
      'estado': estado,
      if (estado == 'resuelto') 'resueltoEn': FieldValue.serverTimestamp(),
    });
  }
}
