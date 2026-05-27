// core/services/places_service.dart
// Wrapper sobre Google Map Places (New V2) via RapidAPI.
// Endpoints usados: Autocomplete + Place Details.
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../constants/app_constants.dart';

// ── Modelos ligeros ──────────────────────────────────────────────────────────

class PlacePrediction {
  final String placeId;
  final String text;
  const PlacePrediction({required this.placeId, required this.text});
}

class PlaceLocation {
  final double lat;
  final double lng;
  final String address;
  const PlaceLocation({
    required this.lat,
    required this.lng,
    required this.address,
  });
}

// ── Servicio ─────────────────────────────────────────────────────────────────

class PlacesService {
  static const _baseUrl =
      'https://google-map-places-new-v2.p.rapidapi.com';
  static const _host = 'google-map-places-new-v2.p.rapidapi.com';

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'X-Goog-FieldMask': '*',
        'x-rapidapi-host': _host,
        'x-rapidapi-key': AppConstants.rapidApiKey,
      };

  /// Retorna sugerencias de direcciones para [input].
  /// Aplica sesgo de ubicacion centrado en Huancayo (50 km de radio).
  Future<List<PlacePrediction>> autocomplete(String input) async {
    if (input.trim().length < 3) return [];
    try {
      final body = jsonEncode({
        'input': input,
        'locationBias': {
          'circle': {
            'center': {
              'latitude': AppConstants.huancayoLat,
              'longitude': AppConstants.huancayoLng,
            },
            'radius': 50000.0,
          }
        },
        'languageCode': 'es',
        'regionCode': 'PE',
        'includeQueryPredictions': true,
      });

      final res = await http
          .post(
            Uri.parse('$_baseUrl/v1/places:autocomplete'),
            headers: _headers,
            body: body,
          )
          .timeout(const Duration(seconds: 8));

      if (res.statusCode != 200) {
        debugPrint('[Places] autocomplete ${res.statusCode}: ${res.body}');
        return [];
      }

      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final suggestions = data['suggestions'] as List? ?? [];

      return suggestions
          .where((s) => s['placePrediction'] != null)
          .map((s) {
            final place = s['placePrediction'] as Map<String, dynamic>;
            return PlacePrediction(
              placeId: place['placeId'] as String,
              text: (place['text'] as Map<String, dynamic>)['text'] as String,
            );
          })
          .toList();
    } catch (e) {
      debugPrint('[Places] autocomplete error: $e');
      return [];
    }
  }

  /// Retorna coordenadas y direccion formateada para [placeId].
  Future<PlaceLocation?> getPlaceDetails(String placeId) async {
    try {
      final res = await http
          .get(
            Uri.parse('$_baseUrl/v1/places/$placeId'),
            headers: {
              ..._headers,
              'X-Goog-FieldMask': 'location,formattedAddress',
            },
          )
          .timeout(const Duration(seconds: 8));

      if (res.statusCode != 200) {
        debugPrint('[Places] details ${res.statusCode}: ${res.body}');
        return null;
      }

      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final loc = data['location'] as Map<String, dynamic>?;
      if (loc == null) return null;

      return PlaceLocation(
        lat: (loc['latitude'] as num).toDouble(),
        lng: (loc['longitude'] as num).toDouble(),
        address: data['formattedAddress'] as String? ?? '',
      );
    } catch (e) {
      debugPrint('[Places] details error: $e');
      return null;
    }
  }
}
