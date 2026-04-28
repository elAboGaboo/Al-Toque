// screens/auth/welcome_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';

/// Pantalla unificada de bienvenida.
/// Tiene dos modos:
///   • 'registro' — selector de rol + botón Continuar (lleva a /registro)
///   • 'login'    — formulario email/password
/// El usuario alterna entre los dos modos con un link al pie.
class WelcomeScreen extends ConsumerStatefulWidget {
  /// 'registro' (por defecto) o 'login'
  final String modoInicial;
  const WelcomeScreen({super.key, this.modoInicial = 'registro'});

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen> {
  late String _modo; // 'registro' | 'login'

  // ── Estado de registro ────────────────────────────
  String _rolSeleccionado = 'jugador';

  // ── Estado de login ───────────────────────────────
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _modo = widget.modoInicial;
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  void _switchModo(String nuevoModo) {
    if (_loading) return;
    setState(() => _modo = nuevoModo);
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    await ref.read(authNotifierProvider.notifier).login(
          email: _emailCtrl.text.trim(),
          password: _passCtrl.text,
        );

    if (!mounted) return;
    final state = ref.read(authNotifierProvider);
    if (state.hasError) {
      _mostrarError(state.error.toString());
      setState(() => _loading = false);
    }
    // El GoRouter maneja la navegación al detectar el cambio de auth state
  }

  void _mostrarError(String raw) {
    final lower = raw.toLowerCase();
    String msg;
    if (lower.contains('invalid-credential') ||
        lower.contains('user-not-found') ||
        lower.contains('wrong-password')) {
      msg = 'Correo o contraseña incorrectos';
    } else if (lower.contains('invalid-email')) {
      msg = 'Correo inválido';
    } else if (lower.contains('too-many-requests')) {
      msg = 'Demasiados intentos. Espera unos minutos.';
    } else if (lower.contains('network-request-failed') ||
        lower.contains('network_request_failed')) {
      msg = 'Sin conexión a internet';
    } else if (lower.contains('configuration-not-found') ||
        lower.contains('configuration_not_found') ||
        lower.contains('operation-not-allowed')) {
      msg = 'Email/Password no habilitado en Firebase Console';
    } else {
      msg = raw.length > 200 ? '${raw.substring(0, 200)}…' : raw;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.outfit()),
        backgroundColor: AppColors.errorRed,
        duration: const Duration(seconds: 5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final esLogin = _modo == 'login';

    return Scaffold(
      backgroundColor: AppColors.adminBg,
      // Importante: false para que el form no se reduzca cuando aparece el teclado.
      // En su lugar, el SingleChildScrollView se encarga del scroll.
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          // ── Glow verde radial detrás ───────────────────
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0, -0.6),
                    radius: 1.2,
                    colors: [
                      AppColors.adminGreen.withValues(alpha: 0.18),
                      AppColors.adminBg.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: MediaQuery.of(context).size.height -
                      MediaQuery.of(context).padding.top -
                      MediaQuery.of(context).padding.bottom,
                ),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 28),

                      // ── Logo + Wordmark (compartido) ───
                      _buildHeader(),

                      const SizedBox(height: 36),

                      // ── Cuerpo: registro o login ───────
                      Expanded(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 280),
                          switchInCurve: Curves.easeOutCubic,
                          switchOutCurve: Curves.easeInCubic,
                          transitionBuilder: (child, animation) {
                            return FadeTransition(
                              opacity: animation,
                              child: SlideTransition(
                                position: Tween<Offset>(
                                  begin: const Offset(0, 0.04),
                                  end: Offset.zero,
                                ).animate(animation),
                                child: child,
                              ),
                            );
                          },
                          child: esLogin
                              ? _buildLoginForm(
                                  key: const ValueKey('login'))
                              : _buildRegistroForm(
                                  key: const ValueKey('registro')),
                        ),
                      ),

