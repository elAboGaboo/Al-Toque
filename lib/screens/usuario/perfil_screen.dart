// screens/usuario/perfil_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../models/usuario_model.dart';
import '../../providers/auth_provider.dart';

class PerfilScreen extends ConsumerWidget {
  const PerfilScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final perfilAsync = ref.watch(perfilUsuarioProvider);

    return perfilAsync.when(
      loading: () => const Scaffold(
        backgroundColor: AppColors.bg,
        body: Center(child: CircularProgressIndicator(color: AppColors.acc)),
      ),
      error: (_, _) => const Scaffold(
        backgroundColor: AppColors.bg,
        body: Center(child: Text('Error cargando perfil')),
      ),
      data: (perfil) {
        if (perfil == null) return const SizedBox.shrink();
        if (perfil.esDueno) return _AdminPerfil(perfil: perfil, ref: ref);
        return _JugadorPerfil(perfil: perfil, ref: ref);
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// JUGADOR — diseño con header verde oscuro + cuerpo claro
// ─────────────────────────────────────────────────────────────────────────────

class _JugadorPerfil extends StatelessWidget {
  final UsuarioModel perfil;
  final WidgetRef ref;
  const _JugadorPerfil({required this.perfil, required this.ref});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(
        children: [
          // ── Header verde oscuro ──────────────────────────────
          _Header(perfil: perfil),

          // ── Cuerpo blanco/crema ──────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Mi perfil',
                      style: GoogleFonts.bricolageGrotesque(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.tx,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Deporte favorito
                    _PerfilTile(
                      iconBg: const Color(0xFFEBF5FF),
                      iconColor: const Color(0xFF3B82F6),
                      icon: Icons.sports_soccer_rounded,
                      label: 'Deporte favorito',
                      value:
                          '${_deporteLabel(perfil.deporteFavorito)} · ${perfil.totalReservas} reservas',
                    ),

                    // Método de pago (placeholder)
                    const _PerfilTile(
                      iconBg: Color(0xFFFFF3E0),
                      iconColor: Color(0xFFE67E22),
                      icon: Icons.credit_card_rounded,
                      label: 'Método de pago',
                      value: 'Yape · **** 4821',
                    ),

                    // Total gastado
                    _PerfilTile(
                      iconBg: const Color(0xFFE8F5E9),
                      iconColor: AppColors.acc,
                      icon: Icons.attach_money_rounded,
                      label: 'Total invertido',
                      value: 'S/${perfil.totalGastado.toStringAsFixed(0)}',
                    ),

                    // Email
                    _PerfilTile(
                      iconBg: const Color(0xFFF3E8FF),
                      iconColor: const Color(0xFF7C3AED),
                      icon: Icons.email_outlined,
                      label: 'Correo electrónico',
                      value: perfil.email,
                    ),

                    const SizedBox(height: 32),

                    // Setup base de datos (solo desarrollo)
                    Center(
                      child: TextButton.icon(
                        onPressed: () => context.push('/dev/seed'),
                        icon: const Icon(Icons.dataset_rounded,
                            size: 16, color: AppColors.acc),
                        label: Text(
                          'Poblar base de datos',
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.acc,
                          ),
                        ),
                      ),
                    ),

                    // Logout
                    Center(
                      child: TextButton(
                        onPressed: () =>
                            ref.read(authNotifierProvider.notifier).logout(),
                        child: Text(
                          'Cerrar Sesión',
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.red,
                          ),
                        ),
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
  }

  String _deporteLabel(String deporte) {
    return switch (deporte) {
      'futbol5' => 'Fútbol 5',
      'futbol7' => 'Fútbol 7',
      'futbol11' => 'Fútbol 11',
      'fulbito' => 'Fulbito',
      'basquet' => 'Básquet',
      'voley' => 'Vóley',
      'tenis' => 'Tenis',
      'padel' => 'Pádel',
      _ => deporte,
    };
  }
}

class _Header extends StatelessWidget {
  final UsuarioModel perfil;
  const _Header({required this.perfil});

  static const _headerBg = Color(0xFF0F2419);

  String _nivelLabel(int r) {
    if (r >= 20) return 'MVP';
    if (r >= 10) return 'Pro';
    if (r >= 5) return 'Semi';
    return 'Rookie';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: _headerBg,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
          child: Column(
            children: [
              // Avatar cuadrado redondeado
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  color: AppColors.acc,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.acc.withValues(alpha: 0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    perfil.iniciales,
                    style: GoogleFonts.bricolageGrotesque(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 14),

              // Nombre
              Text(
                perfil.nombre,
                style: GoogleFonts.bricolageGrotesque(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),

              const SizedBox(height: 4),

              // Email
              Text(
                perfil.email,
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  color: Colors.white.withValues(alpha: 0.55),
                ),
              ),

              const SizedBox(height: 24),

              // Stats row
              Row(
                children: [
                  Expanded(
                    child: _HeaderStat(
                      val: '${perfil.totalReservas}',
                      label: 'Reservas',
                    ),
                  ),
                  _StatDivider(),
                  Expanded(
                    child: _HeaderStat(
                      val: _nivelLabel(perfil.totalReservas),
                      label: 'Nivel',
                    ),
                  ),
                  _StatDivider(),
                  Expanded(
                    child: _HeaderStat(
                      val: 'S/${perfil.totalGastado.toStringAsFixed(0)}',
                      label: 'Total',
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

class _StatDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 36,
      color: Colors.white.withValues(alpha: 0.12),
    );
  }
}

class _HeaderStat extends StatelessWidget {
  final String val;
  final String label;
  const _HeaderStat({required this.val, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          val,
          style: GoogleFonts.bricolageGrotesque(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 12,
            color: Colors.white.withValues(alpha: 0.5),
          ),
        ),
      ],
    );
  }
}

class _PerfilTile extends StatelessWidget {
  final Color iconBg;
  final Color iconColor;
  final IconData icon;
  final String label;
  final String value;

  const _PerfilTile({
    required this.iconBg,
    required this.iconColor,
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 2),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: iconBg,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 20, color: iconColor),
        ),
        title: Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 12,
            color: AppColors.tx3,
          ),
        ),
        subtitle: Container(
          margin: const EdgeInsets.only(top: 4),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: const Color(0xFF0F2419),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios_rounded,
          size: 14,
          color: AppColors.tx3,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ADMIN — tema oscuro premium (mismo lenguaje visual que dashboard)
// ─────────────────────────────────────────────────────────────────────────────

class _AdminPerfil extends StatelessWidget {
  final UsuarioModel perfil;
  final WidgetRef ref;
  const _AdminPerfil({required this.perfil, required this.ref});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.abg,
      body: Column(
        children: [
          // ── Header oscuro ────────────────────────────────────
          _AdminHeader(perfil: perfil),

          // ── Cuerpo ───────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Sección cuenta
                    _SectionLabel('Mi cuenta'),
                    const SizedBox(height: 12),

                    _AdminTile(
                      iconColor: AppColors.aacc,
                      iconBg: AppColors.aaccD,
                      icon: Icons.email_outlined,
                      label: 'Email',
                      value: perfil.email,
                    ),
                    if (perfil.complejoId != null)
                      _AdminTile(
                        iconColor: AppColors.aamber,
                        iconBg: const Color(0x1FFFB547),
                        icon: Icons.stadium_outlined,
                        label: 'Complejo gestionado',
                        value: perfil.complejoId!,
                      ),
                    _AdminTile(
                      iconColor: AppColors.ablu,
                      iconBg: const Color(0x1F5B8EFF),
                      icon: Icons.verified_user_outlined,
                      label: 'Rol',
                      value: 'Administrador',
                      valueColor: AppColors.aacc,
                    ),

                    const SizedBox(height: 28),

                    // Sección configuración
                    _SectionLabel('Configuración'),
                    const SizedBox(height: 12),

                    _AdminTile(
                      iconColor: AppColors.atx2,
                      iconBg: AppColors.asur3,
                      icon: Icons.notifications_none_rounded,
                      label: 'Notificaciones push',
                      value: 'Activadas',
                    ),
                    _AdminTile(
                      iconColor: AppColors.atx2,
                      iconBg: AppColors.asur3,
                      icon: Icons.security_outlined,
                      label: 'Seguridad',
                      value: 'Contraseña y acceso',
                    ),
                    _AdminTile(
                      iconColor: AppColors.atx2,
                      iconBg: AppColors.asur3,
                      icon: Icons.help_outline_rounded,
                      label: 'Soporte técnico',
                      value: 'soporte@altoque.pe',
                    ),

                    const SizedBox(height: 36),

                    // Logout
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () =>
                            ref.read(authNotifierProvider.notifier).logout(),
                        icon: const Icon(
                          Icons.logout_rounded,
                          size: 18,
                          color: AppColors.ared,
                        ),
                        label: Text(
                          'Cerrar Sesión',
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.ared,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                              color: AppColors.ared.withValues(alpha: 0.35)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
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
  }
}

class _AdminHeader extends StatelessWidget {
  final UsuarioModel perfil;
  const _AdminHeader({required this.perfil});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppColors.asur,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
        border: Border(
          bottom: BorderSide(color: AppColors.abdr2),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
          child: Column(
            children: [
              // Avatar
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  color: AppColors.aaccD,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                      color: AppColors.aacc.withValues(alpha: 0.35), width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.aacc.withValues(alpha: 0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    perfil.iniciales,
                    style: GoogleFonts.bricolageGrotesque(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: AppColors.aacc,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 14),

              // Nombre
              Text(
                perfil.nombre,
                style: GoogleFonts.bricolageGrotesque(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.atx,
                ),
              ),

              const SizedBox(height: 8),

              // Badge admin
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.aaccD,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: AppColors.aacc.withValues(alpha: 0.25)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: AppColors.aacc,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.aacc.withValues(alpha: 0.7),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 7),
                    Text(
                      'Administrador · Al Toque',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.aacc,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Stats admin
              Row(
                children: [
                  Expanded(
                    child: _AdminStat(
                      val: perfil.complejoId != null ? '1' : '—',
                      label: 'Complejo',
                    ),
                  ),
                  _AdminStatDivider(),
                  const Expanded(
                    child: _AdminStat(val: 'Admin', label: 'Rol'),
                  ),
                  _AdminStatDivider(),
                  const Expanded(
                    child: _AdminStat(val: 'Activo', label: 'Estado'),
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

class _AdminStatDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 36,
      color: AppColors.abdr2,
    );
  }
}

class _AdminStat extends StatelessWidget {
  final String val;
  final String label;
  const _AdminStat({required this.val, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          val,
          style: GoogleFonts.bricolageGrotesque(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.aacc,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 12,
            color: AppColors.atx2,
          ),
        ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: GoogleFonts.outfit(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: AppColors.atx3,
        letterSpacing: 1.2,
      ),
    );
  }
}

class _AdminTile extends StatelessWidget {
  final Color iconBg;
  final Color iconColor;
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _AdminTile({
    required this.iconBg,
    required this.iconColor,
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.asur2,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.abdr2),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 20, color: iconColor),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    color: AppColors.atx3,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: valueColor ?? AppColors.atx,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.arrow_forward_ios_rounded,
              size: 12, color: AppColors.atx3),
        ],
      ),
    );
  }
}

