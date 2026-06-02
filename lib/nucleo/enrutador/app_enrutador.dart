// nucleo/enrutador/app_enrutador.dart
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

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();
final _userShellNavigatorKey = GlobalKey<NavigatorState>();

final appRouterProvider = Provider<GoRouter>((ref) {
  // Escuchamos authState Y perfilUsuario.
  // Ahora es seguro escuchar ambos porque las rutas de detalle
  // (/complejo, /reservar...) están en el root navigator — no en el
  // ShellRoute — así que un refresh del perfil ya no destruye la pila
  // de navegación ni causa el redirect /complejo/:id → /inicio.
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
      } catch (_) {}

      final isAuth = currentUser != null;
      final loc = state.matchedLocation;

      const publicRoutes = ['/welcome', '/login', '/registro'];
      final isPublic = publicRoutes.contains(loc);

      // ── No autenticado ───────────────────────────────────────────
      if (!isAuth) {
        return isPublic ? null : '/welcome';
      }

      // ── Autenticado: leer perfil ─────────────────────────────────
      final perfilAsync = ref.read(perfilUsuarioProvider);

      // Perfil aun cargando (stream conectando): ir a /loading y esperar
      // el refresh del perfilUsuarioProvider para continuar.
      if (perfilAsync.asData == null) {
        if (isPublic || loc == '/loading') return '/loading';
        // Ya en una ruta de app: esperar que llegue el perfil.
        // El router se refresca cuando perfilUsuarioProvider emita.
        return '/loading';
      }

      final perfil = perfilAsync.asData!.value;
      final isAdminRoute = loc.startsWith('/admin');

      // Perfil null = documento no existe en Firestore.
      // Puede ser un estado transitorio (recien creado, cache local tarde)
      // o un error real. Esperar otro ciclo de refresh en /loading.
      if (perfil == null) {
        if (isPublic) return '/loading';
        if (loc == '/loading') return null; // esperar
        return '/loading'; // cualquier otra ruta: esperar el perfil
      }

      final esDueno = perfil.esDueno;

      debugPrint('[Router] uid=${currentUser.uid.substring(0, 6)}... '
          'rol="${perfil.rol}" esDueno=$esDueno loc=$loc');

      // ── Dueno ────────────────────────────────────────────────────
      if (esDueno) {
        final tieneComplejo =
            perfil.complejoId != null && perfil.complejoId!.isNotEmpty;
        if (!tieneComplejo && loc != '/admin/setup-complejo') {
          return '/admin/setup-complejo';
        }
        // Rutas de detalle/flujo: duenos tambien pueden acceder.
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

      // ── Jugador ──────────────────────────────────────────────────
      if (!esDueno && isAdminRoute) return '/inicio';
      if (isPublic || loc == '/loading') return '/inicio';

      return null;
    },
    routes: [
      // ── Loading ──────────────────────────────────────────────────
      GoRoute(
        path: '/loading',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, _) => const _LoadingScreen(),
      ),

      // ── Auth ─────────────────────────────────────────────────────
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

      // ── Pantallas de flujo — ROOT NAVIGATOR ──────────────────────
      // Estan en el root navigator para que los refreshes del router
      // (authState) no destruyan la pila y provoquen redirects erroneos.
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

      // ── Usuario · ShellRoute (solo los 4 tabs con bottom nav) ────
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

      // ── Admin Setup (pantallas completas, fuera del shell) ───────
      GoRoute(
        path: '/admin/setup-complejo',
        name: 'adminSetupComplejo',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, _) => const AdminSetupComplejoScreen(),
      ),
      GoRoute(
        path: '/admin/mi-complejo',
        name: 'adminMiComplejo',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, _) => const AdminMiComplejoScreen(),
      ),
      GoRoute(
        path: '/admin/canchas',
        name: 'adminCanchas',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, _) => const AdminCanchasScreen(),
      ),

      // ── Admin · ShellRoute ───────────────────────────────────────
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

// ── Pantalla de carga con escape si el perfil tarda demasiado ─────────────────

class _LoadingScreen extends StatefulWidget {
  const _LoadingScreen();

  @override
  State<_LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<_LoadingScreen> {
  bool _showEscape = false;

  @override
  void initState() {
    super.initState();
    // Después de 6 s sin resolver, mostramos el botón de salida.
    Future.delayed(const Duration(seconds: 6), () {
      if (mounted) setState(() => _showEscape = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            if (_showEscape) ...[
              const SizedBox(height: 32),
              TextButton(
                onPressed: () async {
                  // Cerramos sesión y volvemos a la pantalla de inicio
                  await FirebaseAuth.instance.signOut();
                },
                child: const Text('Volver al inicio'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
