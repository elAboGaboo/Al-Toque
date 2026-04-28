// core/services/location_service.dart
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart';

class LocationService {
  LocationService._();
  static final LocationService instance = LocationService._();

  // Coordenadas default: Plaza Huancayo
  static const LatLng _defaultPos = LatLng(-12.0651, -75.2049);

  /// Solicita permiso de ubicación y retorna la posición actual.
  /// Si el permiso es denegado, retorna la posición default de Huancayo.
  Future<LatLng> obtenerPosicion() async {
    // Verificar y solicitar permiso
    var permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever ||
        permission == LocationPermission.denied) {
      return _defaultPos;
    }

    // Verificar que el GPS esté habilitado
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return _defaultPos;

    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
      return LatLng(pos.latitude, pos.longitude);
    } catch (_) {
      return _defaultPos;
    }
  }

  /// Stream de actualizaciones de posición (para tracking en tiempo real).
  Stream<LatLng> posicionStream() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 50, // actualizar cada 50 metros
      ),
    ).map((pos) => LatLng(pos.latitude, pos.longitude));
  }

  /// Solo verifica si el permiso fue concedido (sin pedirlo).
  Future<bool> tienePermiso() async {
    final perm = await Geolocator.checkPermission();
    return perm == LocationPermission.always ||
        perm == LocationPermission.whileInUse;
  }

  /// Abre configuración del sistema para habilitar ubicación manualmente.
  Future<void> abrirConfiguracion() async {
    await openAppSettings();
  }
}
