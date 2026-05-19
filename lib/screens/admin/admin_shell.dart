// screens/admin/admin_shell.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_colors.dart';

/// Shell admin con barra de navegación inferior (dark premium).
class AdminShell extends StatelessWidget {
  final Widget child;
  const AdminShell({super.key, required this.child});

  static const _tabs = <_AdminTab>[
    _AdminTab(
      route: '/admin/dashboard',
      label: 'Dashboard',
      icon: Icons.dashboard_outlined,
      iconActive: Icons.dashboard_rounded,
    ),
    _AdminTab(
      route: '/admin/horarios',
      label: 'Horarios',
      icon: Icons.calendar_month_outlined,
      iconActive: Icons.calendar_month_rounded,
    ),
    _AdminTab(
      route: '/admin/ia',
      label: 'IA',
      icon: Icons.monitor_heart_outlined,
      iconActive: Icons.monitor_heart_rounded,
    ),
    _AdminTab(
      route: '/admin/precios',
      label: 'Precios',
      icon: Icons.attach_money_rounded,
      iconActive: Icons.attach_money_rounded,
    ),
    _AdminTab(
      route: '/admin/usuarios',
      label: 'Usuarios',
      icon: Icons.person_outline_rounded,
      iconActive: Icons.person_rounded,
    ),
  ];

  int _currentIndex(BuildContext context) {
    final loc = GoRouterState.of(context).matchedLocation;
    for (int i = 0; i < _tabs.length; i++) {
      if (loc.startsWith(_tabs[i].route)) return i;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final selected = _currentIndex(context);

    return Scaffold(
      backgroundColor: AppColors.abg,
      body: child,
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          height: 72,
          decoration: BoxDecoration(
            color: AppColors.asur,
            border: Border(
              top: BorderSide(color: AppColors.abdr2, width: 0.5),
            ),
          ),
          padding: const EdgeInsets.only(top: 10),
          child: Row(
            children: [
              for (int i = 0; i < _tabs.length; i++)
                Expanded(
                  child: _AdminNavItem(
                    tab: _tabs[i],
                    selected: i == selected,
                    onTap: () {
                      if (i == selected) return;
                      context.go(_tabs[i].route);
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AdminTab {
  final String route;
  final String label;
  final IconData icon;
  final IconData iconActive;
  const _AdminTab({
    required this.route,
    required this.label,
    required this.icon,
    required this.iconActive,
  });
}

class _AdminNavItem extends StatelessWidget {
  final _AdminTab tab;
  final bool selected;
  final VoidCallback onTap;

  const _AdminNavItem({
    required this.tab,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.aacc : AppColors.atx3;
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Icon(
            selected ? tab.iconActive : tab.icon,
            color: color,
            size: 22,
          ),
          const SizedBox(height: 4),
          Text(
            tab.label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          // Indicador de tab activa
          Container(
            width: selected ? 18 : 0,
            height: 2,
            decoration: BoxDecoration(
              color: AppColors.aacc,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }
}
