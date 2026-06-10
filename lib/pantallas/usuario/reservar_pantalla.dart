// screens/usuario/reservar_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../nucleo/tema/app_colores.dart';
import '../../nucleo/utilidades/app_fecha_utilidades.dart';
import '../../modelos/cancha_modelo.dart';
import '../../modelos/complejo_modelo.dart';
import '../../modelos/reserva_modelo.dart';
import '../../proveedores/complejos_proveedor.dart';
import '../../proveedores/reservas_proveedor.dart';

class ReservarScreen extends ConsumerStatefulWidget {
  final String complejoId;
  final String canchaId;

  const ReservarScreen({
    super.key,
    required this.complejoId,
    required this.canchaId,
  });

  @override
  ConsumerState<ReservarScreen> createState() => _ReservarScreenState();
}

class _ReservarScreenState extends ConsumerState<ReservarScreen> {
  late DateTime _fechaSeleccionada;
  String? _horaSeleccionada;
  String _metodoPago = 'yape';

  // Datos capturados sincrónicamente desde providers en caché.
  // Si el usuario viene de ComplejoDetalleScreen siempre están disponibles
  // y no se hace ningún request extra a Firestore.
  CanchaModel? _cancha;
  ComplejoModel? _complejo;

  static DateTime _soloFecha(DateTime d) => DateTime(d.year, d.month, d.day);

