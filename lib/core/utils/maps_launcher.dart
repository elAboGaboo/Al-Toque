// core/utils/maps_launcher.dart
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

/// Abre la app de mapas del dispositivo con las coordenadas dadas.
///
/// Estrategia:
///   1. Intenta `geo:lat,lng?q=lat,lng` → abre Google Maps nativo (Android)
///   2. Fallback: URL web de Google Maps → abre en el navegador
///
/// Uso:
///   ```dart
///   await MapsLauncher.complejoDetalle(lat: c.lat, lng: c.lng, nombre: c.nombre);
///   ```
class MapsLauncher {
  MapsLauncher._();

  /// Navegar a destino (apertura de Google Maps / app de navegación nativa).
  static Future<void> irA({
    required double lat,
    required double lng,
    String? nombre,
  }) async {
    // geo: scheme → Google Maps nativo en Android, Apple Maps en iOS
    final geoUri = Uri(
      scheme: 'geo',
      path: '$lat,$lng',
      queryParameters: {'q': nombre != null ? '$lat,$lng($nombre)' : '$lat,$lng'},
    );

    // URL web como fallback garantizado (funciona en cualquier navegador)
    final webUri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$lat,$lng',
    );

    try {
      if (await canLaunchUrl(geoUri)) {
        await launchUrl(geoUri);
        return;
      }
    } catch (e) {
      debugPrint('[MapsLauncher] geo: no disponible → $e');
    }

    // Fallback web
    try {
      await launchUrl(webUri, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('[MapsLauncher] No se pudo abrir Google Maps: $e');
    }
  }
}
