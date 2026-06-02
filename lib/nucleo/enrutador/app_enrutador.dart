// core/router/app_router.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../proveedores/auth_proveedor.dart';
import '../../pantallas/autenticacion/registro_pantalla.dart';
import '../../pantallas/autenticacion/bienvenida_pantalla.dart';
import '../../pantallas/mapa/mapa_pantalla.dart';
import '../../pantallas/usuario/buscar_partidos_pantalla.dart';
import '../../pantallas/usuario/confirmacion_pantalla.dart';
import '../../pantallas/usuario/crear_partido_pantalla.dart';
import '../../pantallas/usuario/inicio_pantalla.dart';
import '../../pantallas/usuario/partido_completado_pantalla.dart';
import '../../pantallas/usuario/partido_envivo_pantalla.dart';
import '../../pantallas/usuario/perfil_pantalla.dart';
import '../../pantallas/usuario/complejo_detalle_pantalla.dart';
import '../../pantallas/usuario/reservar_pantalla.dart';
import '../../pantallas/usuario/usuario_envoltorio.dart';
import '../../pantallas/administracion/admin_panel_pantalla.dart';
import '../../pantallas/administracion/admin_flash_slots_pantalla.dart';
import '../../pantallas/administracion/admin_horarios_pantalla.dart';
import '../../pantallas/administracion/admin_ia_pantalla.dart';
import '../../pantallas/administracion/admin_ingresos_pantalla.dart';
import '../../pantallas/administracion/admin_partidos_pantalla.dart';
import '../../pantallas/administracion/admin_precios_pantalla.dart';
import '../../pantallas/administracion/admin_canchas_pantalla.dart';
import '../../pantallas/administracion/admin_mi_complejo_pantalla.dart';
import '../../pantallas/administracion/admin_configuracion_complejo_pantalla.dart';
import '../../pantallas/administracion/admin_envoltorio.dart';
import '../../pantallas/administracion/admin_usuarios_pantalla.dart';
import '../../pantallas/desarrollo/sembrar_pantalla.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();
final _userShellNavigatorKey = GlobalKey<NavigatorState>();