  @override
  void initState() {
    super.initState();
    _fechaSeleccionada = _soloFecha(DateTime.now());

    // Leer cancha y complejo del provider (seteados antes de navegar).
    final cachedCancha = ref.read(canchaSeleccionadaProvider);
    if (cachedCancha != null && cachedCancha.id == widget.canchaId) {
      _cancha = cachedCancha;
    }
    final cachedComplejo = ref.read(complejoSeleccionadoProvider);
    if (cachedComplejo != null && cachedComplejo.id == widget.complejoId) {
      _complejo = cachedComplejo;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Disponibilidad: siempre va a Firestore (datos en tiempo real, timeout 8s).
    // La clave cambia con la fecha → auto-refetch al cambiar día.
    final fechaConsulta = _soloFecha(_fechaSeleccionada);
    final disponibilidadAsync = ref.watch(
      disponibilidadFutureProvider((
        complejoId: widget.complejoId,
        canchaId: widget.canchaId,
        fecha: fechaConsulta,
      )),
    );
    final isLoading = ref.watch(reservaNotifierProvider).isLoading;

    // ── Ruta rápida: datos en caché (navegación normal) ────────────────────
    if (_cancha != null && _complejo != null) {
      return _buildScaffold(
        context,
        cancha: _cancha!,
        complejo: _complejo!,
        disponibilidadAsync: disponibilidadAsync,
        isLoading: isLoading,
      );
    }

    // ── Fallback: deep link → cargar desde Firestore ───────────────────────
    final canchaAsync = ref.watch(
      canchaFutureProvider((
        complejoId: widget.complejoId,
        canchaId: widget.canchaId,
      )),
    );
    final complejoAsync = ref.watch(complejoFutureProvider(widget.complejoId));

    final cancha = canchaAsync.asData?.value;
    final complejo = complejoAsync.asData?.value;

    // Si ambos ya están disponibles, construir directamente.
    if (cancha != null && complejo != null) {
      return _buildScaffold(
        context,
        cancha: cancha,
        complejo: complejo,
        disponibilidadAsync: disponibilidadAsync,
        isLoading: isLoading,
      );
    }

    // Loading o error mientras llegan los datos base.
    final isLoadingBase =
        canchaAsync.isLoading || complejoAsync.isLoading;
    final errorBase = canchaAsync.error ?? complejoAsync.error;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => context.canPop() ? context.pop() : context.go('/inicio'),
        ),
        title: Text(
          'Reservar cancha',
          style: GoogleFonts.bricolageGrotesque(
              fontSize: 18, fontWeight: FontWeight.w700),
        ),
      ),
      body: isLoadingBase
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.acc))
          : _ErrorRecuperable(
              mensaje: errorBase != null
                  ? _mensajeAmigable(errorBase.toString())
                  : 'Cancha o complejo no encontrado.',
              onRetry: () {
                ref.invalidate(canchaFutureProvider((
                  complejoId: widget.complejoId,
                  canchaId: widget.canchaId,
                )));
                ref.invalidate(
                    complejoFutureProvider(widget.complejoId));
              },
            ),
    );
  }

  Scaffold _buildScaffold(
    BuildContext context, {
    required CanchaModel cancha,
    required ComplejoModel complejo,
    required AsyncValue<List<ReservaModel>> disponibilidadAsync,
    required bool isLoading,
  }) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => context.canPop() ? context.pop() : context.go('/inicio'),
        ),
        title: Text(
          cancha.nombre,
          style: GoogleFonts.bricolageGrotesque(
              fontSize: 18, fontWeight: FontWeight.w700),
        ),
      ),
      body: _buildBody(
          context, cancha, complejo, disponibilidadAsync, isLoading),
    );
  }

  Widget _buildBody(
    BuildContext context,
    CanchaModel cancha,
    ComplejoModel complejo,
    AsyncValue<List<ReservaModel>> disponibilidadAsync,
    bool isLoading,
  ) {
    final slots = AppDateUtils.generarSlots(
      apertura: complejo.horarioApertura,
      cierre: complejo.horarioCierre,
    );

    return Stack(
      children: [
        SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Info de cancha ────────────────────────────
              _CanchaInfoBanner(cancha: cancha, complejo: complejo),

              // ── Calendario ───────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 14),
                child: _CalendarHeader(fecha: _fechaSeleccionada),
              ),
              _HorizontalCalendar(
                selectedDate: _fechaSeleccionada,
                onDateSelected: (d) => setState(() {
                  _fechaSeleccionada = _soloFecha(d);
                  _horaSeleccionada = null;
                }),
              ),

              const SizedBox(height: 24),

              // ── Sugerencia IA ─────────────────────────────
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: _AISuggestionBanner(),
              ),

              const SizedBox(height: 24),

              // ── Selector de Slots ─────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'Horarios Disponibles',
                  style: GoogleFonts.bricolageGrotesque(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.tx,
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Disponibilidad: si falla la consulta, mostramos los slots
              // como disponibles (sin verificar ocupación). El usuario
              // podrá intentar reservar y verá el error solo si el slot
              // realmente está tomado al momento de confirmar.
              Builder(builder: (_) {
                final ocupadas = disponibilidadAsync.asData?.value
                        .where((r) => r.estado != 'cancelada')
                        .map((r) => r.horaInicio)
                        .toList() ??
                    [];
                final hayError = disponibilidadAsync.hasError;

                return Column(
                  children: [
                    if (hayError)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: AppColors.amber.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: AppColors.amber.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.wifi_off_rounded,
                                  size: 14, color: AppColors.amber),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Sin conexión — mostrando horarios estimados',
                                  style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11, color: AppColors.amber),
                                ),
                              ),
                              GestureDetector(
                                onTap: () => ref.invalidate(
                                    disponibilidadFutureProvider((
                                  complejoId: widget.complejoId,
                                  canchaId: widget.canchaId,
                                  fecha: _fechaSeleccionada,
                                ))),
                                child: Text('Reintentar',
                                    style: GoogleFonts.outfit(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.amber)),
                              ),
                            ],
                          ),
                        ),
                      )
                    else if (disponibilidadAsync.isLoading)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Center(
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                color: AppColors.acc, strokeWidth: 2),
                          ),
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: _TimeSlotsGrid(
                        slots: slots,
                        ocupadas: ocupadas,
                        fecha: _fechaSeleccionada,
                        precio: cancha.precioBase,
                        selectedTime: _horaSeleccionada,
                        onTimeSelected: (t) =>
                            setState(() => _horaSeleccionada = t),
                      ),
                    ),
                  ],
                );
              }),

              const SizedBox(height: 140),
            ],
          ),
        ),

        // ── Bottom summary fijo ───────────────────────────
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: _BookingSummary(
            selectedTime: _horaSeleccionada,
            fecha: _fechaSeleccionada,
            precio: cancha.precioBase,
            metodoPago: _metodoPago,
            onMetodoPagoTap: _mostrarSelectorPago,
            isLoading: isLoading,
            onConfirm: () => _confirmarReserva(
              cancha,
              disponibilidadAsync.asData?.value
                      .where((r) => r.estado != 'cancelada')
                      .map((r) => r.horaInicio)
                      .toList() ??
                  [],
            ),
          ),
        ),
      ],
    );
  }

  void _mostrarSelectorPago() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _MetodoPagoSheet(
        seleccionado: _metodoPago,
        onSeleccionado: (m) {
          setState(() => _metodoPago = m);
          Navigator.pop(context);
        },
      ),
    );
  }

  /// Muestra el diálogo de pago simulado, luego crea la reserva en Firestore.
  Future<void> _confirmarReserva(
    CanchaModel cancha,
    List<String> ocupadas,
  ) async {
    if (_horaSeleccionada == null) return;

    if (ocupadas.contains(_horaSeleccionada)) {
      _mostrarError('Ese horario acaba de ser reservado. Elige otro.');
      ref.invalidate(disponibilidadFutureProvider((
        complejoId: widget.complejoId,
        canchaId: widget.canchaId,
        fecha: _soloFecha(_fechaSeleccionada),
      )));
      return;
    }

    // 1 ── Mostrar diálogo de pago simulado ─────────────────────────────────
    final confirmar = await _mostrarDialogoPago(cancha.precioBase);
    if (!mounted || confirmar != true) return;

    // 2 ── Crear reserva en Firestore ────────────────────────────────────────
    try {
      final fecha = _soloFecha(_fechaSeleccionada);
      final horaFin = _calcularHoraFin(_horaSeleccionada!);
      final reservaId =
          await ref.read(reservaNotifierProvider.notifier).crearReserva(
                complejoId: widget.complejoId,
                canchaId: widget.canchaId,
                fecha: fecha,
                horaInicio: _horaSeleccionada!,
                horaFin: horaFin,
                duracionHoras: 1.0,
                precioTotal: cancha.precioBase,
                metodoPago: _metodoPago,
              );

      if (!mounted) return;

      if (reservaId != null) {
        ref.invalidate(disponibilidadFutureProvider((
          complejoId: widget.complejoId,
          canchaId: widget.canchaId,
          fecha: fecha,
        )));
        context.pushReplacement('/confirmacion/$reservaId');
      } else {
        final rawMsg =
            ref.read(reservaNotifierProvider).error?.toString() ?? '';
        _mostrarError(_mensajeAmigable(rawMsg));
      }
    } catch (e) {
      if (!mounted) return;
      _mostrarError(_mensajeAmigable(e.toString()));
    }
  }

  /// Diálogo de pago simulado: procesa 1.5 s y cierra retornando true.
  Future<bool?> _mostrarDialogoPago(double precio) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _PagoDialog(
        metodoPago: _metodoPago,
        precio: precio,
      ),
    );
  }

  void _mostrarError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: AppColors.red,
        duration: const Duration(seconds: 5),
      ),
    );
  }

  /// Convierte un mensaje de excepción técnico en texto para el usuario.
  String _mensajeAmigable(String raw) {
    if (raw.contains('agotado') || raw.contains('timeout')) {
      return 'Tiempo de espera agotado. Verifica tu conexión e intenta de nuevo.';
    }
    if (raw.contains('PERMISSION_DENIED') || raw.contains('permission')) {
      return 'Sin permiso para crear la reserva. Intenta cerrar sesión e ingresar de nuevo.';
    }
    if (raw.contains('UNAVAILABLE') || raw.contains('unavailable')) {
      return 'Servicio no disponible. Verifica tu conexión a internet.';
    }
    if (raw.isEmpty) return 'Error al crear la reserva. Intenta nuevamente.';
    return 'Error al crear la reserva. Intenta nuevamente.';
  }

  String _calcularHoraFin(String horaInicio) {
    final parts = horaInicio.split(':');
    final hora = int.parse(parts[0]) + 1;
    // Cap en 23:00 — no existen slots que terminen a las 24:00
    final horaFin = hora > 23 ? 23 : hora;
    return '${horaFin.toString().padLeft(2, '0')}:${parts[1]}';
  }
}

