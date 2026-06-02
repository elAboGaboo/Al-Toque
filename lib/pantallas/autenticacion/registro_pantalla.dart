// pantallas/autenticacion/registro_pantalla.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../nucleo/constantes/app_constantes.dart';
import '../../nucleo/tema/app_colores.dart';
import '../../proveedores/auth_proveedor.dart';

/// Formulario de registro: jugador o dueño.
/// Solo recopila nombre, email y contraseña — los datos opcionales
/// (teléfono, género, DNI) se pueden completar en la pantalla de perfil.
class RegistroScreen extends ConsumerStatefulWidget {
  final String rolInicial; // 'jugador' | 'dueno'
  const RegistroScreen({super.key, this.rolInicial = 'jugador'});

  @override
  ConsumerState<RegistroScreen> createState() => _RegistroScreenState();
}

class _RegistroScreenState extends ConsumerState<RegistroScreen> {
  final _formKey    = GlobalKey<FormState>();
  final _nombreCtrl = TextEditingController();
  final _emailCtrl  = TextEditingController();
  final _passCtrl   = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _codigoCtrl = TextEditingController();
  bool _obscure = true;
  bool _obscureConfirm = true;
  bool _loading = false;

  bool get _esDueno => widget.rolInicial == 'dueno';

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    _codigoCtrl.dispose();
    super.dispose();
  }

  Future<void> _registrar() async {
    if (!_formKey.currentState!.validate()) return;

    // Código de acceso para dueños
    if (_esDueno &&
        _codigoCtrl.text.trim() != AppConstants.codigoRegistroDueno) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Código de acceso incorrecto',
            style: GoogleFonts.outfit()),
        backgroundColor: AppColors.errorRed,
        duration: const Duration(seconds: 4),
      ));
      return;
    }

    setState(() => _loading = true);

    await ref.read(authNotifierProvider.notifier).registrar(
          nombre:   _nombreCtrl.text.trim(),
          email:    _emailCtrl.text.trim(),
          password: _passCtrl.text,
          rol:      widget.rolInicial,
        );

    if (!mounted) return;

    final state = ref.read(authNotifierProvider);
    if (state.hasError) {
      final err = state.error.toString();
      debugPrint('[Registro] Error: $err');
      final lower = err.toLowerCase();

      String msg;
      if (lower.contains('email-already-in-use')) {
        msg = 'Este correo ya está registrado';
      } else if (lower.contains('weak-password')) {
        msg = 'Contraseña muy débil (mínimo 6 caracteres)';
      } else if (lower.contains('invalid-email')) {
        msg = 'Correo inválido';
      } else if (lower.contains('operation-not-allowed') ||
          lower.contains('configuration-not-found')) {
        msg = 'Email/Password no habilitado en Firebase.\n'
            'Actívalo en: Authentication → Sign-in method';
      } else if (lower.contains('network-request-failed')) {
        msg = 'Sin conexión a internet';
      } else if (lower.contains('permission-denied')) {
        msg = 'Firestore: permisos denegados — revisa las reglas';
      } else {
        msg = err.length > 200 ? '${err.substring(0, 200)}…' : err;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg, style: GoogleFonts.outfit()),
          backgroundColor: AppColors.errorRed,
          duration: const Duration(seconds: 8),
        ),
      );
      setState(() => _loading = false);
    } else {
      // El router redirige automáticamente cuando el perfil llega de
      // Firestore (perfilUsuarioProvider → routerNotifier → redirect).
      // La navegación explícita es un respaldo por si el stream tarda.
      if (_esDueno) {
        context.go('/admin/setup-complejo');
      } else {
        context.go('/inicio');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: AppBar(
        backgroundColor: AppColors.paper,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                Text(
                  _esDueno ? 'Registra tu\ncomplejo' : 'Crear tu\ncuenta',
                  style: GoogleFonts.bricolageGrotesque(
                    fontSize: 36,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _esDueno
                      ? 'Gestiona tu complejo deportivo en Al Toque'
                      : 'Únete a miles de jugadores en Huancayo',
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    color: AppColors.ink.withValues(alpha: 0.5),
                  ),
                ),
                const SizedBox(height: 32),

                // ── Nombre completo ───────────────────────────
                TextFormField(
                  controller: _nombreCtrl,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: 'Nombre completo',
                    labelStyle: GoogleFonts.outfit(
                        color: AppColors.ink.withValues(alpha: 0.5)),
                    prefixIcon: const Icon(Icons.person_outline_rounded,
                        color: AppColors.green, size: 20),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Ingresa tu nombre';
                    if (v.trim().length < 3) return 'Nombre muy corto';
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                // ── Correo electrónico ────────────────────────
                TextFormField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: 'Correo electrónico',
                    labelStyle: GoogleFonts.outfit(
                        color: AppColors.ink.withValues(alpha: 0.5)),
                    prefixIcon: const Icon(Icons.email_outlined,
                        color: AppColors.green, size: 20),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Ingresa tu correo';
                    if (!v.contains('@') || !v.contains('.')) {
                      return 'Correo inválido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                // ── Contraseña ────────────────────────────────
                TextFormField(
                  controller: _passCtrl,
                  obscureText: _obscure,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: 'Contraseña',
                    labelStyle: GoogleFonts.outfit(
                        color: AppColors.ink.withValues(alpha: 0.5)),
                    prefixIcon: const Icon(Icons.lock_outline_rounded,
                        color: AppColors.green, size: 20),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscure
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: AppColors.ink.withValues(alpha: 0.4),
                        size: 20,
                      ),
                      onPressed: () =>
                          setState(() => _obscure = !_obscure),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Ingresa una contraseña';
                    if (v.length < 6) return 'Mínimo 6 caracteres';
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                // ── Confirmar contraseña ──────────────────────
                TextFormField(
                  controller: _confirmCtrl,
                  obscureText: _obscureConfirm,
                  textInputAction:
                      _esDueno ? TextInputAction.next : TextInputAction.done,
                  onFieldSubmitted: _esDueno ? null : (_) => _registrar(),
                  decoration: InputDecoration(
                    labelText: 'Confirmar contraseña',
                    labelStyle: GoogleFonts.outfit(
                        color: AppColors.ink.withValues(alpha: 0.5)),
                    prefixIcon: const Icon(Icons.lock_outline_rounded,
                        color: AppColors.green, size: 20),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirm
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: AppColors.ink.withValues(alpha: 0.4),
                        size: 20,
                      ),
                      onPressed: () =>
                          setState(() => _obscureConfirm = !_obscureConfirm),
                    ),
                  ),
                  validator: (v) {
                    if (v != _passCtrl.text) {
                      return 'Las contraseñas no coinciden';
                    }
                    return null;
                  },
                ),

                // ── Código de acceso (solo dueños) ────────────
                if (_esDueno) ...[
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _codigoCtrl,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _registrar(),
                    decoration: InputDecoration(
                      labelText: 'Código de acceso',
                      hintText: 'Proporcionado por Al Toque',
                      labelStyle: GoogleFonts.outfit(
                          color: AppColors.ink.withValues(alpha: 0.5)),
                      prefixIcon: const Icon(Icons.vpn_key_outlined,
                          color: AppColors.green, size: 20),
                    ),
                    validator: (v) {
                      if (_esDueno && (v == null || v.trim().isEmpty)) {
                        return 'Ingresa el código de acceso';
                      }
                      return null;
                    },
                  ),
                ],

                const SizedBox(height: 28),

                // ── Términos ──────────────────────────────────
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline_rounded,
                        size: 16, color: AppColors.green),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Al crear tu cuenta aceptas nuestros Términos de Servicio y Política de Privacidad.',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          color: AppColors.ink.withValues(alpha: 0.5),
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // ── Botón registrar ───────────────────────────
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _registrar,
                    child: _loading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            'Crear cuenta',
                            style: GoogleFonts.outfit(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 16),

                // ── Ya tengo cuenta ───────────────────────────
                Center(
                  child: TextButton(
                    onPressed: () => context.pop(),
                    child: Text(
                      '¿Ya tienes cuenta? Ingresa aquí',
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        color: AppColors.green,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
