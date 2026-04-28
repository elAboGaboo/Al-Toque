// core/services/notification_service.dart
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// Canal HIGH PRIORITY: partidos completados, flash slots urgentes
const AndroidNotificationChannel _channelHigh = AndroidNotificationChannel(
  'canchapp_high',
  'CanchApp — Urgente',
  description: 'Partido completado, Flash Slots y alertas inmediatas',
  importance: Importance.max,
  playSound: true,
  enableVibration: true,
);

// Canal NORMAL: confirmaciones y recordatorios
const AndroidNotificationChannel _channelNormal = AndroidNotificationChannel(
  'canchapp_channel',
  'CanchApp Notificaciones',
  description: 'Reservas, Flash Slots y Partidos',
  importance: Importance.high,
  playSound: true,
);

/// Maneja FCM (Firebase Cloud Messaging) + notificaciones locales.
/// Android únicamente — no contiene ninguna lógica iOS.
class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  final _fcm = FirebaseMessaging.instance;
  final _localNotif = FlutterLocalNotificationsPlugin();

  // Callback para navegación desde notificación
  void Function(String route)? onNavigate;

  /// Llamar una sola vez al inicio de la app.
  Future<void> initialize({void Function(String route)? onNavigate}) async {
    this.onNavigate = onNavigate;

    // Configurar local notifications
    const androidInit = AndroidInitializationSettings('@drawable/ic_notification');
    const initSettings = InitializationSettings(android: androidInit);

    await _localNotif.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        final payload = response.payload;
        if (payload != null && onNavigate != null) {
          onNavigate(payload);
        }
      },
    );

    // Crear canales Android (API 26+, minSdk=24 así que siempre se ejecuta en 26+)
    final plugin = _localNotif
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (plugin != null) {
      await plugin.createNotificationChannel(_channelHigh);
      await plugin.createNotificationChannel(_channelNormal);
    }

    // Solicitar permisos FCM (Android 13+ = POST_NOTIFICATIONS)
    // La solicitud del permiso de sistema se hace en main.dart via permission_handler
    await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // FCM handlers (background handler se registra en main.dart)
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

    // Mensaje inicial (app abierta desde notificación cold start)
    final initial = await _fcm.getInitialMessage();
    if (initial != null) _handleMessageOpenedApp(initial);
  }

  /// Obtiene el FCM token del dispositivo Android.
  Future<String?> getToken() async {
    return await _fcm.getToken();
  }

  // ── Handlers ────────────────────────────────────────────────

  void _handleForegroundMessage(RemoteMessage message) {
    final notif = message.notification;
    final android = message.notification?.android;
    if (notif == null || android == null) return;

    final isUrgente = message.data['tipo'] == 'partido_completo' ||
        message.data['tipo'] == 'flash_slot';

    _localNotif.show(
      notif.hashCode,
      notif.title,
      notif.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          isUrgente ? _channelHigh.id : _channelNormal.id,
          isUrgente ? _channelHigh.name : _channelNormal.name,
          icon: '@drawable/ic_notification',
          importance: isUrgente ? Importance.max : Importance.high,
          priority: isUrgente ? Priority.max : Priority.high,
          styleInformation: const BigTextStyleInformation(''),
        ),
      ),
      payload: message.data['route'],
    );
  }

  void _handleMessageOpenedApp(RemoteMessage message) {
    final route = message.data['route'] as String?;
    if (route != null && onNavigate != null) {
      onNavigate!(route);
    }
  }

  /// Muestra notificación local inmediata (sin FCM).
  Future<void> mostrarLocal({
    required String titulo,
    required String cuerpo,
    String? payload,
    bool urgente = false,
  }) async {
    await _localNotif.show(
      DateTime.now().millisecondsSinceEpoch & 0x7FFFFFFF,
      titulo,
      cuerpo,
      NotificationDetails(
        android: AndroidNotificationDetails(
          urgente ? _channelHigh.id : _channelNormal.id,
          urgente ? _channelHigh.name : _channelNormal.name,
          icon: '@drawable/ic_notification',
          importance: urgente ? Importance.max : Importance.high,
          priority: urgente ? Priority.max : Priority.high,
        ),
      ),
      payload: payload,
    );
  }
}

