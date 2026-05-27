// screens/usuario/user_shell.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_colors.dart';

/// Shell de la app del jugador con barra de navegación inferior.
/// Envuelve a /inicio, /mapa, /partidos y /perfil.
class UserShell extends StatelessWidget {
  final Widget child;
  const UserShell({super.key, required this.child});

  static const _tabs = <_TabItem>[
    _TabItem(
      route: '/inicio',
      label: 'Inicio',
      icon: Icons.home_outlined,
      iconActive: Icons.home_rounded,
      activeColor: null, // usa green
    ),
    _TabItem(
      route: '/mapa',
      label: 'Mapa',
      icon: Icons.location_on_outlined,
      iconActive: Icons.location_on_rounded,
      activeColor: null, // usa green
    ),
    _TabItem(
      route: '/partidos',
      label: 'Partido',
      icon: Icons.groups_outlined,
      iconActive: Icons.groups_rounded,
      activeColor: 'party', // usa party (azul)
    ),
    _TabItem(
      route: '/perfil',
      label: 'Perfil',
      icon: Icons.person_outline_rounded,
      iconActive: Icons.person_rounded,
      activeColor: null, // usa green
    ),
  ];

  /// Devuelve el índice del tab activo, o -1 si la ruta actual
  /// no corresponde a ningún tab (p.ej. /complejo/:id, /reservar/...).
  int _currentIndex(BuildContext context) {
    final loc = GoRouterState.of(context).matchedLocation;
    for (int i = 0; i < _tabs.length; i++) {
      if (loc.startsWith(_tabs[i].route)) return i;
    }
    return -1; // ruta de detalle/reserva/partido — sin tab activo
  }

  @override
  Widget build(BuildContext context) {
    final selected = _currentIndex(context);
    // El bottom nav solo se muestra cuando estamos en un tab principal.
    final showNav = selected >= 0;

    return Scaffold(
      backgroundColor: AppColors.paper,
      // El body es el contenido de cada ruta (mapa, inicio, detalle, etc.)
      body: child,
      bottomNavigationBar: showNav
          ? _BottomNavBar(
              selectedIndex: selected,
              items: _tabs,
              onTap: (i) {
                if (i == selected) return;
                context.go(_tabs[i].route);
              },
            )
          : null,
    );
  }
}

class _TabItem {
  final String route;
  final String label;
  final IconData icon;
  final IconData iconActive;
  final String? activeColor; // null = verde, 'party' = azul
  const _TabItem({
    required this.route,
    required this.label,
    required this.icon,
    required this.iconActive,
    required this.activeColor,
  });
}

class _BottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final List<_TabItem> items;
  final ValueChanged<int> onTap;

  const _BottomNavBar({
    required this.selectedIndex,
    required this.items,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        height: 62,
        decoration: BoxDecoration(
          color: AppColors.white,
          border: Border(
            top: BorderSide(color: AppColors.line, width: 1),
          ),
        ),
        padding: const EdgeInsets.only(top: 9),
        child: Row(
          children: [
            for (int i = 0; i < items.length; i++)
              Expanded(
                child: _NavItem(
                  item: items[i],
                  selected: i == selectedIndex,
                  onTap: () => onTap(i),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final _TabItem item;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = item.activeColor == 'party'
        ? AppColors.party
        : AppColors.green;
    final color = selected ? activeColor : AppColors.ink3;

    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Icon(
            selected ? item.iconActive : item.icon,
            color: color,
            size: 22,
          ),
          const SizedBox(height: 3),
          Text(
            item.label,
            style: GoogleFonts.outfit(
              fontSize: 9,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          // Pip de "tab activa"
          Container(
            width: 3,
            height: 3,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: selected ? activeColor : Colors.transparent,
            ),
          ),
        ],
      ),
    );
  }
}
