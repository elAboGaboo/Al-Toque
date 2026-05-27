// core/router/app_router.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/auth_provider.dart';
import '../../screens/auth/registro_screen.dart';
import '../../screens/auth/welcome_screen.dart';
import '../../screens/mapa/mapa_screen.dart';
import '../../screens/usuario/buscar_partidos_screen.dart';
import '../../screens/usuario/confirmacion_screen.dart';
import '../../screens/usuario/crear_partido_screen.dart';
import '../../screens/usuario/inicio_screen.dart';
import '../../screens/usuario/partido_completado_screen.dart';
import '../../screens/usuario/partido_live_screen.dart';
import '../../screens/usuario/perfil_screen.dart';
import '../../screens/usuario/complejo_detalle_screen.dart';
import '../../screens/usuario/reservar_screen.dart';
import '../../screens/usuario/user_shell.dart';
import '../../screens/admin/admin_dashboard_screen.dart';
import '../../screens/admin/admin_flash_slots_screen.dart';
import '../../screens/admin/admin_horarios_screen.dart';
import '../../screens/admin/admin_ia_screen.dart';
import '../../screens/admin/admin_ingresos_screen.dart';
import '../../screens/admin/admin_partidos_screen.dart';
import '../../screens/admin/admin_precios_screen.dart';
import '../../screens/admin/admin_canchas_screen.dart';
import '../../screens/admin/admin_mi_complejo_screen.dart';
import '../../screens/admin/admin_setup_complejo_screen.dart';
import '../../screens/admin/admin_shell.dart';
import '../../screens/admin/admin_usuarios_screen.dart';
import '../../screens/dev/seed_screen.dart';

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

      // ── No autenticado → /welcome ───────────────────────
      if (!isAuth) {
        debugPrint('[Router] no auth · loc=$loc → ${isPublic ? "stay" : "/welcome"}');
        return isPublic ? null : '/welcome';
      }

      // ── Autenticado: leemos el perfil de Firestore ──────
      final perfilAsync = ref.read(perfilUsuarioProvider);

      // Perfil aún cargando — ruta neutra para evitar flashear la UI de jugador
      if (perfilAsync.asData == null) {
        debugPrint('[Router] auth=true · perfil cargando · loc=$loc');
        return loc == '/loading' ? null : '/loading';
      }

      final perfil = perfilAsync.asData!.value;

      // Usuario autenticado pero sin documento en Firestore (caso edge)
      if (perfil == null) {
        debugPrint('[Router] auth=true · sin perfil en Firestore · loc=$loc');
        return isPublic ? null : '/welcome';
      }

      final esDueno = perfil.esDueno;
      final isAdminRoute = loc.startsWith('/admin');

      debugPrint('[Router] auth=true · uid=${currentUser.uid.substring(0, 6)}… · '
          'rol="${perfil.rol}" · esDueno=$esDueno · loc=$loc');

      if (esDueno) {
        // Si el dueño aún no tiene complejo vinculado → setup obligatorio.
        final tieneComplejo = perfil.complejoId != null &&
            perfil.complejoId!.isNotEmpty;
        if (!tieneComplejo && loc != '/admin/setup-complejo') {
          return '/admin/setup-complejo';
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
      // ── Loading (perfil cargando) ───────────────────────────
      GoRoute(
        path: '/loading',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, _) => const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      ),

      // ── Auth ────────────────────────────────────────────────
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

      // ── Usuario · ShellRoute con bottom navigation ───────────
      ShellRoute(
        navigatorKey: _userShellNavigatorKey,
        builder: (_, _, child) => UserShell(child: child),
        routes: [
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
        ],
      ),

      // ── Rutas usuario fuera del shell (pantallas completas) ─
      GoRoute(
        path: '/complejo/:complejoId',
        name: 'complejoDetalle',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, state) => ComplejoDetalleScreen(
          complejoId: state.pathParameters['complejoId']!,
        ),
      ),
      GoRoute(
        path: '/reservar/:complejoId/:canchaId',
        name: 'reservar',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, state) => ReservarScreen(
          complejoId: state.pathParameters['complejoId']!,
          canchaId: state.pathParameters['canchaId']!,
        ),
      ),
      GoRoute(
        path: '/confirmacion/:reservaId',
        name: 'confirmacion',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, state) => ConfirmacionScreen(
          reservaId: state.pathParameters['reservaId']!,
        ),
      ),
      GoRoute(
        path: '/crear-partido',
        name: 'crearPartido',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, _) => const CrearPartidoScreen(),
      ),
      GoRoute(
        path: '/partido/:partidoId',
        name: 'partidoLive',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, state) => PartidoLiveScreen(
          partidoId: state.pathParameters['partidoId']!,
        ),
      ),
      GoRoute(
        path: '/partido/:partidoId/completado',
        name: 'partidoCompletado',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, state) => PartidoCompletadoScreen(
          partidoId: state.pathParameters['partidoId']!,
        ),
      ),

      // ── Seed / Setup inicial de base de datos ───────────────
      GoRoute(
        path: '/dev/seed',
        name: 'seedDatabase',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, _) => const SeedScreen(),
      ),

      // ── Admin Setup — fuera del shell (pantalla completa) ──
      GoRoute(
        path: '/admin/setup-complejo',
        name: 'adminSetupComplejo',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, _) => const AdminSetupComplejoScreen(),
      ),

      // ── Mi Complejo — edición desde el panel admin ──────
      GoRoute(
        path: '/admin/mi-complejo',
        name: 'adminMiComplejo',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, _) => const AdminMiComplejoScreen(),
      ),

      // ── Canchas — gestión desde el panel admin ───────────
      GoRoute(
        path: '/admin/canchas',
        name: 'adminCanchas',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, _) => const AdminCanchasScreen(),
      ),

      // ── Admin (ShellRoute con bottom nav) ──────────────────
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
          // Rutas auxiliares (no en bottom nav, accesibles vía deep-link/admin)
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
