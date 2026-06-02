// core/services/directions_service.dart
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

/// Obtiene la polilínea de ruta usando OSRM (gratuito, sin API key).
class DirectionsService {
  DirectionsService._();

  static const _baseUrl = 'https://router.project-osrm.org/route/v1/foot';

  static Future<List<LatLng>?> getRoute({
    required LatLng origin,
    required LatLng destination,
  }) async {
    final uri = Uri.parse(
      '$_baseUrl/${origin.longitude},${origin.latitude}'
      ';${destination.longitude},${destination.latitude}'
      '?overview=full&geometries=geojson',
    );

    try {
      final response =
          await http.get(uri).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        debugPrint('[DirectionsService] HTTP ${response.statusCode}');
        return null;
      }

      final data = json.decode(response.body) as Map<String, dynamic>;
      final routes = data['routes'] as List?;

      if (routes == null || routes.isEmpty) {
        debugPrint('[DirectionsService] Sin rutas: ${data['code']}');
        return null;
      }

      final geometry =
          (routes.first as Map<String, dynamic>)['geometry'] as Map<String, dynamic>?;
      final coords = geometry?['coordinates'] as List?;

      if (coords == null || coords.isEmpty) return null;

      // OSRM devuelve [lng, lat] — invertimos a LatLng(lat, lng)
      return coords
          .map((c) => LatLng((c as List)[1] as double, c[0] as double))
          .toList();
    } catch (e) {
      debugPrint('[DirectionsService] Error: $e');
      return null;
    }
  }
}