                      // ── Link de toggle al pie ──────────
                      _buildToggleLink(esLogin),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════
  //  HEADER (logo + wordmark)
  // ════════════════════════════════════════════════════
  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: AppColors.adminGreen,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.adminGreen.withValues(alpha: 0.4),
                blurRadius: 32,
                spreadRadius: 4,
              ),
            ],
          ),
          child: const Icon(
            Icons.sports_soccer_rounded,
            color: Colors.black,
            size: 38,
          ),
        ),
        const SizedBox(height: 16),
        RichText(
          text: TextSpan(
            style: GoogleFonts.bricolageGrotesque(
              fontSize: 38,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              height: 1,
            ),
            children: [
              const TextSpan(text: 'Can'),
              TextSpan(
                text: 'cha',
                style: TextStyle(color: AppColors.adminGreen),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Complejos Deportivos · Huancayo',
          style: GoogleFonts.outfit(
            fontSize: 13,
            color: Colors.white.withValues(alpha: 0.55),
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  // ════════════════════════════════════════════════════
  //  MODO REGISTRO — selector de rol
  // ════════════════════════════════════════════════════
  Widget _buildRegistroForm({Key? key}) {
    return Column(
      key: key,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Spacer(flex: 1),

        Text(
          '¿Cómo usarás\nCanchApp?',
          textAlign: TextAlign.center,
          style: GoogleFonts.bricolageGrotesque(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            height: 1.15,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Elige tu rol para personalizar tu experiencia',
          textAlign: TextAlign.center,
          style: GoogleFonts.outfit(
            fontSize: 13,
            color: Colors.white.withValues(alpha: 0.55),
          ),
        ),

        const SizedBox(height: 28),

        _RoleCard(
          icon: Icons.person_rounded,
          title: 'Soy jugador',
          subtitle: 'Busca canchas, reserva y paga en segundos',
          selected: _rolSeleccionado == 'jugador',
          onTap: () => setState(() => _rolSeleccionado = 'jugador'),
        ),
        const SizedBox(height: 12),
        _RoleCard(
          icon: Icons.dashboard_rounded,
          title: 'Soy administrador',
          subtitle: 'Gestiona tu complejo y maximiza ingresos con IA',
          selected: _rolSeleccionado == 'admin',
          onTap: () => setState(() => _rolSeleccionado = 'admin'),
        ),

        const Spacer(flex: 2),

        _PrimaryButton(
          label: 'Continuar',
          icon: Icons.arrow_forward_rounded,
          onTap: () => context.push('/registro?rol=$_rolSeleccionado'),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  // ════════════════════════════════════════════════════
  //  MODO LOGIN — email + password
  // ════════════════════════════════════════════════════
  Widget _buildLoginForm({Key? key}) {
    return Form(
      key: _formKey,
      child: Column(
        key: key,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Spacer(flex: 1),

          Text(
            'Bienvenido\nde vuelta',
            textAlign: TextAlign.center,
            style: GoogleFonts.bricolageGrotesque(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Inicia sesión para reservar tu cancha',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 13,
              color: Colors.white.withValues(alpha: 0.55),
            ),
          ),

          const SizedBox(height: 28),

          _DarkTextField(
            controller: _emailCtrl,
            label: 'Correo electrónico',
            icon: Icons.mail_outline_rounded,
            keyboardType: TextInputType.emailAddress,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Ingresa tu correo';
              if (!v.contains('@')) return 'Correo inválido';
              return null;
            },
          ),
          const SizedBox(height: 12),
          _DarkTextField(
            controller: _passCtrl,
            label: 'Contraseña',
            icon: Icons.lock_outline_rounded,
            obscureText: _obscure,
            suffix: IconButton(
              icon: Icon(
                _obscure
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: Colors.white.withValues(alpha: 0.5),
                size: 20,
              ),
              onPressed: () => setState(() => _obscure = !_obscure),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Ingresa tu contraseña';
              return null;
            },
          ),

          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Recuperación de contraseña: próximamente'),
                  ),
                );
              },
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                '¿Olvidaste tu contraseña?',
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  color: AppColors.adminGreen,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),

          const Spacer(flex: 2),

          _PrimaryButton(
            label: _loading ? 'Iniciando sesión…' : 'Iniciar sesión',
            icon: _loading ? null : Icons.login_rounded,
            loading: _loading,
            onTap: _loading ? null : _login,
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════
  //  TOGGLE link
  // ════════════════════════════════════════════════════
  Widget _buildToggleLink(bool esLogin) {
    return Center(
      child: TextButton(
        onPressed: () => _switchModo(esLogin ? 'registro' : 'login'),
        child: RichText(
          text: TextSpan(
            style: GoogleFonts.outfit(
              fontSize: 13,
              color: Colors.white.withValues(alpha: 0.55),
            ),
            children: [
              TextSpan(
                text: esLogin
                    ? '¿Aún no tienes cuenta? '
                    : '¿Ya tienes cuenta? ',
              ),
              TextSpan(
                text: esLogin ? 'Crear cuenta' : 'Iniciar sesión',
                style: TextStyle(
                  color: AppColors.adminGreen,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
//  Sub-widgets reutilizables
// ═══════════════════════════════════════════════════════

class _RoleCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  const _RoleCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.adminGreen.withValues(alpha: 0.08)
                : AppColors.adminS1.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected
                  ? AppColors.adminGreen
                  : AppColors.adminBorder.withValues(alpha: 0.4),
              width: selected ? 1.5 : 1,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: AppColors.adminGreen.withValues(alpha: 0.15),
                      blurRadius: 16,
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.adminGreen.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppColors.adminGreen, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.55),
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                child: selected
                    ? Container(
                        key: const ValueKey('selected'),
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          color: AppColors.adminGreen,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check_rounded,
                          color: Colors.black,
                          size: 14,
                        ),
                      )
                    : Container(
                        key: const ValueKey('unselected'),
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.3),
                            width: 1.5,
                          ),
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

class _DarkTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final Widget? suffix;

  const _DarkTextField({
    required this.controller,
    required this.label,
    required this.icon,
    this.obscureText = false,
    this.keyboardType,
    this.validator,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      style: GoogleFonts.outfit(
        fontSize: 14,
        color: Colors.white,
        fontWeight: FontWeight.w500,
      ),
      cursorColor: AppColors.adminGreen,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.outfit(
          fontSize: 13,
          color: Colors.white.withValues(alpha: 0.55),
        ),
        prefixIcon: Icon(
          icon,
          color: Colors.white.withValues(alpha: 0.5),
          size: 20,
        ),
        suffixIcon: suffix,
        filled: true,
        fillColor: AppColors.adminS1.withValues(alpha: 0.7),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: AppColors.adminBorder.withValues(alpha: 0.4),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: AppColors.adminBorder.withValues(alpha: 0.4),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppColors.adminGreen, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppColors.errorRed),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppColors.errorRed, width: 1.5),
        ),
        errorStyle: GoogleFonts.outfit(
          fontSize: 11,
          color: AppColors.errorRed,
        ),
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onTap;
  final bool loading;

  const _PrimaryButton({
    required this.label,
    this.icon,
    required this.onTap,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null;
    return SizedBox(
      height: 56,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: LinearGradient(
            colors: disabled
                ? [
                    AppColors.adminGreen.withValues(alpha: 0.4),
                    AppColors.adminGreen.withValues(alpha: 0.3),
                  ]
                : [
                    AppColors.adminGreen,
                    AppColors.adminGreen.withValues(alpha: 0.85),
                  ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: disabled
              ? null
              : [
                  BoxShadow(
                    color: AppColors.adminGreen.withValues(alpha: 0.45),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(28),
            onTap: onTap,
            child: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (loading)
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        color: Colors.black,
                      ),
                    )
                  else
                    Text(
                      label,
                      style: GoogleFonts.outfit(
                        color: Colors.black,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  if (!loading && icon != null) ...[
                    const SizedBox(width: 8),
                    Icon(icon, size: 18, color: Colors.black),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