// ── Widgets ────────────────────────────────────────────────────────────────

class _CanchaInfoBanner extends StatelessWidget {
  final CanchaModel cancha;
  final ComplejoModel complejo;

  const _CanchaInfoBanner({required this.cancha, required this.complejo});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.accLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.acc.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.acc,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(cancha.deporteEmoji,
                  style: const TextStyle(fontSize: 22)),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  cancha.nombre,
                  style: GoogleFonts.bricolageGrotesque(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.tx,
                  ),
                ),
                Text(
                  '${cancha.deporteLabel} · ${cancha.superficieLabel}',
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 12, color: AppColors.tx2),
                ),
                Text(
                  '${complejo.horarioApertura} – ${complejo.horarioCierre}',
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 11, color: AppColors.tx3),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'S/${cancha.precioBase.toStringAsFixed(0)}',
                style: GoogleFonts.bricolageGrotesque(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.acc,
                ),
              ),
              Text(
                'por hora',
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 10, color: AppColors.tx3),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CalendarHeader extends StatelessWidget {
  final DateTime fecha;
  const _CalendarHeader({required this.fecha});

  @override
  Widget build(BuildContext context) {
    final raw = DateFormat('MMMM yyyy', 'es').format(fecha);
    final label = raw[0].toUpperCase() + raw.substring(1);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.bricolageGrotesque(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppColors.tx,
          ),
        ),
        const Icon(Icons.calendar_month_rounded,
            size: 16, color: AppColors.tx3),
      ],
    );
  }
}