final appRouterProvider = Provider<GoRouter>((ref) {
  // Escuchamos auth state Y perfil del usuario para que el redirect se vuelva
  // a evaluar cuando cambien.
  final routerNotifier = ValueNotifier<int>(0);

  ref.listen(authStateProvider, (_, _) {
    routerNotifier.value++;
  });
  ref.listen(perfilUsuarioProvider, (_, _) {
    routerNotifier.value++;
  });

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/inicio',
    debugLogDiagnostics: false,
    refreshListenable: routerNotifier,
    redirect: (context, state) {
      User? currentUser;
      try {
        currentUser = FirebaseAuth.instance.currentUser;
      } catch (_) {
        // Firebase no inicializado (stub). Tratar como no autenticado.
      }
      final isAuth = currentUser != null;
      final loc = state.matchedLocation;

      const publicRoutes = ['/welcome', '/login', '/registro'];
      final isPublic = publicRoutes.contains(loc);

      // â”€â”€ No autenticado â†’ /welcome â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
      if (!isAuth) {
        debugPrint('[Router] no auth Â· loc=$loc â†’ ${isPublic ? "stay" : "/welcome"}');
        return isPublic ? null : '/welcome';
      }

      // â”€â”€ Autenticado: leemos el perfil de Firestore â”€â”€â”€â”€â”€â”€
      final perfilAsync = ref.read(perfilUsuarioProvider);

      // Perfil aÃºn sin datos (loading o error transitorio).
      // IMPORTANTE: solo redirigir a /loading desde rutas pÃºblicas.
      // Si ya estamos en una ruta de app (/inicio, /complejo/:id, etc.),
      // NO redirigir â€” evita el loop:
      //   /complejo/:id â†’ /loading â†’ (perfil recarga) â†’ /inicio
      // que hace que "Ver canchas" nunca llegue a destino.
      if (perfilAsync.asData == null) {
        debugPrint('[Router] auth=true Â· perfil cargando Â· loc=$loc');
        // Rutas pÃºblicas (auth): bloqueamos hasta tener perfil
        if (isPublic) return '/loading';
        // Ya en /loading: esperar
        if (loc == '/loading') return null;
        // En cualquier ruta de app: dejar pasar, la pantalla maneja su loading
        return null;
      }

      final perfil = perfilAsync.asData!.value;
      final isAdminRoute = loc.startsWith('/admin');

      // Usuario autenticado pero sin documento en Firestore (perfil null).
      // Posible en: registro parcial, red lenta, doc borrado manualmente.
      // NO redirigir desde rutas de app (complejo, reserva, etc.) porque
      // causarÃ­a pantalla en blanco al navegar. Solo bloquear admin routes
      // o rutas pÃºblicas donde el perfil es obligatorio.
      if (perfil == null) {
        debugPrint('[Router] auth=true Â· sin perfil en Firestore Â· loc=$loc');
        // Admin requiere perfil completo â†’ welcome para re-login / re-registro
        if (isAdminRoute) return '/welcome';
        // Rutas pÃºblicas: redirigir al inicio
        if (isPublic || loc == '/loading') return '/inicio';
        // Rutas de usuario (complejo, reserva, etc.): dejar pasar
        // El perfil puede llegar en cualquier momento (stream tarda en emitir)
        return null;
      }

      final esDueno = perfil.esDueno;

      debugPrint('[Router] auth=true Â· uid=${currentUser.uid.substring(0, 6)}â€¦ Â· '
          'rol="${perfil.rol}" Â· esDueno=$esDueno Â· loc=$loc');

      if (esDueno) {
        // Si el dueÃ±o aÃºn no tiene complejo vinculado â†’ setup obligatorio.
        final tieneComplejo = perfil.complejoId != null &&
            perfil.complejoId!.isNotEmpty;
        if (!tieneComplejo && loc != '/admin/setup-complejo') {
          return '/admin/setup-complejo';
        }
        // Rutas dev/seed siempre accesibles (para poblar BD de prueba)
        if (loc.startsWith('/dev/')) return null;
        // Rutas de detalle/flujo de usuario: dueÃ±os tambiÃ©n pueden acceder
        // (p.ej. para previsualizar un complejo o reservar como jugador)
        if (loc.startsWith('/complejo/') ||
            loc.startsWith('/reservar/') ||
            loc.startsWith('/confirmacion/') ||
            loc.startsWith('/partido/') ||
            loc == '/crear-partido') {
          return null;
        }
        if (isPublic || !isAdminRoute) return '/admin/dashboard';
        return null;
      }

      if (!esDueno && isAdminRoute) {
        return '/inicio';
      }

      if (isPublic || loc == '/loading') return '/inicio';

      return null;
    },
    routes: [
      // â”€â”€ Loading (perfil cargando) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
      GoRoute(
        path: '/loading',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, _) => const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      ),

      // â”€â”€ Auth â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
      GoRoute(
        path: '/welcome',
        name: 'welcome',
        builder: (_, _) => const WelcomeScreen(modoInicial: 'roles'),
      ),
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (_, _) => const WelcomeScreen(modoInicial: 'login'),
      ),
      GoRoute(
        path: '/registro',
        name: 'registro',
        builder: (_, state) => RegistroScreen(
          rolInicial: state.uri.queryParameters['rol'] ?? 'jugador',
        ),
      ),

      // â”€â”€ Usuario Â· ShellRoute con bottom navigation â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
      // Las rutas de detalle y reserva tambiÃ©n viven aquÃ­ dentro para que
      // el navigator del shell haga offstage correcto del mapa al navegar.
      // UserShell oculta el bottom nav cuando la ruta no es un tab principal.
      ShellRoute(
        navigatorKey: _userShellNavigatorKey,
        builder: (_, _, child) => UserShell(child: child),
        routes: [
          // â”€â”€ Tabs principales (con bottom nav) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
          GoRoute(
            path: '/inicio',
            name: 'inicio',
            builder: (_, _) => const InicioScreen(),
          ),
          GoRoute(
            path: '/mapa',
            name: 'mapa',
            builder: (_, _) => const MapaScreen(),
          ),
          GoRoute(
            path: '/partidos',
            name: 'buscarPartidos',
            builder: (_, _) => const BuscarPartidosScreen(),
          ),
          GoRoute(
            path: '/perfil',
            name: 'perfil',
            builder: (_, _) => const PerfilScreen(),
          ),

          // â”€â”€ Pantallas de flujo usuario (sin bottom nav) â”€â”€â”€
          GoRoute(
            path: '/complejo/:complejoId',
            name: 'complejoDetalle',
            builder: (_, state) => ComplejoDetalleScreen(
              complejoId: state.pathParameters['complejoId']!,
            ),
          ),
          GoRoute(
            path: '/reservar/:complejoId/:canchaId',
            name: 'reservar',
            builder: (_, state) => ReservarScreen(
              complejoId: state.pathParameters['complejoId']!,
              canchaId: state.pathParameters['canchaId']!,
            ),
          ),
          GoRoute(
            path: '/confirmacion/:reservaId',
            name: 'confirmacion',
            builder: (_, state) => ConfirmacionScreen(
              reservaId: state.pathParameters['reservaId']!,
            ),
          ),
          GoRoute(
            path: '/crear-partido',
            name: 'crearPartido',
            builder: (_, _) => const CrearPartidoScreen(),
          ),
          GoRoute(
            path: '/partido/:partidoId',
            name: 'partidoLive',
            builder: (_, state) => PartidoLiveScreen(
              partidoId: state.pathParameters['partidoId']!,
            ),
          ),
          GoRoute(
            path: '/partido/:partidoId/completado',
            name: 'partidoCompletado',
            builder: (_, state) => PartidoCompletadoScreen(
              partidoId: state.pathParameters['partidoId']!,
            ),
          ),
        ],
      ),

      // â”€â”€ Seed / Setup inicial de base de datos â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
      GoRoute(
        path: '/dev/seed',
        name: 'seedDatabase',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, _) => const SeedScreen(),
      ),

      // â”€â”€ Admin Setup â€” fuera del shell (pantalla completa) â”€â”€
      GoRoute(
        path: '/admin/setup-complejo',
        name: 'adminSetupComplejo',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, _) => const AdminSetupComplejoScreen(),
      ),

      // â”€â”€ Mi Complejo â€” ediciÃ³n desde el panel admin â”€â”€â”€â”€â”€â”€
      GoRoute(
        path: '/admin/mi-complejo',
        name: 'adminMiComplejo',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, _) => const AdminMiComplejoScreen(),
      ),

      // â”€â”€ Canchas â€” gestiÃ³n desde el panel admin â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
      GoRoute(
        path: '/admin/canchas',
        name: 'adminCanchas',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, _) => const AdminCanchasScreen(),
      ),

      // â”€â”€ Admin (ShellRoute con bottom nav) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (_, _, child) => AdminShell(child: child),
        routes: [
          GoRoute(
            path: '/admin',
            redirect: (_, _) => '/admin/dashboard',
          ),
          GoRoute(
            path: '/admin/dashboard',
            name: 'adminDashboard',
            builder: (_, _) => const AdminDashboardScreen(),
          ),
          GoRoute(
            path: '/admin/horarios',
            name: 'adminHorarios',
            builder: (_, _) => const AdminHorariosScreen(),
          ),
          GoRoute(
            path: '/admin/ia',
            name: 'adminIA',
            builder: (_, _) => const AdminIAScreen(),
          ),
          GoRoute(
            path: '/admin/precios',
            name: 'adminPrecios',
            builder: (_, _) => const AdminPreciosScreen(),
          ),
          GoRoute(
            path: '/admin/usuarios',
            name: 'adminUsuarios',
            builder: (_, _) => const AdminUsuariosScreen(),
          ),
          // Rutas auxiliares (no en bottom nav, accesibles vÃ­a deep-link/admin)
          GoRoute(
            path: '/admin/flash-slots',
            name: 'adminFlashSlots',
            builder: (_, _) => const AdminFlashSlotsScreen(),
          ),
          GoRoute(
            path: '/admin/partidos',
            name: 'adminPartidos',
            builder: (_, _) => const AdminPartidosScreen(),
          ),
          GoRoute(
            path: '/admin/ingresos',
            name: 'adminIngresos',
            builder: (_, _) => const AdminIngresosScreen(),
          ),
        ],
      ),
    ],
  );
});

// AdminShell vive ahora en lib/screens/admin/admin_shell.dart
