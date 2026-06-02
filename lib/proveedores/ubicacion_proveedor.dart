// providers/location_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../nucleo/servicios/ubicacion_servicio.dart';

/// Posición actual del usuario (se obtiene una vez al iniciar).
final ubicacionProvider = FutureProvider<LatLng>((ref) async {
  return await LocationService.instance.obtenerPosicion();
});

/// Stream de actualizaciones de posición (para tracking).
final ubicacionStreamProvider = StreamProvider<LatLng>((ref) {
  return LocationService.instance.posicionStream();
});

/// Si el usuario concedió permiso de ubicación.
final tienePermisoUbicacionProvider = FutureProvider<bool>((ref) async {
  return await LocationService.instance.tienePermiso();
});

/// Obtiene la dirección (texto) a partir de coordenadas.
final direccionProvider = FutureProvider.family<String, LatLng>((ref, pos) async {
  return await LocationService.instance.obtenerDireccion(pos);
});