class _HorizontalCalendar extends StatelessWidget {
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateSelected;

  const _HorizontalCalendar(
      {required this.selectedDate, required this.onDateSelected});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    // Base normalizada para que los días generados sean fecha-pura
    final hoy = DateTime(now.year, now.month, now.day);

    return SizedBox(
      height: 85,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: 14,
        separatorBuilder: (_, idx) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final date = hoy.add(Duration(days: i)); // fecha normalizada
          final isSelected = date.day == selectedDate.day &&
              date.month == selectedDate.month &&
              date.year == selectedDate.year;
          final dayName =
              ['L', 'M', 'M', 'J', 'V', 'S', 'D'][date.weekday - 1];

          return GestureDetector(
            onTap: () => onDateSelected(date),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 54,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.tx : AppColors.sur,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: isSelected ? AppColors.tx : AppColors.bdr2),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    dayName,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: isSelected
                          ? FontWeight.w500
                          : FontWeight.w400,
                      color: isSelected
                          ? Colors.white.withValues(alpha: 0.5)
                          : AppColors.tx3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${date.day}',
                    style: GoogleFonts.bricolageGrotesque(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? Colors.white : AppColors.tx,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _AISuggestionBanner extends StatelessWidget {
  const _AISuggestionBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.acc.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.acc.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: AppColors.acc,
                borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.auto_awesome_rounded,
                size: 16, color: Colors.white),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sugerencia IA',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.acc,
                  ),
                ),
                Text(
                  'Los horarios con menor demanda tienen precios más bajos.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    color: AppColors.tx2,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TimeSlotsGrid extends StatelessWidget {
  final List<String> slots;
  final List<String> ocupadas;
  final DateTime fecha;
  final double precio;
  final String? selectedTime;
  final ValueChanged<String> onTimeSelected;

  const _TimeSlotsGrid({
    required this.slots,
    required this.ocupadas,
    required this.fecha,
    required this.precio,
    required this.selectedTime,
    required this.onTimeSelected,
  });

  bool _esPasado(String slot) {
    final now = DateTime.now();
    final hoy = DateTime(now.year, now.month, now.day);
    final dia = DateTime(fecha.year, fecha.month, fecha.day);
    // Día futuro → nunca pasado
    if (dia.isAfter(hoy)) return false;
    // Día pasado → todos los slots ya pasaron
    if (dia.isBefore(hoy)) return true;
    // Mismo día → comparar hora y minutos
    final parts = slot.split(':');
    final slotHora = int.parse(parts[0]);
    final slotMin = int.parse(parts[1]);
    if (slotHora < now.hour) return true;
    if (slotHora > now.hour) return false;
    return slotMin <= now.minute;
  }

  @override
  Widget build(BuildContext context) {
    if (slots.isEmpty) {
      return Center(
        child: Text('Sin horarios disponibles',
            style: GoogleFonts.plusJakartaSans(color: AppColors.tx3)),
      );
    }

    // Ancho de cada celda: descuenta 2×20 padding exterior + 2×10 de spacing
    final slotWidth = (MediaQuery.of(context).size.width - 60) / 3;

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: slots.map((slot) {
        final isOcupado = ocupadas.contains(slot);
        final isPasado = _esPasado(slot);
        final isDisponible = !isOcupado && !isPasado;
        final isSelected = selectedTime == slot;

        Color bgColor;
        Color borderColor;
        Color textColor;
        Color subColor;

        if (isSelected) {
          bgColor = AppColors.tx;
          borderColor = AppColors.tx;
          textColor = Colors.white;
          subColor = Colors.white.withValues(alpha: 0.5);
        } else if (isOcupado) {
          bgColor = AppColors.red.withValues(alpha: 0.06);
          borderColor = AppColors.red.withValues(alpha: 0.2);
          textColor = AppColors.tx3;
          subColor = AppColors.red.withValues(alpha: 0.7);
        } else if (isPasado) {
          bgColor = AppColors.sur;
          borderColor = AppColors.bdr;
          textColor = AppColors.tx3;
          subColor = AppColors.tx3;
        } else {
          bgColor = AppColors.sur;
          borderColor = AppColors.bdr2;
          textColor = AppColors.tx;
          subColor = AppColors.acc;
        }

        return GestureDetector(
          onTap: isDisponible ? () => onTimeSelected(slot) : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: slotWidth,
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: borderColor),
            ),
            child: Column(
              children: [
                Text(
                  slot,
                  style: GoogleFonts.bricolageGrotesque(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isOcupado
                      ? 'Ocupado'
                      : isPasado
                          ? 'Pasado'
                          : 'S/${precio.toStringAsFixed(0)}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: subColor,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _BookingSummary extends StatelessWidget {
  final String? selectedTime;
  final DateTime fecha;
  final double precio;
  final String metodoPago;
  final VoidCallback onMetodoPagoTap;
  final bool isLoading;
  final VoidCallback onConfirm;

  const _BookingSummary({
    required this.selectedTime,
    required this.fecha,
    required this.precio,
    required this.metodoPago,
    required this.onMetodoPagoTap,
    required this.isLoading,
    required this.onConfirm,
  });

  String get _pagoLabel {
    const m = {
      'yape': '💜 Yape',
      'plin': '💙 Plin',
      'efectivo': '💵 Efectivo',
      'tarjeta': '💳 Tarjeta',
    };
    return m[metodoPago] ?? metodoPago;
  }

  String _horaFin(String horaInicio) {
    final parts = horaInicio.split(':');
    final hora = int.parse(parts[0]) + 1;
    final hf = hora > 23 ? 23 : hora;
    return '${hf.toString().padLeft(2, '0')}:${parts[1]}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          24, 20, 24, MediaQuery.of(context).padding.bottom + 20),
      decoration: BoxDecoration(
        color: AppColors.sur,
        border: Border(top: BorderSide(color: AppColors.bdr)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 20,
              offset: const Offset(0, -5)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Resumen de reserva (visible cuando hay hora seleccionada) ──
          if (selectedTime != null) ...[
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: AppColors.accLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: AppColors.acc.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.event_available_rounded,
                      size: 14, color: AppColors.acc),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      AppDateUtils.formatearFechaLarga(fecha),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.tx,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.acc,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '$selectedTime – ${_horaFin(selectedTime!)}',
                      style: GoogleFonts.bricolageGrotesque(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Método de pago ──
            GestureDetector(
              onTap: onMetodoPagoTap,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: AppColors.bg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.bdr2),
                ),
                child: Row(
                  children: [
                    Text('Pagar con',
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 12, color: AppColors.tx3)),
                    const Spacer(),
                    Text(_pagoLabel,
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.tx)),
                    const SizedBox(width: 6),
                    const Icon(Icons.keyboard_arrow_down_rounded,
                        size: 16, color: AppColors.tx3),
                  ],
                ),
              ),
            ),
          ],

          // ── Total + botón ──────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Total a pagar',
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 11, color: AppColors.tx3)),
                  Text(
                    selectedTime != null
                        ? 'S/ ${precio.toStringAsFixed(2)}'
                        : '—',
                    style: GoogleFonts.bricolageGrotesque(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppColors.tx,
                    ),
                  ),
                ],
              ),
              ElevatedButton(
                onPressed:
                    (selectedTime != null && !isLoading) ? onConfirm : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.acc,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor:
                      AppColors.acc.withValues(alpha: 0.4),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 28, vertical: 16),
                  minimumSize: Size.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                    : Text(
                        'Confirmar Reserva',
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetodoPagoSheet extends StatelessWidget {
  final String seleccionado;
  final ValueChanged<String> onSeleccionado;

  const _MetodoPagoSheet(
      {required this.seleccionado, required this.onSeleccionado});

  @override
  Widget build(BuildContext context) {
    const metodos = [
      ('yape', '💜', 'Yape'),
      ('plin', '💙', 'Plin'),
      ('efectivo', '💵', 'Efectivo'),
      ('tarjeta', '💳', 'Tarjeta'),
    ];

    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
      decoration: BoxDecoration(
        color: AppColors.sur,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Método de pago',
            style: GoogleFonts.bricolageGrotesque(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.tx,
            ),
          ),
          const SizedBox(height: 16),
          ...metodos.map((m) {
            final (id, emoji, label) = m;
            final isSel = seleccionado == id;
            return GestureDetector(
              onTap: () => onSeleccionado(id),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: isSel ? AppColors.accLight : AppColors.bg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSel ? AppColors.acc : AppColors.bdr2,
                    width: isSel ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Text(emoji, style: const TextStyle(fontSize: 20)),
                    const SizedBox(width: 14),
                    Text(
                      label,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight:
                            isSel ? FontWeight.w600 : FontWeight.w400,
                        color: isSel ? AppColors.acc : AppColors.tx,
                      ),
                    ),
                    if (isSel) ...[
                      const Spacer(),
                      const Icon(Icons.check_circle_rounded,
                          color: AppColors.acc, size: 20),
                    ],
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}


// ── Error recuperable: cancha/complejo no disponibles (deep link) ─────────────

class _ErrorRecuperable extends StatelessWidget {
  final String mensaje;
  final VoidCallback onRetry;
  const _ErrorRecuperable({required this.mensaje, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.wifi_off_rounded,
                  color: AppColors.red, size: 28),
            ),
            const SizedBox(height: 16),
            Text(
              'No se pudo cargar la cancha',
              style: GoogleFonts.bricolageGrotesque(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.tx,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              mensaje,
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 13, color: AppColors.tx2, height: 1.5),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 15),
              label: Text('Reintentar',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.acc,
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Diálogo de pago simulado ──────────────────────────────────────────────────

class _PagoDialog extends StatefulWidget {
  final String metodoPago;
  final double precio;
  const _PagoDialog({required this.metodoPago, required this.precio});

  @override
  State<_PagoDialog> createState() => _PagoDialogState();
}

class _PagoDialogState extends State<_PagoDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  bool _aprobado = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..forward().then((_) {
        if (mounted) setState(() => _aprobado = true);
        Future.delayed(const Duration(milliseconds: 600), () {
          if (mounted) Navigator.of(context).pop(true);
        });
      });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  String get _metodoLabel {
    const m = {
      'yape': 'Yape 💜',
      'plin': 'Plin 💙',
      'efectivo': 'Efectivo 💵',
      'tarjeta': 'Tarjeta 💳',
    };
    return m[widget.metodoPago] ?? widget.metodoPago;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.sur,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _aprobado
                  ? Container(
                      key: const ValueKey('ok'),
                      width: 56,
                      height: 56,
                      decoration: const BoxDecoration(
                        color: AppColors.acc,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check_rounded,
                          color: Colors.white, size: 32),
                    )
                  : const SizedBox(
                      key: ValueKey('spin'),
                      width: 56,
                      height: 56,
                      child: CircularProgressIndicator(
                          color: AppColors.acc, strokeWidth: 3),
                    ),
            ),
            const SizedBox(height: 20),
            Text(
              _aprobado ? '¡Pago aprobado!' : 'Procesando pago…',
              style: GoogleFonts.bricolageGrotesque(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.tx,
              ),
            ),
            const SizedBox(height: 6),
            Text(_metodoLabel,
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 13, color: AppColors.tx3)),
            const SizedBox(height: 4),
            Text(
              'S/ ${widget.precio.toStringAsFixed(2)}',
              style: GoogleFonts.bricolageGrotesque(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppColors.acc,
              ),
            ),
            if (!_aprobado) ...[
              const SizedBox(height: 16),
              AnimatedBuilder(
                animation: _ctrl,
                builder: (_, idx) => LinearProgressIndicator(
                  value: _ctrl.value,
                  backgroundColor: AppColors.bdr2,
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(AppColors.acc),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
