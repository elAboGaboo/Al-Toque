import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart'; 
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'core/router/app_router.dart';
import 'core/services/deep_link_service.dart';
import 'core/services/notification_service.dart';
import 'core/theme/app_theme.dart';
import 'firebase_options.dart';

/// Handler background de FCM — debe ser top-level.
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Orientación solo portrait
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Status bar oscura sobre fondo claro
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));

  // Inicializar Firebase
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    // Registrar handler background de FCM
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    // Inicializar servicio de notificaciones
    await NotificationService.instance.initialize();
    // Inicializar deep links
    await DeepLinkService.instance.initialize(onLink: (_) {});
  } catch (e) {
    // Firebase no disponible (credenciales stub). La app arranca sin servicios.
    debugPrint('[Firebase] No inicializado: $e');
  }

  // Solicitar permisos Android en runtime
  await _solicitarPermisos();

  runApp(const ProviderScope(child: AlToqueApp()));
}

/// Solicita permisos de ubicación y notificaciones en Android runtime.
Future<void> _solicitarPermisos() async {
  // Ubicación (obligatoria para el mapa)
  final locationPerm = await Permission.locationWhenInUse.status;
  if (locationPerm.isDenied) {
    await Permission.locationWhenInUse.request();
  }

  // Notificaciones — obligatorio en Android 13+ (API 33+)
  // minSdk=24, así que verificamos la versión del SDK
  final androidInfo = await DeviceInfoPlugin().androidInfo;
  if (androidInfo.version.sdkInt >= 33) {
    final notifPerm = await Permission.notification.status;
    if (notifPerm.isDenied) {
      await Permission.notification.request();
    }
  }
}

class AlToqueApp extends ConsumerWidget {
  const AlToqueApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'Al Toque',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      // No usamos ThemeMode.system — la app Admin usa dark, usuario usa light
      themeMode: ThemeMode.light,
      routerConfig: router,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('es', 'PE'),
        Locale('es'),
        Locale('en'),
      ],
    );
  }
}
