// screens/auth/welcome_screen.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../nucleo/tema/app_colores.dart';
import '../../proveedores/auth_proveedor.dart';

/// Pantalla unificada de auth con 2 modos internos:
///   'roles' — selector de rol con CTAs separados por rol
///   'login' — formulario email/password (ambos roles)
class WelcomeScreen extends ConsumerStatefulWidget {
  final String modoInicial;
  const WelcomeScreen({super.key, this.modoInicial = 'roles'});

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen> {
  late String _modo; // 'roles' | 'login'

  // Login
  final _loginKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;
  bool _loadingLogin = false;

  /// Rol esperado para el login actual: 'jugador' | 'dueno' | null
  String? _rolLogin;

  @override
  void initState() {
    super.initState();
    _modo = widget.modoInicial == 'login' ? 'login' : 'roles';
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  void _irA(String modo, {String? rol}) =>
      setState(() { _modo = modo; if (rol != null) _rolLogin = rol; });

  void _volverARoles() => setState(() { _modo = 'roles'; _rolLogin = null; });

  // ── LOGIN ──────────────────────────────────────────────
  Future<void> _login() async {
    if (!_loginKey.currentState!.validate()) return;
    setState(() => _loadingLogin = true);

    await ref.read(authNotifierProvider.notifier).login(
          email: _emailCtrl.text.trim(),
          password: _passCtrl.text,
        );

    if (!mounted) return;
    final st = ref.read(authNotifierProvider);
    if (st.hasError) {
      _mostrarError(st.error.toString());
      setState(() => _loadingLogin = false);
      return;
    }

    // ── Validar que el rol de la cuenta coincide con el acceso elegido ──
    if (_rolLogin != null) {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final perfil = await ref
            .read(usuariosRepositoryProvider)
            .getUsuario(user.uid);

        if (!mounted) return;

        if (perfil != null && perfil.rol != _rolLogin) {
          // Rol incorrecto → cerrar sesión y mostrar error descriptivo
          await ref.read(authNotifierProvider.notifier).logout();
          if (!mounted) return;
          final esperado = _rolLogin == 'jugador' ? 'jugador' : 'dueño';
          final incorrecto = _rolLogin == 'jugador' ? 'dueño de complejo' : 'jugador';
          final seccion = _rolLogin == 'jugador'
              ? '"Tengo un complejo → Ingresar"'
              : '"Soy jugador → Ingresar"';
          _mostrarError(
            'Esta cuenta es de $incorrecto, no de $esperado. '
            'Para ingresar con esta cuenta usa $seccion.',
          );
          setState(() => _loadingLogin = false);
          return;
        }
      }
    }

    // GoRouter maneja la navegación al detectar el cambio de authState
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
        lower.contains('operation-not-allowed')) {
      msg = 'Email/Password no habilitado en Firebase Console';
    } else {
      msg = raw.length > 200 ? '${raw.substring(0, 200)}…' : raw;
    }
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.outfit()),
      backgroundColor: AppColors.errorRed,
      duration: const Duration(seconds: 5),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.abg,
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          // ── Orbes decorativos ────────────────────────
          Positioned(
            top: -70, right: -70,
            child: Container(
              width: 240, height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  AppColors.aacc.withValues(alpha: 0.1),
                  Colors.transparent,
                ]),
              ),
            ),
          ),
          Positioned(
            bottom: 120, left: -90,
            child: Container(
              width: 220, height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  AppColors.acc.withValues(alpha: 0.12),
                  Colors.transparent,
                ]),
              ),
            ),
          ),

          SafeArea(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 280),
              child: _buildCurrentMode(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentMode() {
    switch (_modo) {
      case 'login':
        return _buildLogin(key: const ValueKey('login'));
      default:
        return _buildRoles(key: const ValueKey('roles'));
    }
  }

  // ════════════════════════════════════════════════════
  //  MODO ROLES
  // ════════════════════════════════════════════════════
  Widget _buildRoles({Key? key}) {
    return SingleChildScrollView(
      key: key,
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 32),
          _buildEyebrow(),
          const SizedBox(height: 20),
          _buildHeader(),
          const SizedBox(height: 40),

          // ── Jugador ──────────────────────────────────
          _RoleSection(
            icon: Icons.person_rounded,
            title: 'Soy jugador',
            subtitle: 'Busca canchas, reserva y arma partidos en segundos',
            color: AppColors.aacc,
            onCrearCuenta: () => context.push('/registro?rol=jugador'),
            onIngresarLabel: 'Ya tengo cuenta → Ingresar',
            onIngresar: () => _irA('login', rol: 'jugador'),
          ),

          const SizedBox(height: 16),

          // ── Administrador ────────────────────────────
          _RoleSection(
            icon: Icons.stadium_rounded,
            title: 'Tengo un complejo',
            subtitle: 'Gestiona tu complejo deportivo con IA y analytics',
            color: AppColors.ablu,
            crearCuentaLabel: 'Registrar mi complejo',
            onCrearCuenta: () => context.push('/registro?rol=dueno'),
            onIngresarLabel: 'Ya tengo cuenta → Ingresar',
            onIngresar: () => _irA('login', rol: 'dueno'),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════
  //  MODO LOGIN
  // ════════════════════════════════════════════════════
  Widget _buildLogin({Key? key}) {
    return SingleChildScrollView(
      key: key,
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Form(
        key: _loginKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 28),
            _buildBackButton(_volverARoles),
            const SizedBox(height: 24),
            _buildHeader(),
            const SizedBox(height: 36),

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
              _rolLogin == 'dueno'
                  ? 'Acceso para dueños de complejo'
                  : _rolLogin == 'jugador'
                      ? 'Acceso para jugadores'
                      : 'Inicia sesión con tu cuenta registrada',
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
                onPressed: _mostrarResetDialog,
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

            const SizedBox(height: 32),

            _PrimaryButton(
              label: _loadingLogin ? 'Iniciando sesión…' : 'Iniciar sesión',
              icon: _loadingLogin ? null : Icons.login_rounded,
              loading: _loadingLogin,
              onTap: _loadingLogin ? null : _login,
            ),
            const SizedBox(height: 20),

            Center(
              child: TextButton(
                onPressed: () {
                  if (_rolLogin != null) {
                    context.push('/registro?rol=$_rolLogin');
                  } else {
                    _volverARoles();
                  }
                },
                child: Text(
                  '¿No tienes cuenta? Regístrate aquí',
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.55),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // ── Shared widgets ─────────────────────────────────

  Widget _buildEyebrow() {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.aacc.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(100),
          border: Border.all(color: AppColors.aacc.withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6, height: 6,
              decoration: const BoxDecoration(
                  color: AppColors.aacc, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            Text(
              'DISEÑO PREMIUM · AL TOQUE 2026',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 10, fontWeight: FontWeight.w700,
                color: AppColors.aacc, letterSpacing: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: 64, height: 64,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.acc, AppColors.acc2],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.aacc.withValues(alpha: 0.35),
                blurRadius: 32, offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(Icons.sports_soccer_rounded,
              color: Colors.white, size: 32),
        ),
        const SizedBox(height: 14),
        RichText(
          text: TextSpan(
            style: GoogleFonts.bricolageGrotesque(
              fontSize: 32, fontWeight: FontWeight.w700,
              color: AppColors.atx, letterSpacing: -1,
            ),
            children: [
              const TextSpan(text: 'Al '),
              const TextSpan(
                text: 'Toque',
                style: TextStyle(color: AppColors.aacc),
              ),
            ],
          ),
        ),
        const SizedBox(height: 3),
        Text(
          'Complejos Deportivos · Huancayo',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12, color: AppColors.atx2, fontWeight: FontWeight.w300,
          ),
        ),
      ],
    );
  }

  Widget _buildBackButton(VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.arrow_back_ios_new_rounded,
              size: 14, color: Colors.white.withValues(alpha: 0.5)),
          const SizedBox(width: 6),
          Text(
            'Volver',
            style: GoogleFonts.outfit(
              fontSize: 13, color: Colors.white.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }

  void _mostrarResetDialog() {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.asur,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Recuperar contraseña',
            style: GoogleFonts.bricolageGrotesque(
                fontWeight: FontWeight.w700,
                fontSize: 18,
                color: AppColors.atx)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Te enviaremos un enlace a tu correo para restablecer tu contraseña.',
              style: GoogleFonts.outfit(fontSize: 14, color: AppColors.atx2),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: ctrl,
              style: GoogleFonts.outfit(color: AppColors.atx),
              decoration: InputDecoration(
                labelText: 'Correo electrónico',
                labelStyle: GoogleFonts.outfit(color: AppColors.atx3),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancelar',
                style: GoogleFonts.outfit(color: AppColors.atx3)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.adminGreen,
                foregroundColor: Colors.black),
            onPressed: () async {
              Navigator.pop(ctx);
              await ref
                  .read(authNotifierProvider.notifier)
                  .resetPassword(ctrl.text);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('Enlace enviado a ${ctrl.text}',
                      style: GoogleFonts.outfit()),
                  backgroundColor: AppColors.adminGreen,
                ));
              }
            },
            child: Text('Enviar', style: GoogleFonts.outfit()),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
//  _RoleSection — card completa de un rol
// ═══════════════════════════════════════════════════════
class _RoleSection extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final String crearCuentaLabel;
  final VoidCallback onCrearCuenta;
  final String onIngresarLabel;
  final VoidCallback onIngresar;

  const _RoleSection({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    this.crearCuentaLabel = 'Crear cuenta',
    required this.onCrearCuenta,
    required this.onIngresarLabel,
    required this.onIngresar,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.adminS1.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.adminBorder.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header del rol
          Row(
            children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: GoogleFonts.outfit(
                          fontSize: 16, fontWeight: FontWeight.w700,
                          color: Colors.white,
                        )),
                    Text(subtitle,
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.5),
                          height: 1.3,
                        )),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Botón principal
          SizedBox(
            width: double.infinity,
            height: 46,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                gradient: LinearGradient(
                  colors: [color, color.withValues(alpha: 0.8)],
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.35),
                    blurRadius: 16, offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: onCrearCuenta,
                  child: Center(
                    child: Text(
                      crearCuentaLabel,
                      style: GoogleFonts.outfit(
                        fontSize: 14, fontWeight: FontWeight.w700,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 10),

          // Link "ya tengo cuenta"
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: onIngresar,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 10),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                overlayColor: color.withValues(alpha: 0.08),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                onIngresarLabel,
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  color: color.withValues(alpha: 0.9),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
//  Sub-widgets (reutilizados del login)
// ═══════════════════════════════════════════════════════

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
          fontSize: 14, color: Colors.white, fontWeight: FontWeight.w500),
      cursorColor: AppColors.adminGreen,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.outfit(
            fontSize: 13, color: Colors.white.withValues(alpha: 0.55)),
        prefixIcon:
            Icon(icon, color: Colors.white.withValues(alpha: 0.5), size: 20),
        suffixIcon: suffix,
        filled: true,
        fillColor: AppColors.adminS1.withValues(alpha: 0.7),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide:
              BorderSide(color: AppColors.adminBorder.withValues(alpha: 0.4)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide:
              BorderSide(color: AppColors.adminBorder.withValues(alpha: 0.4)),
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
        errorStyle: GoogleFonts.outfit(fontSize: 11, color: AppColors.errorRed),
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
    const btnColor = AppColors.adminGreen;
    final disabled = onTap == null;
    return SizedBox(
      height: 56,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: LinearGradient(
            colors: disabled
                ? [
                    btnColor.withValues(alpha: 0.4),
                    btnColor.withValues(alpha: 0.3),
                  ]
                : [btnColor, btnColor.withValues(alpha: 0.85)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: disabled
              ? null
              : [
                  BoxShadow(
                    color: btnColor.withValues(alpha: 0.45),
                    blurRadius: 24, offset: const Offset(0, 8),
                  ),
                ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(28),
            onTap: onTap,
            child: Center(
              child: loading
                  ? const SizedBox(
                      width: 18, height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2.4, color: Colors.black),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(label,
                            style: GoogleFonts.outfit(
                              color: Colors.black, fontSize: 16,
                              fontWeight: FontWeight.w700,
                            )),
                        if (icon != null) ...[
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
