// DEAD CODE — Este archivo ya no se usa. La lógica de login fue migrada a
// welcome_screen.dart (modo "login"). Puede eliminarse sin afectar el proyecto.
// screens/auth/login_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;
  bool _loading = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    final notifier = ref.read(authNotifierProvider.notifier);
    await notifier.login(
      email: _emailCtrl.text,
      password: _passCtrl.text,
    );

    if (mounted) {
      final state = ref.read(authNotifierProvider);
      if (state.hasError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _mensajeError(state.error.toString()),
              style: GoogleFonts.outfit(),
            ),
            backgroundColor: AppColors.errorRed,
          ),
        );
        setState(() => _loading = false);
      }
      // La navegación la maneja GoRouter al detectar el cambio de authState
    }
  }

  String _mensajeError(String raw) {
    if (raw.contains('invalid-credential') ||
        raw.contains('wrong-password') ||
        raw.contains('user-not-found')) {
      return 'Email o contraseña incorrectos';
    }
    if (raw.contains('too-many-requests')) {
      return 'Demasiados intentos. Espera un momento';
    }
    return 'Error al iniciar sesión. Intenta de nuevo';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paper,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 56),
                // Logo + marca
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.green,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.sports_soccer_rounded,
                          color: Colors.white, size: 28),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Al Toque',
                      style: GoogleFonts.bricolageGrotesque(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 40),
                Text(
                  'Bienvenido\nde vuelta',
                  style: GoogleFonts.bricolageGrotesque(
                    fontSize: 36,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Reserva canchas en Huancayo al instante',
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    color: AppColors.ink.withValues(alpha: 0.5),
                  ),
                ),
                const SizedBox(height: 36),

                // Email
                TextFormField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: 'Correo electrónico',
                    labelStyle: GoogleFonts.outfit(color: AppColors.ink.withValues(alpha: 0.5)),
                    prefixIcon: const Icon(Icons.email_outlined,
                        color: AppColors.green, size: 20),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Ingresa tu correo';
                    if (!v.contains('@')) return 'Correo inválido';
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                // Contraseña
                TextFormField(
                  controller: _passCtrl,
                  obscureText: _obscure,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _login(),
                  decoration: InputDecoration(
                    labelText: 'Contraseña',
                    labelStyle: GoogleFonts.outfit(color: AppColors.ink.withValues(alpha: 0.5)),
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
                    if (v == null || v.isEmpty) return 'Ingresa tu contraseña';
                    if (v.length < 6) return 'Mínimo 6 caracteres';
                    return null;
                  },
                ),
                const SizedBox(height: 10),

                // Olvidé contraseña
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => _mostrarResetDialog(),
                    child: Text(
                      '¿Olvidaste tu contraseña?',
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        color: AppColors.green,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Botón ingresar
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _login,
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
                            'Ingresar',
                            style: GoogleFonts.outfit(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 20),

                // Divider
                Row(
                  children: [
                    const Expanded(child: Divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        'o',
                        style: GoogleFonts.outfit(
                            color: AppColors.ink.withValues(alpha: 0.4)),
                      ),
                    ),
                    const Expanded(child: Divider()),
                  ],
                ),
                const SizedBox(height: 20),

                // Registrarse
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => context.push('/registro'),
                    child: Text(
                      'Crear cuenta nueva',
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Ciudad
                Center(
                  child: Text(
                    '📍 Huancayo, Perú',
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      color: AppColors.ink.withValues(alpha: 0.4),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _mostrarResetDialog() {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Recuperar contraseña',
          style: GoogleFonts.bricolageGrotesque(
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Te enviaremos un enlace a tu correo para restablecer tu contraseña.',
              style: GoogleFonts.outfit(fontSize: 14),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: ctrl,
              decoration: InputDecoration(
                labelText: 'Correo electrónico',
                labelStyle: GoogleFonts.outfit(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ref
                  .read(authNotifierProvider.notifier)
                  .resetPassword(ctrl.text);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Enlace enviado a ${ctrl.text}',
                      style: GoogleFonts.outfit(),
                    ),
                    backgroundColor: AppColors.green,
                  ),
                );
              }
            },
            child: const Text('Enviar'),
          ),
        ],
      ),
    );
  }
}
