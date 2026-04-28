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
import '../../screens/usuario/reservar_screen.dart';
import '../../screens/usuario/user_shell.dart';
import '../../screens/admin/admin_dashboard_screen.dart';
import '../../screens/admin/admin_flash_slots_screen.dart';
import '../../screens/admin/admin_horarios_screen.dart';
import '../../screens/admin/admin_ia_screen.dart';
import '../../screens/admin/admin_ingresos_screen.dart';
import '../../screens/admin/admin_partidos_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();
final _userShellNavigatorKey = GlobalKey<NavigatorState>();

final appRouterProvider = Provider<GoRouter>((ref) {
  // Escucha el estado de autenticación para redirect reactivo
  final authNotifier = ValueNotifier<AsyncValue<User?>>(const AsyncLoading());

  ref.listen(authStateProvider, (_, next) {
    authNotifier.value = next;
  });

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/inicio',
    debugLogDiagnostics: false,
    refreshListenable: authNotifier,
    redirect: (context, state) async {
      User? currentUser;
      try {
        currentUser = FirebaseAuth.instance.currentUser;
      } catch (_) {
        // Firebase no inicializado (stub). Tratar como no autenticado.
      }
      final isAuth = currentUser != null;
      final loc = state.matchedLocation;

      final publicRoutes = ['/welcome', '/login', '/registro'];
      final isPublic = publicRoutes.contains(loc);

      if (!isAuth && !isPublic) return '/welcome';
      if (isAuth && isPublic) {
        // Verificar si es admin
        // El redirect a /admin/dashboard se hace desde perfilUsuarioProvider
        return '/inicio';
      }
      return null;
    },
    routes: [
      // ── Auth ────────────────────────────────────────────────
      GoRoute(
        path: '/welcome',
        name: 'welcome',
        builder: (_, __) => const WelcomeScreen(modoInicial: 'registro'),
      ),
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (_, __) => const WelcomeScreen(modoInicial: 'login'),
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
        builder: (_, __, child) => UserShell(child: child),
        routes: [
          GoRoute(
            path: '/inicio',
            name: 'inicio',
            builder: (_, __) => const InicioScreen(),
          ),
          GoRoute(
            path: '/mapa',
            name: 'mapa',
            builder: (_, __) => const MapaScreen(),
          ),
          GoRoute(
            path: '/partidos',
            name: 'buscarPartidos',
            builder: (_, __) => const BuscarPartidosScreen(),
          ),
          GoRoute(
            path: '/perfil',
            name: 'perfil',
            builder: (_, __) => const PerfilScreen(),
          ),
        ],
      ),

      // ── Rutas usuario fuera del shell (pantallas completas) ─
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
        builder: (_, __) => const CrearPartidoScreen(),
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

      // ── Admin (ShellRoute con nav lateral) ─────────────────
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (_, __, child) => AdminShell(child: child),
        routes: [
          GoRoute(
            path: '/admin',
            redirect: (_, __) => '/admin/dashboard',
          ),
          GoRoute(
            path: '/admin/dashboard',
            name: 'adminDashboard',
            builder: (_, __) => const AdminDashboardScreen(),
          ),
          GoRoute(
            path: '/admin/horarios',
            name: 'adminHorarios',
            builder: (_, __) => const AdminHorariosScreen(),
          ),
          GoRoute(
            path: '/admin/flash-slots',
            name: 'adminFlashSlots',
            builder: (_, __) => const AdminFlashSlotsScreen(),
          ),
          GoRoute(
            path: '/admin/partidos',
            name: 'adminPartidos',
            builder: (_, __) => const AdminPartidosScreen(),
          ),
          GoRoute(
            path: '/admin/ia',
            name: 'adminIA',
            builder: (_, __) => const AdminIAScreen(),
          ),
          GoRoute(
            path: '/admin/ingresos',
            name: 'adminIngresos',
            builder: (_, __) => const AdminIngresosScreen(),
          ),
        ],
      ),
    ],
  );
});

/// Shell de admin con NavigationRail lateral (dark theme).
class AdminShell extends StatelessWidget {
  final Widget child;

  const AdminShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;

    final destinations = [
      ('dashboard', Icons.dashboard_rounded, Icons.dashboard_outlined, 'Panel'),
      ('horarios', Icons.calendar_month_rounded, Icons.calendar_month_outlined, 'Horarios'),
      ('flash-slots', Icons.flash_on_rounded, Icons.flash_on_outlined, 'Flash'),
      ('partidos', Icons.group_rounded, Icons.group_outlined, 'Partidos'),
      ('ia', Icons.auto_awesome_rounded, Icons.auto_awesome_outlined, 'IA'),
      ('ingresos', Icons.bar_chart_rounded, Icons.bar_chart_outlined, 'Ingresos'),
    ];

    int selectedIndex = 0;
    for (int i = 0; i < destinations.length; i++) {
      if (location.contains(destinations[i].$1)) {
        selectedIndex = i;
        break;
      }
    }

    return Theme(
      data: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF080C12),
        navigationRailTheme: const NavigationRailThemeData(
          backgroundColor: Color(0xFF0D1320),
          selectedIconTheme:
              IconThemeData(color: Color(0xFF64D28C), size: 24),
          unselectedIconTheme:
              IconThemeData(color: Color(0xFF4B5563), size: 22),
          selectedLabelTextStyle: TextStyle(
              color: Color(0xFF64D28C),
              fontSize: 11,
              fontWeight: FontWeight.w600),
          unselectedLabelTextStyle:
              TextStyle(color: Color(0xFF4B5563), fontSize: 11),
          indicatorColor: Color(0xFF1A2438),
        ),
      ),
      child: Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: selectedIndex,
              onDestinationSelected: (i) {
                final route = '/admin/${destinations[i].$1}';
                context.go(route);
              },
              labelType: NavigationRailLabelType.all,
              leading: Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Column(
                  children: [
                    const SizedBox(height: 8),
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: const Color(0xFF64D28C).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.sports_soccer_rounded,
                        color: Color(0xFF64D28C),
                        size: 20,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Admin',
                      style: TextStyle(
                        fontSize: 10,
                        color: Color(0xFF64D28C),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              destinations: destinations
                  .map((d) => NavigationRailDestination(
                        icon: Icon(d.$3),
                        selectedIcon: Icon(d.$2),
                        label: Text(d.$4),
                      ))
                  .toList(),
            ),
            const VerticalDivider(
                thickness: 1, width: 1, color: Color(0xFF1E293B)),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}
