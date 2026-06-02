// core/constants/app_constants.dart
class AppConstants {
  AppConstants._();

  // ── API Keys ─────────────────────────────────────────────────────────────────
  /// RapidAPI key para Google Map Places (autocompletado de dirección en admin).
  static const String rapidApiKey = 'b6a60ec491mshb9ad791337a2de2p1acbebjsne8639ef7c3b5';

  // App info
  static const String appName = 'Al Toque';

  // Código secreto para registro de dueños de complejos.
  // Solo los dueños que trabajen con Al Toque conocen este código.
  static const String codigoRegistroDueno = 'ALTOQUE2026';
  static const String appVersion = '1.0.0';
  static const String ciudad = 'Huancayo';
  static const String pais = 'Perú';
  static const String currency = 'S/';

  // Coordenadas de Huancayo, Perú
  static const double huancayoLat = -12.0651;
  static const double huancayoLng = -75.2049;

  // Radio de búsqueda de complejos (km)
  static const double radioKm = 5.0;

  // Flash Slots
  static const int flashDuracionMinutos = 120; // 2 horas
  static const double flashDescuentoMinPct = 20.0;
  static const double flashDescuentoMaxPct = 30.0;
  static const int flashCheckIntervalMin = 30; // cada 30 min
  static const int canchaVaciaMinutosThreshold = 60; // > 60 min vacía

  // Notificaciones — canal IDs
  static const String channelIdAlta = 'canchapp_high';
  static const String channelIdNormal = 'canchapp_channel';

  // Partidos
  static const int partidoMinJugadores = 2;
  static const int partidoMaxJugadores = 22;

  // Horario default de complejos
  static const String horarioApertura = '07:00';
  static const String horarioCierre = '23:00';

  // Duración de slots (en horas)
  static const List<int> duracionesDisponibles = [1, 2, 3];

  // Deportes disponibles
  static const List<String> deportes = [
    'futbol5',
    'futbol7',
    'basquet',
    'voley',
  ];

  static const Map<String, String> deporteLabels = {
    'futbol5': 'Fútbol 5',
    'futbol7': 'Fútbol 7',
    'basquet': 'Básquet',
    'voley': 'Voley',
  };

  static const Map<String, String> deporteEmojis = {
    'futbol5': '⚽',
    'futbol7': '⚽',
    'basquet': '🏀',
    'voley': '🏐',
  };

  // Superficies
  static const Map<String, String> superficieLabels = {
    'sintetico': 'Sintético',
    'cemento': 'Cemento',
    'grass': 'Grass natural',
  };

  // Roles de usuario
  static const String rolJugador = 'jugador';
  static const String rolDueno = 'dueno';


  // Métodos de pago
  static const List<String> metodosPago = [
    'yape',
    'plin',
    'tarjeta',
    'transferencia',
  ];
  static const Map<String, String> metodoPagoLabels = {
    'yape': 'Yape',
    'plin': 'Plin',
    'tarjeta': 'Tarjeta',
    'transferencia': 'Transferencia',
  };

  // Estados de reserva
  static const String estadoConfirmada = 'confirmada';
  static const String estadoPendiente = 'pendiente';
  static const String estadoCancelada = 'cancelada';

  // Estados de partido
  static const String partidoAbierto = 'abierto';
  static const String partidoCompleto = 'completo';
  static const String partidoCancelado = 'cancelado';
  static const String partidoPendienteCancha = 'pendiente_cancha';

  // Estados de flash slot
  static const String flashActivo = 'activo';
  static const String flashReservado = 'reservado';
  static const String flashExpirado = 'expirado';

  // Deep link base URL
  static const String deepLinkBase = 'https://canchapp.pe';
  static const String deepLinkScheme = 'canchapp';
}
