import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../models/complejo_model.dart';
import '../models/flash_slot_model.dart';
import '../models/partido_model.dart';
import '../models/prediccion_ia_model.dart';
import '../services/complejos_service.dart';
import '../services/flash_slots_service.dart';
import '../services/partidos_service.dart';
import '../services/predicciones_service.dart';

// ── Servicios ──────────────────────────────────────────────

final complejosServiceProvider = Provider<ComplejosService>(
  (_) => ComplejosService(),
);
final flashSlotsServiceProvider = Provider<FlashSlotsService>(
  (_) => FlashSlotsService(),
);
final partidosServiceProvider = Provider<PartidosService>(
  (_) => PartidosService(),
);
final prediccionesServiceProvider = Provider<PrediccionesService>(
  (_) => PrediccionesService(),
);

// ── Ubicación del usuario ──────────────────────────────────

final ubicacionProvider = FutureProvider<LatLng?>((ref) async {
  LocationPermission perm = await Geolocator.checkPermission();
  if (perm == LocationPermission.denied) {
    perm = await Geolocator.requestPermission();
  }
  if (perm == LocationPermission.deniedForever) return null;

  final pos = await Geolocator.getCurrentPosition(
    locationSettings: const LocationSettings(
      accuracy: LocationAccuracy.high,
      timeLimit: Duration(seconds: 10),
    ),
  );
  return LatLng(pos.latitude, pos.longitude);
});

// ── Filtro activo del mapa ─────────────────────────────────

enum MapFilter { todos, flash, partidos, disponibles, futbol5 }

final mapFilterProvider = StateProvider<MapFilter>(
  (_) => MapFilter.todos,
);

// ── Complejos cercanos ─────────────────────────────────────

final complejosCercanosProvider =
    StreamProvider.family<List<ComplejoModel>, LatLng>((ref, pos) {
  final svc = ref.watch(complejosServiceProvider);
  return svc.streamComplejosCercanos(
    lat: pos.latitude,
    lng: pos.longitude,
    radioKm: 5,
  );
});

// ── Flash slots activos ────────────────────────────────────

final flashSlotsActivosProvider =
    StreamProvider<List<FlashSlotModel>>((ref) {
  final svc = ref.watch(flashSlotsServiceProvider);
  return svc.streamSlotsActivos();
});

// ── Partidos abiertos ──────────────────────────────────────

final partidosAbiertosProvider =
    StreamProvider<List<PartidoModel>>((ref) {
  final svc = ref.watch(partidosServiceProvider);
  return svc.streamPartidosAbiertos();
});

// ── Predicción IA del complejo más cercano ─────────────────

final prediccionCercanosProvider =
    FutureProvider.family<PrediccionIAModel?, String>((ref, complejoId) {
  final svc = ref.watch(prediccionesServiceProvider);
  return svc.getUltimaPrediccion(complejoId);
});

// ── Complejo seleccionado (para sheet de detalle) ──────────

final complejoSeleccionadoProvider =
    StateProvider<ComplejoModel?>((ref) => null);
