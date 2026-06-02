// screens/auth/registro_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../nucleo/constantes/app_constantes.dart';
import '../../nucleo/tema/app_colores.dart';
import '../../proveedores/auth_proveedor.dart';

class RegistroScreen extends ConsumerStatefulWidget {
  final String rolInicial; // 'jugador' | 'dueno'
  const RegistroScreen({super.key, this.rolInicial = 'jugador'});

  @override
  ConsumerState<RegistroScreen> createState() => _RegistroScreenState();
}

class _RegistroScreenState extends ConsumerState<RegistroScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreCtrl = TextEditingController();
  final _dniCtrl    = TextEditingController();
  final _telefonoCtrl = TextEditingController();
  final _emailCtrl  = TextEditingController();
  final _passCtrl   = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _codigoCtrl = TextEditingController();
  String? _genero; // 'masculino' | 'femenino' | 'otro'
  bool _obscure = true;
  bool _obscureConfirm = true;
  bool _loading = false;

  bool get _esDueno => widget.rolInicial == 'dueno';

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _dniCtrl.dispose();
    _telefonoCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    _codigoCtrl.dispose();
    super.dispose();
  }

  Future<void> _registrar() async {
    if (!_formKey.currentState!.validate()) return;
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
          nombre: _nombreCtrl.text.trim(),
          email: _emailCtrl.text.trim(),
          password: _passCtrl.text,
          rol: widget.rolInicial,
          dni: _esDueno ? '' : _dniCtrl.text.trim(),
          telefono: _telefonoCtrl.text.trim(),
          genero: _genero ?? '',
        );

    if (mounted) {
      final state = ref.read(authNotifierProvider);
      if (state.hasError) {
        final err = state.error.toString();
        // Imprime el error completo en la consola para debug
        debugPrint('[Registro] Error completo: $err');
        final errLower = err.toLowerCase();

        String msg;
        if (errLower.contains('email-already-in-use')) {
          msg = 'Este correo ya está registrado';
        } else if (errLower.contains('weak-password')) {
          msg = 'Contraseña muy débil (mínimo 6 caracteres)';
        } else if (errLower.contains('invalid-email')) {
          msg = 'Correo inválido';
        } else if (errLower.contains('operation-not-allowed') ||
            errLower.contains('configuration-not-found') ||
            errLower.contains('configuration_not_found')) {
          msg = 'Email/Password no habilitado en Firebase Console.\n'
              'Actívalo en: Authentication → Sign-in method → Email/Password';
        } else if (errLower.contains('network-request-failed') ||
            errLower.contains('network_request_failed')) {
          msg = 'Sin conexión a internet';
        } else if (errLower.contains('no-app') ||
            errLower.contains('no firebase app')) {
          msg = 'Firebase no inicializado — revisa firebase_options.dart';
        } else if (errLower.contains('permission-denied') ||
            errLower.contains('permission_denied')) {
          msg = 'Firestore: permisos denegados (revisa reglas)';
        } else {
          // Muestra el error real para poder diagnosticarlo
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
        // Navegar explícitamente — no depender del redirect de GoRouter
        // porque hay una ventana de tiempo donde el doc de Firestore aún
        // no llegó al stream y el router envía de vuelta a /welcome.
        if (_esDueno) {
          context.go('/admin/setup-complejo');
        } else {
          context.go('/inicio');
        }
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

                // Nombre completo
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
                    if (v == null || v.trim().isEmpty) {
                      return 'Ingresa tu nombre';
                    }
                    if (v.trim().length < 3) return 'Nombre muy corto';
                    return null;
                  },
                ),
                // DNI — solo jugadores
                if (!_esDueno) ...[
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _dniCtrl,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.next,
                    maxLength: 8,
                    decoration: InputDecoration(
                      labelText: 'DNI',
                      hintText: '12345678',
                      counterText: '',
                      labelStyle: GoogleFonts.outfit(
                          color: AppColors.ink.withValues(alpha: 0.5)),
                      prefixIcon: const Icon(Icons.badge_outlined,
                          color: AppColors.green, size: 20),
                    ),
                    validator: (v) {
                      if (_esDueno) return null;
                      if (v == null || v.trim().isEmpty) return 'Ingresa tu DNI';
                      if (v.trim().length != 8) return 'El DNI debe tener 8 dígitos';
                      if (!RegExp(r'^\d{8}$').hasMatch(v.trim())) {
                        return 'Solo números';
                      }
                      return null;
                    },
                  ),
                ],

                const SizedBox(height: 14),

                // Teléfono
                TextFormField(
                  controller: _telefonoCtrl,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                  maxLength: 9,
                  decoration: InputDecoration(
                    labelText: 'Número de teléfono',
                    hintText: '987654321',
                    counterText: '',
                    labelStyle: GoogleFonts.outfit(
                        color: AppColors.ink.withValues(alpha: 0.5)),
                    prefixIcon: const Icon(Icons.phone_outlined,
                        color: AppColors.green, size: 20),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Ingresa tu número de teléfono';
                    }
                    if (!RegExp(r'^\d{9}$').hasMatch(v.trim())) {
                      return 'Debe tener 9 dígitos';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                // Género
                DropdownButtonFormField<String>(
                  initialValue: _genero,
                  decoration: InputDecoration(
                    labelText: 'Género',
                    labelStyle: GoogleFonts.outfit(
                        color: AppColors.ink.withValues(alpha: 0.5)),
                    prefixIcon: const Icon(Icons.wc_outlined,
                        color: AppColors.green, size: 20),
                  ),
                  style: GoogleFonts.outfit(
                      color: AppColors.ink, fontSize: 16),
                  items: [
                    DropdownMenuItem(
                      value: 'masculino',
                      child: Text('Masculino', style: GoogleFonts.outfit()),
                    ),
                    DropdownMenuItem(
                      value: 'femenino',
                      child: Text('Femenino', style: GoogleFonts.outfit()),
                    ),
                    DropdownMenuItem(
                      value: 'otro',
                      child: Text('Prefiero no decir',
                          style: GoogleFonts.outfit()),
                    ),
                  ],
                  onChanged: (v) => setState(() => _genero = v),
                  validator: (v) =>
                      v == null ? 'Selecciona tu género' : null,
                ),
                const SizedBox(height: 14),

                // Email
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

                // Contraseña
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

                // Confirmar contraseña
                TextFormField(
                  controller: _confirmCtrl,
                  obscureText: _obscureConfirm,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _registrar(),
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
                // Código secreto — solo para dueños de complejo
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

                // Términos
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

                // Botón registrar
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

                // Ya tengo cuenta
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
