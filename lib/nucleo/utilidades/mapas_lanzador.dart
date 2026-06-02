// core/utils/maps_launcher.dart
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

/// Utilidad para abrir Google Maps (o el navegador como fallback)
/// apuntando a una ubicación con nombre.
class MapsLauncher {
  MapsLauncher._();

  /// Abre Google Maps en la ubicación [lat]/[lng] con etiqueta [nombre].
  /// Intenta primero la app nativa de Google Maps; si no está instalada
  /// usa el fallback de google.com/maps en el navegador.
  static Future<void> irA({
    required double lat,
    required double lng,
    required String nombre,
  }) async {
    final encoded = Uri.encodeComponent(nombre);

    // URI nativa de Google Maps (Android & iOS)
    final nativeUri = Uri.parse(
      'google.navigation:q=$lat,$lng&label=$encoded',
    );

    // URI web de fallback
    final webUri = Uri.parse(
      'https://www.google.com/maps/search/?api=1'
      '&query=$lat,$lng'
      '&query_place_id=$encoded',
    );

    try {
      if (await canLaunchUrl(nativeUri)) {
        await launchUrl(nativeUri);
      } else {
        await launchUrl(webUri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('[MapsLauncher] Error abriendo Maps: $e');
      // Fallback silencioso — no lanzar excepción al usuario
      try {
        await launchUrl(webUri, mode: LaunchMode.externalApplication);
      } catch (_) {}
    }
  }
}
