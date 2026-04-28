// screens/usuario/perfil_screen.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';

class PerfilScreen extends ConsumerWidget {
  const PerfilScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final perfilAsync = ref.watch(perfilUsuarioProvider);

    return Scaffold(
      backgroundColor: AppColors.paper,
      body: SafeArea(
        child: perfilAsync.when(
          loading: () =>
              const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (perfil) {
            if (perfil == null) {
              return const Center(child: Text('Sin perfil'));
            }
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Header con avatar ───────────────
                  Center(
                    child: Column(
                      children: [
                        Container(
                          width: 88,
                          height: 88,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [AppColors.green, AppColors.green2],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color:
                                    AppColors.green.withValues(alpha: 0.3),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              perfil.iniciales,
                              style: GoogleFonts.bricolageGrotesque(
                                fontSize: 32,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          perfil.nombre,
                          style: GoogleFonts.bricolageGrotesque(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: AppColors.ink,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          perfil.email,
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            color: AppColors.ink2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: perfil.esAdmin
                                ? AppColors.party.withValues(alpha: 0.1)
                                : AppColors.greenLight,
                            borderRadius: BorderRadius.circular(100),
                          ),
                          child: Text(
                            perfil.esAdmin ? 'Administrador' : 'Jugador',
                            style: GoogleFonts.outfit(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: perfil.esAdmin
                                  ? AppColors.party
                                  : AppColors.green,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  // ── Estadísticas ────────────────────
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          label: 'Reservas',
                          value: '${perfil.totalReservas}',
                          icon: Icons.calendar_month_rounded,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _StatCard(
                          label: 'Gastado',
                          value:
                              'S/${perfil.totalGastado.toStringAsFixed(0)}',
                          icon: Icons.account_balance_wallet_rounded,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // ── Lista de opciones ───────────────
                  Text(
                    'CUENTA',
                    style: GoogleFonts.bricolageGrotesque(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5,
                      color: AppColors.ink3,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.line),
                    ),
                    child: Column(
                      children: [
                        _MenuTile(
                          icon: Icons.person_outline_rounded,
                          label: 'Editar perfil',
                          onTap: () => _todo(context, 'Editar perfil'),
                        ),
                        const Divider(height: 1),
                        _MenuTile(
                          icon: Icons.history_rounded,
                          label: 'Historial de reservas',
                          onTap: () => _todo(context, 'Historial'),
                        ),
                        const Divider(height: 1),
                        _MenuTile(
                          icon: Icons.notifications_outlined,
                          label: 'Notificaciones',
                          onTap: () => _todo(context, 'Notificaciones'),
                        ),
                        const Divider(height: 1),
                        _MenuTile(
                          icon: Icons.help_outline_rounded,
                          label: 'Ayuda y soporte',
                          onTap: () => _todo(context, 'Soporte'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── Cerrar sesión ───────────────────
                  Material(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(16),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (dialogCtx) => AlertDialog(
                            title: const Text('¿Cerrar sesión?'),
                            content: const Text(
                                'Tendrás que iniciar sesión otra vez.'),
                            actions: [
                              TextButton(
                                onPressed: () =>
                                    Navigator.pop(dialogCtx, false),
                                child: const Text('Cancelar'),
                              ),
                              FilledButton(
                                onPressed: () =>
                                    Navigator.pop(dialogCtx, true),
                                style: FilledButton.styleFrom(
                                  backgroundColor: AppColors.errorRed,
                                ),
                                child: const Text('Cerrar sesión'),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true) {
                          // Cerrar sesión. El router detecta el cambio de auth
                          // state y redirige automáticamente a /welcome.
                          await FirebaseAuth.instance.signOut();
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(
                              color: AppColors.errorRed.withValues(alpha: 0.3)),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.logout_rounded,
                                color: AppColors.errorRed, size: 20),
                            const SizedBox(width: 12),
                            Text(
                              'Cerrar sesión',
                              style: GoogleFonts.outfit(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.errorRed,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  void _todo(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$feature: próximamente')),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.green),
          const SizedBox(height: 10),
          Text(
            value,
            style: GoogleFonts.bricolageGrotesque(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 12,
              color: AppColors.ink2,
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _MenuTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: AppColors.ink2, size: 20),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  color: AppColors.ink,
                ),
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                color: AppColors.ink3, size: 20),
          ],
        ),
      ),
    );
  }
}
