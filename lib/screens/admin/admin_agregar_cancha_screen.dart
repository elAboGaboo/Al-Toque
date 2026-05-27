// screens/admin/admin_agregar_cancha_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_colors.dart';
import '../../models/cancha_model.dart';
import '../../repositories/complejos_repository.dart';

class AdminAgregarCanchaScreen extends StatefulWidget {
  /// complejoId ya resuelto — nunca null aquí.
  final String complejoId;

  /// Si se pasa, estamos editando. Si null, estamos creando.
  final CanchaModel? canchaExistente;

  const AdminAgregarCanchaScreen({
    super.key,
    required this.complejoId,
    this.canchaExistente,
  });

  @override
  State<AdminAgregarCanchaScreen> createState() =>
      _AdminAgregarCanchaScreenState();
}

class _AdminAgregarCanchaScreenState
    extends State<AdminAgregarCanchaScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nombreCtrl;
  late final TextEditingController _capacidadCtrl;
  late final TextEditingController _precioCtrl;

  String _deporte = 'futbol5';
  String _superficie = 'sintetico';
  bool _activa = true;
  bool _guardando = false;
  bool _guardado = false;

  bool get _esEdicion => widget.canchaExistente != null;

  static const _deportes = [
    ('futbol5', '⚽', 'Fútbol 5'),
    ('futbol7', '⚽', 'Fútbol 7'),
    ('basquet', '🏀', 'Básquet'),
    ('voley', '🏐', 'Voley'),
  ];

  static const _superficies = [
    ('sintetico', 'Sintético'),
    ('cemento', 'Cemento'),
    ('grass', 'Grass'),
  ];

  @override
  void initState() {
    super.initState();
    final c = widget.canchaExistente;
    _nombreCtrl = TextEditingController(text: c?.nombre ?? '');
    _capacidadCtrl = TextEditingController(
        text: c != null ? '${c.capacidad}' : '10');
    _precioCtrl = TextEditingController(
        text: c != null ? c.precioBase.toStringAsFixed(0) : '');
    if (c != null) {
      _deporte = c.deporte;
      _superficie = c.superficie;
      _activa = c.activa;
    }
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _capacidadCtrl.dispose();
    _precioCtrl.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    if (_guardando || _guardado) return;
    setState(() => _guardando = true);

    try {
      final repo = ComplejosRepository();
      final cancha = CanchaModel(
        id: widget.canchaExistente?.id ?? '',
        complejoId: widget.complejoId,
        nombre: _nombreCtrl.text.trim(),
        deporte: _deporte,
        superficie: _superficie,
        capacidad: int.tryParse(_capacidadCtrl.text.trim()) ?? 10,
        precioBase: double.tryParse(_precioCtrl.text.trim()) ?? 0,
        activa: _activa,
      );

      if (_esEdicion) {
        await repo.guardarCancha(widget.complejoId, cancha);
      } else {
        await repo.crearCancha(widget.complejoId, cancha);
      }

      if (mounted) {
        setState(() {
          _guardado = true;
          _guardando = false;
        });

        // Esperar a que Firestore sincronice
        await Future.delayed(const Duration(milliseconds: 300));

        if (mounted) {
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error al guardar: $e',
              style: GoogleFonts.outfit()),
          backgroundColor: AppColors.ared,
          behavior: SnackBarBehavior.floating,
        ));
        setState(() => _guardando = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.abg,
      body: SafeArea(
        child: Column(
          children: [
            // ── Top bar ──────────────────────────────
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
                      child: const Icon(Icons.arrow_back_rounded,
                          color: AppColors.atx, size: 18),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _esEdicion ? 'Editar cancha' : 'Nueva cancha',
                    style: GoogleFonts.bricolageGrotesque(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.atx,
                    ),
                  ),
                ],
              ),
            ),

            // ── Contenido ────────────────────────────
            Expanded(
              child: _guardado
                  ? _buildExito()
                  : SingleChildScrollView(
                      padding:
                          const EdgeInsets.fromLTRB(24, 8, 24, 48),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            // Header visual
                            Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                color: AppColors.aaccD,
                                borderRadius:
                                    BorderRadius.circular(16),
                              ),
                              child: const Icon(
                                  Icons.stadium_rounded,
                                  color: AppColors.aacc,
                                  size: 28),
                            ),
                            const SizedBox(height: 18),
                            Text(
                              _esEdicion
                                  ? 'Editar\ncancha'
                                  : 'Registrar\ncancha',
                              style: GoogleFonts.bricolageGrotesque(
                                fontSize: 32,
                                fontWeight: FontWeight.w800,
                                color: AppColors.atx,
                                height: 1.1,
                                letterSpacing: -1,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Ingresa los datos de tu cancha para que los jugadores puedan reservarla.',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14,
                                color: AppColors.atx2,
                                height: 1.5,
                              ),
                            ),
                            const SizedBox(height: 36),

                            // ── Nombre ───────────────
                            _SectionLabel('Nombre de la cancha'),
                            const SizedBox(height: 8),
                            _InputField(
                              controller: _nombreCtrl,
                              hint: 'Ej: Cancha 1',
                              icon: Icons.stadium_outlined,
                              validator: (v) =>
                                  (v == null ||
                                          v.trim().length < 2)
                                      ? 'Mínimo 2 caracteres'
                                      : null,
                            ),
                            const SizedBox(height: 24),

                            // ── Deporte ───────────────
                            _SectionLabel('Deporte'),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _deportes
                                  .map((d) => _ChipOp(
                                        label: '${d.$2} ${d.$3}',
                                        selected:
                                            _deporte == d.$1,
                                        onTap: () => setState(
                                            () =>
                                                _deporte = d.$1),
                                      ))
                                  .toList(),
                            ),
                            const SizedBox(height: 24),

                            // ── Superficie ────────────
                            _SectionLabel('Superficie'),
                            const SizedBox(height: 10),
                            Row(
                              children: _superficies
                                  .map((s) => Expanded(
                                        child: Padding(
                                          padding:
                                              const EdgeInsets.only(
                                                  right: 8),
                                          child: _ChipOp(
                                            label: s.$2,
                                            selected:
                                                _superficie == s.$1,
                                            onTap: () => setState(
                                                () => _superficie =
                                                    s.$1),
                                          ),
                                        ),
                                      ))
                                  .toList(),
                            ),
                            const SizedBox(height: 24),

                            // ── Capacidad & Precio ────
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      _SectionLabel(
                                          'Jugadores máx.'),
                                      const SizedBox(height: 8),
                                      _InputField(
                                        controller: _capacidadCtrl,
                                        hint: '10',
                                        icon: Icons
                                            .people_outline_rounded,
                                        keyboardType:
                                            TextInputType.number,
                                        inputFormatters: [
                                          FilteringTextInputFormatter
                                              .digitsOnly
                                        ],
                                        validator: (v) =>
                                            (v == null ||
                                                    v.isEmpty)
                                                ? 'Requerido'
                                                : null,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      _SectionLabel('Precio / hora'),
                                      const SizedBox(height: 8),
                                      _InputField(
                                        controller: _precioCtrl,
                                        hint: 'S/ 60',
                                        icon: Icons
                                            .attach_money_rounded,
                                        keyboardType: const TextInputType
                                            .numberWithOptions(
                                                decimal: true),
                                        inputFormatters: [
                                          FilteringTextInputFormatter
                                              .allow(RegExp(
                                                  r'^\d+\.?\d{0,2}'))
                                        ],
                                        validator: (v) =>
                                            (v == null ||
                                                    v.isEmpty)
                                                ? 'Requerido'
                                                : null,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),

                            // ── Activa toggle ─────────
                            GestureDetector(
                              onTap: () =>
                                  setState(() => _activa = !_activa),
                              child: AnimatedContainer(
                                duration:
                                    const Duration(milliseconds: 200),
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: _activa
                                      ? AppColors.aaccD
                                      : AppColors.asur,
                                  borderRadius:
                                      BorderRadius.circular(14),
                                  border: Border.all(
                                    color: _activa
                                        ? AppColors.aacc
                                        : AppColors.abdr2,
                                    width: _activa ? 1.5 : 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 36,
                                      height: 36,
                                      decoration: BoxDecoration(
                                        color: _activa
                                            ? AppColors.aacc
                                                .withValues(
                                                    alpha: 0.18)
                                            : AppColors.asur2,
                                        borderRadius:
                                            BorderRadius.circular(
                                                10),
                                      ),
                                      child: Icon(
                                        _activa
                                            ? Icons.check_circle_rounded
                                            : Icons
                                                .do_not_disturb_rounded,
                                        color: _activa
                                            ? AppColors.aacc
                                            : AppColors.atx3,
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Disponible para reservas',
                                            style: GoogleFonts
                                                .plusJakartaSans(
                                              fontSize: 13,
                                              fontWeight:
                                                  FontWeight.w600,
                                              color: _activa
                                                  ? AppColors.aacc
                                                  : AppColors.atx,
                                            ),
                                          ),
                                          Text(
                                            _activa
                                                ? 'Los jugadores pueden reservarla'
                                                : 'Oculta para los jugadores',
                                            style: GoogleFonts.outfit(
                                                fontSize: 11,
                                                color:
                                                    AppColors.atx2),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Switch.adaptive(
                                      value: _activa,
                                      activeTrackColor: AppColors.aacc,
                                      onChanged: (v) =>
                                          setState(() => _activa = v),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 44),

                            // ── Botón guardar ─────────
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
                                onPressed:
                                    _guardando ? null : _guardar,
                                child: _guardando
                                    ? const SizedBox(
                                        height: 22,
                                        width: 22,
                                        child:
                                            CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          color: Colors.black,
                                        ),
                                      )
                                    : Text(
                                        _esEdicion
                                            ? 'Guardar cambios'
                                            : 'Registrar cancha',
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
  }

  // ── Estado de éxito ─────────────────────────────────────────
  Widget _buildExito() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icono animado
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.aaccD,
                borderRadius: BorderRadius.circular(24),
                border:
                    Border.all(color: AppColors.aaccB, width: 1.5),
              ),
              child: const Icon(Icons.check_rounded,
                  color: AppColors.aacc, size: 44),
            ),
            const SizedBox(height: 24),
            Text(
              _esEdicion
                  ? '¡Cambios guardados!'
                  : '¡Cancha registrada!',
              style: GoogleFonts.bricolageGrotesque(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: AppColors.atx,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              _esEdicion
                  ? 'Los datos de la cancha han sido actualizados.'
                  : '"${_nombreCtrl.text}" ya está disponible para que los jugadores reserven.',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                color: AppColors.atx2,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 36),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.aacc,
                  foregroundColor: Colors.black,
                  padding:
                      const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(
                  'Volver a Horarios',
                  style: GoogleFonts.bricolageGrotesque(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () {
                // Registrar otra cancha — reinicia el estado
                setState(() {
                  _guardado = false;
                  _nombreCtrl.clear();
                  _capacidadCtrl.text = '10';
                  _precioCtrl.clear();
                  _deporte = 'futbol5';
                  _superficie = 'sintetico';
                  _activa = true;
                });
              },
              child: Text(
                'Agregar otra cancha',
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  color: AppColors.atx2,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Widgets locales ────────────────────────────────────────────

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
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;

  const _InputField({
    required this.controller,
    required this.hint,
    required this.icon,
    this.validator,
    this.keyboardType,
    this.inputFormatters,
  });

  @override
  Widget build(BuildContext context) => TextFormField(
        controller: controller,
        validator: validator,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        style:
            GoogleFonts.outfit(fontSize: 15, color: AppColors.atx),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.outfit(
              fontSize: 14, color: AppColors.atx3),
          prefixIcon:
              Icon(icon, size: 18, color: AppColors.atx3),
          filled: true,
          fillColor: AppColors.asur,
          contentPadding: const EdgeInsets.symmetric(
              horizontal: 14, vertical: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide:
                const BorderSide(color: AppColors.abdr2),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide:
                const BorderSide(color: AppColors.abdr2),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(
                color: AppColors.aacc, width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide:
                const BorderSide(color: AppColors.ared),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(
                color: AppColors.ared, width: 1.5),
          ),
        ),
      );
}

class _ChipOp extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _ChipOp(
      {required this.label,
      required this.selected,
      required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(
              horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: selected ? AppColors.aaccD : AppColors.asur,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected
                  ? AppColors.aacc
                  : AppColors.abdr2,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color:
                  selected ? AppColors.aacc : AppColors.atx2,
            ),
          ),
        ),
      );
}
