// services/predicciones_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/constants/firestore_paths.dart';
import '../models/prediccion_ia_model.dart';

class PrediccionesService {
  final _db = FirebaseFirestore.instance;

  /// Retorna la predicción más reciente de un complejo.
  Future<PrediccionIAModel?> getUltimaPrediccion(String complejoId) async {
    final q = await _db
        .collection(FirestorePaths.predicciones)
        .where('complejoId', isEqualTo: complejoId)
        .orderBy('generadoEn', descending: true)
        .limit(1)
        .get();

    if (q.docs.isEmpty) return null;
    return PrediccionIAModel.fromFirestore(q.docs.first);
  }

  /// Stream de la predicción activa en tiempo real.
  Stream<PrediccionIAModel?> streamPrediccion(String complejoId) {
    return _db
        .collection(FirestorePaths.predicciones)
        .where('complejoId', isEqualTo: complejoId)
        .orderBy('generadoEn', descending: true)
        .limit(1)
        .snapshots()
        .map((s) => s.docs.isEmpty
            ? null
            : PrediccionIAModel.fromFirestore(s.docs.first));
  }
}
