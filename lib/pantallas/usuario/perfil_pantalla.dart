// screens/usuario/perfil_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../nucleo/tema/app_colores.dart';
import '../../modelos/complejo_modelo.dart';
import '../../modelos/usuario_modelo.dart';
import '../../proveedores/auth_proveedor.dart';
import '../../proveedores/complejos_proveedor.dart';

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
      error: (e, _) => _PerfilError(mensaje: e.toString()),
      data: (perfil) {
        // Perfil null = usuario autenticado pero sin documento Firestore.
        // Mostramos pantalla de error con botón de cerrar sesión para
        // que el usuario no quede atrapado en una pantalla en blanco.
        if (perfil == null) return const _PerfilError();
        if (perfil.esDueno) return _AdminPerfil(perfil: perfil);
        return _JugadorPerfil(perfil: perfil);
      },
    );
  }
}

// ── Pantalla de error / sin perfil ────────────────────────────────────────────
class _PerfilError extends ConsumerWidget {
  final String? mensaje;
  const _PerfilError({this.mensaje});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.accLight,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(Icons.person_off_outlined,
                    color: AppColors.acc, size: 34),
              ),
              const SizedBox(height: 20),
              Text(
                'Perfil no encontrado',
                style: GoogleFonts.bricolageGrotesque(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.tx,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                mensaje ??
                    'Tu perfil no está disponible en este momento.\n'
                    'Cierra sesión e inicia de nuevo.',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  color: AppColors.tx2,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () =>
                      ref.read(authNotifierProvider.notifier).logout(),
                  icon: const Icon(Icons.logout_rounded, size: 18),
                  label: Text(
                    'Cerrar sesión',
                    style: GoogleFonts.outfit(
                        fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.acc,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// JUGADOR — header verde oscuro + cuerpo claro + edición inline
// ─────────────────────────────────────────────────────────────────────────────

class _JugadorPerfil extends ConsumerStatefulWidget {
  final UsuarioModel perfil;
  const _JugadorPerfil({required this.perfil});

  @override
  ConsumerState<_JugadorPerfil> createState() => _JugadorPerfilState();
}

class _JugadorPerfilState extends ConsumerState<_JugadorPerfil> {
  bool _guardando = false;

  // ── Bottom-sheet de edición ──────────────────────────────────────────────
  Future<String?> _editarCampo({
    required String label,
    required String valorActual,
    TextInputType keyboardType = TextInputType.text,
    int? maxLength,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) async {
    final ctrl = TextEditingController(text: valorActual);
    final formKey = GlobalKey<FormState>();

    final resultado = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: Container(
          decoration: const BoxDecoration(
            color: AppColors.bg,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 36),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.tx3,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Editar $label',
                  style: GoogleFonts.bricolageGrotesque(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.tx,
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: ctrl,
                  autofocus: true,
                  keyboardType: keyboardType,
                  maxLength: maxLength,
                  inputFormatters: inputFormatters,
                  textCapitalization: keyboardType == TextInputType.name
                      ? TextCapitalization.words
                      : TextCapitalization.none,
                  decoration: InputDecoration(
                    labelText: label,
                    counterText: '',
                    labelStyle: GoogleFonts.outfit(
                        color: AppColors.tx.withValues(alpha: 0.5)),
                    prefixIcon: const Icon(
                      Icons.edit_outlined,
                      color: AppColors.acc,
                      size: 18,
                    ),
                  ),
                  validator: validator,
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      if (formKey.currentState!.validate()) {
                        Navigator.of(ctx).pop(ctrl.text.trim());
                      }
                    },
                    child: Text(
                      'Guardar',
                      style: GoogleFonts.outfit(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    ctrl.dispose();
    return resultado;
  }

  Future<void> _guardar(UsuarioModel nuevo) async {
    setState(() => _guardando = true);
    try {
      await ref.read(usuariosRepositoryProvider).guardarUsuario(nuevo);
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  // ── Build ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    // Perfil en tiempo real (stream actualiza cuando guardamos)
    final perfilLive =
        ref.watch(perfilUsuarioProvider).asData?.value ?? widget.perfil;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(
        children: [
          // ── Header verde oscuro ──────────────────────────────
          _JugadorHeader(perfil: perfilLive),

          // ── Cuerpo ──────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Sección perfil ─────────────────────
                    Text(
                      'Mi perfil',
                      style: GoogleFonts.bricolageGrotesque(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.tx,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Nombre completo
                    _PerfilTile(
                      iconBg: const Color(0xFFEBFFEF),
                      iconColor: AppColors.acc,
                      icon: Icons.person_outline_rounded,
                      label: 'Nombre completo',
                      value: perfilLive.nombre,
                      onTap: _guardando
                          ? null
                          : () async {
                              final nuevo = await _editarCampo(
                                label: 'Nombre completo',
                                valorActual: perfilLive.nombre,
                                keyboardType: TextInputType.name,
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty) {
                                    return 'Ingresa tu nombre';
                                  }
                                  if (v.trim().length < 3) {
                                    return 'Nombre muy corto';
                                  }
                                  return null;
                                },
                              );
                              if (nuevo != null &&
                                  nuevo != perfilLive.nombre) {
                                final iniciales = nuevo
                                    .split(' ')
                                    .where((w) => w.isNotEmpty)
                                    .take(2)
                                    .map((w) => w[0].toUpperCase())
                                    .join();
                                await _guardar(perfilLive.copyWith(
                                  nombre: nuevo,
                                  iniciales: iniciales,
                                ));
                              }
                            },
                    ),

                    // Teléfono
                    _PerfilTile(
                      iconBg: const Color(0xFFEBF5FF),
                      iconColor: const Color(0xFF3B82F6),
                      icon: Icons.phone_rounded,
                      label: 'Teléfono',
                      value: perfilLive.telefono.isEmpty
                          ? '—'
                          : perfilLive.telefono,
                      onTap: _guardando
                          ? null
                          : () async {
                              final nuevo = await _editarCampo(
                                label: 'Teléfono',
                                valorActual: perfilLive.telefono,
                                keyboardType: TextInputType.phone,
                                maxLength: 12,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                              );
                              if (nuevo != null &&
                                  nuevo != perfilLive.telefono) {
                                await _guardar(
                                    perfilLive.copyWith(telefono: nuevo));
                              }
                            },
                    ),

                    // DNI
                    _PerfilTile(
                      iconBg: const Color(0xFFFFF3E0),
                      iconColor: const Color(0xFFE67E22),
                      icon: Icons.badge_outlined,
                      label: 'DNI',
                      value:
                          perfilLive.dni.isEmpty ? '—' : perfilLive.dni,
                      onTap: _guardando
                          ? null
                          : () async {
                              final nuevo = await _editarCampo(
                                label: 'DNI',
                                valorActual: perfilLive.dni,
                                keyboardType: TextInputType.number,
                                maxLength: 8,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty) {
                                    return 'Ingresa tu DNI';
                                  }
                                  if (v.trim().length != 8) {
                                    return '8 dígitos requeridos';
                                  }
                                  return null;
                                },
                              );
                              if (nuevo != null &&
                                  nuevo != perfilLive.dni) {
                                await _guardar(
                                    perfilLive.copyWith(dni: nuevo));
                              }
                            },
                    ),

                    // Correo (solo lectura)
                    _PerfilTile(
                      iconBg: const Color(0xFFF3E8FF),
                      iconColor: const Color(0xFF7C3AED),
                      icon: Icons.email_outlined,
                      label: 'Correo electrónico',
                      value: perfilLive.email,
                    ),

                    const SizedBox(height: 32),

                    // ── Complejos disponibles ───────────────
                    Text(
                      'Complejos disponibles',
                      style: GoogleFonts.bricolageGrotesque(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.tx,
                      ),
                    ),
                    const SizedBox(height: 12),

                    _ComplejosSection(),

                    const SizedBox(height: 32),

                    // Logout
                    Center(
                      child: TextButton(
                        onPressed: () => ref
                            .read(authNotifierProvider.notifier)
                            .logout(),
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
}

// ─── Header jugador ──────────────────────────────────────────────────────────

class _JugadorHeader extends StatelessWidget {
  final UsuarioModel perfil;
  const _JugadorHeader({required this.perfil});

  static const _headerBg = Color(0xFF0F2419);

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
              // Avatar
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

              // Stats row: DNI | Teléfono
              Row(
                children: [
                  Expanded(
                    child: _HeaderStat(
                      val: perfil.dni.isEmpty ? '—' : perfil.dni,
                      label: 'DNI',
                      fontSize: perfil.dni.isEmpty ? 20 : 17,
                    ),
                  ),
                  _StatDivider(),
                  Expanded(
                    child: _HeaderStat(
                      val: perfil.telefono.isEmpty
                          ? '—'
                          : perfil.telefono,
                      label: 'Teléfono',
                      fontSize: perfil.telefono.isEmpty ? 20 : 15,
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
  final double fontSize;
  const _HeaderStat({
    required this.val,
    required this.label,
    this.fontSize = 20,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          val,
          style: GoogleFonts.bricolageGrotesque(
            fontSize: fontSize,
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

// ─── Tile editable ───────────────────────────────────────────────────────────

class _PerfilTile extends StatelessWidget {
  final Color iconBg;
  final Color iconColor;
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onTap;

  const _PerfilTile({
    required this.iconBg,
    required this.iconColor,
    required this.icon,
    required this.label,
    required this.value,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 2),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        onTap: onTap,
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
          padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
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
        trailing: onTap != null
            ? const Icon(Icons.edit_outlined,
                size: 16, color: AppColors.acc)
            : const Icon(Icons.lock_outline_rounded,
                size: 14, color: AppColors.tx3),
      ),
    );
  }
}

// ─── Sección complejos ───────────────────────────────────────────────────────

class _ComplejosSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final complejosAsync = ref.watch(complejosProvider);

    return complejosAsync.when(
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 24),
          child: CircularProgressIndicator(
            color: AppColors.acc,
            strokeWidth: 2,
          ),
        ),
      ),
      error: (e, _) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(
          'No se pudieron cargar los complejos',
          style: GoogleFonts.outfit(fontSize: 13, color: AppColors.red),
        ),
      ),
      data: (complejos) {
        if (complejos.isEmpty) {
          return Container(
            padding: const EdgeInsets.symmetric(vertical: 24),
            alignment: Alignment.center,
            child: Text(
              'Aún no hay complejos registrados',
              style: GoogleFonts.outfit(
                  fontSize: 13, color: AppColors.tx3),
            ),
          );
        }
        return Column(
          children: complejos
              .map((c) => _ComplejoCard(complejo: c))
              .toList(),
        );
      },
    );
  }
}

class _ComplejoCard extends ConsumerWidget {
  final ComplejoModel complejo;
  const _ComplejoCard({required this.complejo});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canchasAsync = ref.watch(canchasProvider(complejo.id));

    final canchaCount = canchasAsync.when(
      loading: () => '…',
      error: (_, _) => '?',
      data: (list) => '${list.length}',
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FFF8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD1EDD6)),
      ),
      child: Row(
        children: [
          // Ícono complejo
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.acc.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.stadium_outlined,
              size: 22,
              color: AppColors.acc,
            ),
          ),
          const SizedBox(width: 12),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  complejo.nombre,
                  style: GoogleFonts.bricolageGrotesque(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.tx,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined,
                        size: 12, color: AppColors.tx3),
                    const SizedBox(width: 3),
                    Expanded(
                      child: Text(
                        complejo.direccion,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          color: AppColors.tx3,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    const Icon(Icons.access_time_rounded,
                        size: 12, color: AppColors.tx3),
                    const SizedBox(width: 3),
                    Text(
                      '${complejo.horarioApertura} – ${complejo.horarioCierre}',
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        color: AppColors.tx3,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // Canchas badge
          Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.acc.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  canchaCount,
                  style: GoogleFonts.bricolageGrotesque(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.acc,
                  ),
                ),
              ),
              const SizedBox(height: 3),
              Text(
                'canchas',
                style: GoogleFonts.outfit(
                  fontSize: 10,
                  color: AppColors.tx3,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ADMIN — tema oscuro premium (mismo lenguaje visual que dashboard)
// ─────────────────────────────────────────────────────────────────────────────

class _AdminPerfil extends ConsumerWidget {
  final UsuarioModel perfil;
  const _AdminPerfil({required this.perfil});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                              color:
                                  AppColors.ared.withValues(alpha: 0.35)),
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
                      color: AppColors.aacc.withValues(alpha: 0.35),
                      width: 2),
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
