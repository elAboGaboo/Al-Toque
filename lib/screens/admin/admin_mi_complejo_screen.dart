// screens/admin/admin_mi_complejo_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../models/complejo_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/complejos_provider.dart';
import '../../repositories/complejos_repository.dart';

class AdminMiComplejoScreen extends ConsumerStatefulWidget {
  const AdminMiComplejoScreen({super.key});

  @override
  ConsumerState<AdminMiComplejoScreen> createState() =>
      _AdminMiComplejoScreenState();
}

class _AdminMiComplejoScreenState
    extends ConsumerState<AdminMiComplejoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreCtrl = TextEditingController();
  final _direccionCtrl = TextEditingController();

  String _horaApertura = AppConstants.horarioApertura;
  String _horaCierre = AppConstants.horarioCierre;
  double _lat = AppConstants.huancayoLat;
  double _lng = AppConstants.huancayoLng;

  bool _gpsDetectado = false;
  bool _gpsLoading = false;
  bool _guardando = false;
  bool _cargado = false; // true cuando ya pre-llenamos los campos

  static const _horasApertura = [
    '05:00', '06:00', '07:00', '08:00', '09:00', '10:00',
  ];
  static const _horasCierre = [
    '18:00', '19:00', '20:00', '21:00', '22:00', '23:00', '00:00',
  ];

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _direccionCtrl.dispose();
    super.dispose();
  }

  /// Pre-llena el formulario cuando lleguen los datos de Firestore.
  void _preCargar(ComplejoModel c) {
    if (_cargado) return;
    _cargado = true;
    _nombreCtrl.text = c.nombre;
    _direccionCtrl.text = c.direccion;
    _horaApertura = _horasApertura.contains(c.horarioApertura)
        ? c.horarioApertura
        : _horasApertura.first;
    _horaCierre = _horasCierre.contains(c.horarioCierre)
        ? c.horarioCierre
        : _horasCierre.last;
    _lat = c.lat;
    _lng = c.lng;
    if (c.lat != AppConstants.huancayoLat ||
        c.lng != AppConstants.huancayoLng) {
      _gpsDetectado = true;
    }
  }

  Future<void> _detectarGPS() async {
    setState(() => _gpsLoading = true);
    try {
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        _snack('Permiso denegado — se mantiene la ubicación actual',
            color: AppColors.ablu);
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(accuracy: LocationAccuracy.high),
      );
      setState(() {
        _lat = pos.latitude;
        _lng = pos.longitude;
        _gpsDetectado = true;
      });
    } catch (_) {
      _snack('GPS no disponible — se mantiene la ubicación actual',
          color: AppColors.ablu);
    } finally {
      if (mounted) setState(() => _gpsLoading = false);
    }
  }

  Future<void> _guardar(String complejoId) async {
    if (!_formKey.currentState!.validate()) return;
    if (_guardando) return;
    setState(() => _guardando = true);

    try {
      final repo = ComplejosRepository();
      // Obtenemos el modelo actual para preservar campos que no editamos
      final actual = await repo.getComplejo(complejoId);
      if (actual == null) {
        _snack('No se encontró el complejo', color: AppColors.ared);
        setState(() => _guardando = false);
        return;
      }

      final actualizado = ComplejoModel(
        id: actual.id,
        nombre: _nombreCtrl.text.trim(),
        direccion: _direccionCtrl.text.trim(),
        ciudad: actual.ciudad,
        lat: _lat,
        lng: _lng,
        rating: actual.rating,
        totalResenias: actual.totalResenias,
        horarioApertura: _horaApertura,
        horarioCierre: _horaCierre,
        imagenes: actual.imagenes,
        duenoUid: actual.duenoUid,
        activo: actual.activo,
        configIA: actual.configIA,
      );

      await repo.guardarComplejo(actualizado);

      if (mounted) {
        _snack('¡Cambios guardados!', color: AppColors.aacc);

        // Esperar a que Firestore sincronice
        await Future.delayed(const Duration(milliseconds: 300));

        if (mounted) {
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      if (mounted) {
        _snack('Error al guardar: $e', color: AppColors.ared);
        setState(() => _guardando = false);
      }
    }
  }

  void _snack(String msg, {Color? color}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.outfit()),
      backgroundColor: color ?? AppColors.asur,
      behavior: SnackBarBehavior.floating,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final complejoId = ref.watch(complejoIdProvider);

    if (complejoId == null) {
      return Scaffold(
        backgroundColor: AppColors.abg,
        body: const Center(
          child: CircularProgressIndicator(color: AppColors.aacc),
        ),
      );
    }

    // Escucha el complejo en tiempo real para pre-cargar
    final complejoAsync = ref.watch(complejoProvider(complejoId));

    return complejoAsync.when(
      loading: () => Scaffold(
        backgroundColor: AppColors.abg,
        body: const Center(
          child: CircularProgressIndicator(color: AppColors.aacc),
        ),
      ),
      error: (e, _) => Scaffold(
        backgroundColor: AppColors.abg,
        body: Center(
          child: Text('Error: $e',
              style: GoogleFonts.outfit(color: AppColors.ared)),
        ),
      ),
      data: (complejo) {
        if (complejo != null) {
          // Pre-carga diferida para no llamar setState durante build
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!_cargado) {
              setState(() => _preCargar(complejo));
            }
          });
        }

        return Scaffold(
          backgroundColor: AppColors.abg,
          body: SafeArea(
            child: Column(
              children: [
                // ── Top bar ──────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 12),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: AppColors.asur,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.abdr),
                          ),
                          child: const Icon(
                            Icons.arrow_back_rounded,
                            color: AppColors.atx,
                            size: 18,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Mi Complejo',
                          style: GoogleFonts.bricolageGrotesque(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.atx,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Formulario ───────────────────────
                Expanded(
                  child: SingleChildScrollView(
                    padding:
                        const EdgeInsets.fromLTRB(24, 8, 24, 48),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header info
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppColors.aaccD,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.stadium_rounded,
                                    color: AppColors.aacc, size: 22),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    complejo?.nombre ??
                                        'Cargando...',
                                    style:
                                        GoogleFonts.bricolageGrotesque(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.aacc,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 28),

                          // ── Nombre ─────────────────
                          _SectionLabel('Nombre del complejo'),
                          const SizedBox(height: 8),
                          _InputField(
                            controller: _nombreCtrl,
                            hint: 'Ej: El Tambo Sport',
                            icon: Icons.stadium_outlined,
                            validator: (v) =>
                                (v == null || v.trim().length < 3)
                                    ? 'Mínimo 3 caracteres'
                                    : null,
                          ),
                          const SizedBox(height: 20),

                          // ── Dirección ──────────────
                          _SectionLabel('Dirección'),
                          const SizedBox(height: 8),
                          _InputField(
                            controller: _direccionCtrl,
                            hint: 'Ej: Av. Ferrocarril 245, El Tambo',
                            icon: Icons.location_on_outlined,
                            validator: (v) =>
                                (v == null || v.trim().isEmpty)
                                    ? 'Ingresa la dirección'
                                    : null,
                          ),
                          const SizedBox(height: 20),

                          // ── Horario ────────────────
                          _SectionLabel('Horario de atención'),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: _HorarioDropdown(
                                  horas: _horasApertura,
                                  valor: _horaApertura,
                                  onChanged: (v) =>
                                      setState(() => _horaApertura = v!),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10),
                                child: Text('→',
                                    style: GoogleFonts.outfit(
                                        fontSize: 18,
                                        color: AppColors.atx2)),
                              ),
                              Expanded(
                                child: _HorarioDropdown(
                                  horas: _horasCierre,
                                  valor: _horaCierre,
                                  onChanged: (v) =>
                                      setState(() => _horaCierre = v!),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // ── GPS ────────────────────
                          _SectionLabel('Ubicación en el mapa'),
                          const SizedBox(height: 4),
                          Text(
                            'Toca para actualizar tu ubicación GPS',
                            style: GoogleFonts.outfit(
                                fontSize: 11,
                                color: AppColors.atx3),
                          ),
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap:
                                _gpsLoading ? null : _detectarGPS,
                            child: AnimatedContainer(
                              duration:
                                  const Duration(milliseconds: 250),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: AppColors.asur,
                                borderRadius:
                                    BorderRadius.circular(14),
                                border: Border.all(
                                  color: _gpsDetectado
                                      ? AppColors.aacc
                                      : AppColors.abdr,
                                  width: _gpsDetectado ? 1.5 : 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: _gpsDetectado
                                          ? AppColors.aaccD
                                          : AppColors.asur2,
                                      borderRadius:
                                          BorderRadius.circular(10),
                                    ),
                                    child: _gpsLoading
                                        ? const Center(
                                            child: SizedBox(
                                              width: 16,
                                              height: 16,
                                              child:
                                                  CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: AppColors.aacc,
                                              ),
                                            ),
                                          )
                                        : Icon(
                                            _gpsDetectado
                                                ? Icons
                                                    .my_location_rounded
                                                : Icons
                                                    .location_searching_rounded,
                                            size: 18,
                                            color: _gpsDetectado
                                                ? AppColors.aacc
                                                : AppColors.atx3,
                                          ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _gpsDetectado
                                              ? 'Ubicación actualizada ✓'
                                              : 'Actualizar ubicación GPS',
                                          style: GoogleFonts
                                              .plusJakartaSans(
                                            fontSize: 13,
                                            fontWeight:
                                                FontWeight.w600,
                                            color: _gpsDetectado
                                                ? AppColors.aacc
                                                : AppColors.atx,
                                          ),
                                        ),
                                        Text(
                                          '${_lat.toStringAsFixed(4)}, ${_lng.toStringAsFixed(4)}',
                                          style: GoogleFonts.outfit(
                                              fontSize: 11,
                                              color: AppColors.atx3),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(
                                      Icons.chevron_right_rounded,
                                      color: AppColors.atx3,
                                      size: 18),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 44),

                          // ── Botón guardar ───────────
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.aacc,
                                foregroundColor: Colors.black,
                                padding: const EdgeInsets.symmetric(
                                    vertical: 18),
                                shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(14)),
                                elevation: 0,
                              ),
                              onPressed: _guardando
                                  ? null
                                  : () => _guardar(complejoId),
                              child: _guardando
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.black),
                                    )
                                  : Text(
                                      'Guardar cambios',
                                      style: GoogleFonts
                                          .bricolageGrotesque(
                                        fontSize: 16,
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
              ],
            ),
          ),
        );
      },
    );
  }
}

