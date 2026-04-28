import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/cancha_model.dart';
import '../models/complejo_model.dart';

class ComplejosService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('complejos');

  // ── Streaming ──────────────────────────────────────────────

  /// Stream de todos los complejos activos (filtrado geo en cliente)
  Stream<List<ComplejoModel>> streamComplejosCercanos({
    required double lat,
    required double lng,
    double radioKm = 5,
  }) {
    // Firestore no soporta GeoQuery nativo. Calculamos bounding box
    // y filtramos por lat; el filtro de lng se hace en cliente.
    final deltaLat = radioKm / 111.0;
    return _col
        .where('activo', isEqualTo: true)
        .where('lat', isGreaterThan: lat - deltaLat)
        .where('lat', isLessThan: lat + deltaLat)
        .snapshots()
        .map((snap) {
      final deltaLng = radioKm / (111.0 * math.cos(lat * math.pi / 180));
      return snap.docs
          .map(ComplejoModel.fromDoc)
          .where((c) => (c.lng - lng).abs() < deltaLng)
          .where((c) => _distanciaKm(lat, lng, c.lat, c.lng) <= radioKm)
          .toList()
        ..sort((a, b) => _distanciaKm(lat, lng, a.lat, a.lng)
            .compareTo(_distanciaKm(lat, lng, b.lat, b.lng)));
    });
  }

  /// Distancia en km entre dos puntos usando Haversine simplificado
  double distanciaKm(double lat1, double lng1, ComplejoModel c) =>
      _distanciaKm(lat1, lng1, c.lat, c.lng);

  double _distanciaKm(double lat1, double lng1, double lat2, double lng2) {
    const r = 6371.0;
    final dLat = _rad(lat2 - lat1);
    final dLng = _rad(lng2 - lng1);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_rad(lat1)) *
            math.cos(_rad(lat2)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    return r * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  }

  double _rad(double deg) => deg * math.pi / 180;

  // ── Canchas ────────────────────────────────────────────────

  Stream<List<CanchaModel>> streamCanchas(String complejoId) {
    return _col
        .doc(complejoId)
        .collection('canchas')
        .where('activa', isEqualTo: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => CanchaModel.fromDoc(d, complejoId: complejoId))
            .toList());
  }

  Future<List<CanchaModel>> getCanchas(String complejoId) async {
    final snap = await _col
        .doc(complejoId)
        .collection('canchas')
        .where('activa', isEqualTo: true)
        .get();
    return snap.docs
        .map((d) => CanchaModel.fromDoc(d, complejoId: complejoId))
        .toList();
  }

  Future<ComplejoModel?> getComplejo(String complejoId) async {
    final doc = await _col.doc(complejoId).get();
    if (!doc.exists) return null;
    return ComplejoModel.fromDoc(doc);
  }
}
