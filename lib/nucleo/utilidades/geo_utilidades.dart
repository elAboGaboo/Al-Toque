// core/utils/geo_utils.dart
import 'dart:math';

class GeoUtils {
  GeoUtils._();

  static const double _earthRadiusKm = 6371.0;

  /// Distancia Haversine entre dos puntos (km).
  static double distanciaKm({
    required double lat1,
    required double lng1,
    required double lat2,
    required double lng2,
  }) {
    final dLat = _toRad(lat2 - lat1);
    final dLng = _toRad(lng2 - lng1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRad(lat1)) *
            cos(_toRad(lat2)) *
            sin(dLng / 2) *
            sin(dLng / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return _earthRadiusKm * c;
  }

  /// "a 1.2 km" o "a 850 m"
  static String formatearDistancia(double km) {
    if (km < 1.0) {
      return 'a ${(km * 1000).round()} m';
    }
    return 'a ${km.toStringAsFixed(1)} km';
  }

  static double _toRad(double deg) => deg * pi / 180;
}
