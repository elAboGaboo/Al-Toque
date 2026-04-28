// core/services/deep_link_service.dart
import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';

import '../constants/app_constants.dart';

/// Maneja deep links para invitar jugadores a partidos.
/// Scheme: canchapp://partido/{partidoId}
/// HTTPS: https://canchapp.pe/partido/{partidoId}
class DeepLinkService {
  DeepLinkService._();
  static final DeepLinkService instance = DeepLinkService._();

  final _appLinks = AppLinks();
  void Function(String route)? _onLink;

  /// Inicializar al arrancar la app.
  Future<void> initialize({required void Function(String route) onLink}) async {
    _onLink = onLink;

    // URI inicial (app fría desde link)
    try {
      final initialLink = await _appLinks.getInitialLink();
      if (initialLink != null) {
        _handleUri(initialLink);
      }
    } catch (e) {
      debugPrint('[DeepLink] Error obteniendo link inicial: $e');
    }

    // Escuchar links mientras la app está abierta
    _appLinks.uriLinkStream.listen(
      _handleUri,
      onError: (e) => debugPrint('[DeepLink] Error en stream: $e'),
    );
  }

  void _handleUri(Uri uri) {
    debugPrint('[DeepLink] Recibido: $uri');

    // canchapp://partido/abc123
    // https://canchapp.pe/partido/abc123
    if (uri.pathSegments.length >= 2 &&
        uri.pathSegments[0] == 'partido') {
      final partidoId = uri.pathSegments[1];
      _onLink?.call('/partido/$partidoId');
      return;
    }

    if (uri.pathSegments.isNotEmpty &&
        uri.pathSegments[0] == 'confirmacion') {
      final reservaId = uri.pathSegments.length > 1
          ? uri.pathSegments[1]
          : '';
      _onLink?.call('/confirmacion/$reservaId');
    }
  }

  /// Genera un link para compartir un partido.
  static String generarLinkPartido(String partidoId) {
    return '${AppConstants.deepLinkBase}/partido/$partidoId';
  }
}
