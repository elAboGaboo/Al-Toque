// screens/usuario/inicio_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';

/// Home / feed del jugador. Muestra saludo personalizado + accesos rápidos
/// a Flash Slots, Partidos abiertos y Mapa.
class InicioScreen extends ConsumerWidget {
  const InicioScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final perfil = ref.watch(perfilUsuarioProvider).valueOrNull;
    final nombre = perfil?.nombre.split(' ').first ?? 'jugador';

    return Scaffold(
      backgroundColor: AppColors.paper,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Saludo ────────────────────────────────
              Text(
                'Hola, $nombre 👋',
                style: GoogleFonts.bricolageGrotesque(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '¿Listo para jugar hoy?',
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  color: AppColors.ink2,
                ),
              ),
              const SizedBox(height: 24),

              // ── Card Flash Slots ──────────────────────
              _FeatureCard(
                gradient: const [Color(0xFFF59E0B), Color(0xFFC05E00)],
                icon: '⚡',
                eyebrow: 'FLASH SLOTS',
                title: 'Canchas con descuento\nahora mismo',
                subtitle: 'Hasta –30% por hueco libre',
                ctaText: 'Ver Flash Slots',
                onTap: () => context.go('/mapa'),
              ),
              const SizedBox(height: 12),

              // ── Card Armar partido ────────────────────
              _FeatureCard(
                gradient: const [Color(0xFF3B82F6), Color(0xFF1E40AF)],
                icon: '👥',
                eyebrow: 'ARMAR PARTIDO',
                title: 'Únete o crea un\npartido cerca',
                subtitle: 'Pago dividido automático',
                ctaText: 'Buscar partidos',
                onTap: () => context.go('/partidos'),
              ),
              const SizedBox(height: 24),

              // ── Accesos rápidos ───────────────────────
              Text(
                'Accesos rápidos',
                style: GoogleFonts.bricolageGrotesque(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                  color: AppColors.ink3,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _QuickAction(
                      icon: Icons.location_on_rounded,
                      label: 'Mapa',
                      color: AppColors.green,
                      onTap: () => context.go('/mapa'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _QuickAction(
                      icon: Icons.add_circle_outline_rounded,
                      label: 'Crear partido',
                      color: AppColors.party,
                      onTap: () => context.push('/crear-partido'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _QuickAction(
                      icon: Icons.qr_code_2_rounded,
                      label: 'Mis reservas',
                      color: AppColors.ink,
                      onTap: () => context.go('/perfil'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _QuickAction(
                      icon: Icons.search_rounded,
                      label: 'Buscar partidos',
                      color: AppColors.party,
                      onTap: () => context.go('/partidos'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final List<Color> gradient;
  final String icon;
  final String eyebrow;
  final String title;
  final String subtitle;
  final String ctaText;
  final VoidCallback onTap;

  const _FeatureCard({
    required this.gradient,
    required this.icon,
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    required this.ctaText,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: gradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: gradient.last.withValues(alpha: 0.3),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(icon, style: const TextStyle(fontSize: 38)),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      eyebrow,
                      style: GoogleFonts.bricolageGrotesque(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      title,
                      style: GoogleFonts.bricolageGrotesque(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              const Icon(
                Icons.arrow_forward_rounded,
                color: Colors.white,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 14),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.line),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(height: 8),
              Text(
                label,
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.ink,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