// ── Sub-widgets reutilizados ───────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.atx2,
          letterSpacing: 0.3,
        ),
      );
}

class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final String? Function(String?)? validator;

  const _InputField({
    required this.controller,
    required this.hint,
    required this.icon,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      validator: validator,
      style: GoogleFonts.outfit(fontSize: 15, color: AppColors.atx),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle:
            GoogleFonts.outfit(fontSize: 14, color: AppColors.atx3),
        prefixIcon: Icon(icon, size: 18, color: AppColors.atx3),
        filled: true,
        fillColor: AppColors.asur,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppColors.abdr),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppColors.abdr),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              const BorderSide(color: AppColors.aacc, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.ared),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              const BorderSide(color: AppColors.ared, width: 1.5),
        ),
      ),
    );
  }
}

class _HorarioDropdown extends StatelessWidget {
  final List<String> horas;
  final String valor;
  final void Function(String?) onChanged;

  const _HorarioDropdown({
    required this.horas,
    required this.valor,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.asur,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.abdr),
      ),
      child: DropdownButton<String>(
        value: valor,
        isExpanded: true,
        underline: const SizedBox.shrink(),
        dropdownColor: AppColors.asur,
        style: GoogleFonts.outfit(fontSize: 14, color: AppColors.atx),
        items: horas
            .map((h) => DropdownMenuItem(value: h, child: Text(h)))
            .toList(),
        onChanged: onChanged,
      ),
    );
  }
}

