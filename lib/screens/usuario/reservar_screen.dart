// screens/usuario/reservar_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/app_date_utils.dart';
import '../../models/cancha_model.dart';
import '../../models/complejo_model.dart';
import '../../models/reserva_model.dart';
import '../../providers/complejos_provider.dart';
import '../../providers/reservas_provider.dart';

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

  @override
  void initState() {
    super.initState();
    // Siempre normalizado a fecha-pura (sin componente de tiempo)
    // para que la clave del provider sea estable durante el día.
    final now = DateTime.now();
    _fechaSeleccionada = DateTime(now.year, now.month, now.day);
  }

  @override
  Widget build(BuildContext context) {
    final canchaAsync = ref.watch(
      canchaFutureProvider((
        complejoId: widget.complejoId,
        canchaId: widget.canchaId,
      )),
    );
    final complejoAsync = ref.watch(complejoFutureProvider(widget.complejoId));

    // ── Watch en el nivel de build — nunca dentro de métodos condicionales ──
    final disponibilidadAsync = ref.watch(
      disponibilidadProvider((
        complejoId: widget.complejoId,
        canchaId: widget.canchaId,
        fecha: _fechaSeleccionada,
      )),
    );
    final isLoading = ref.watch(reservaNotifierProvider).isLoading;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => context.pop(),
        ),
        title: canchaAsync.when(
          data: (c) => Text(
            c?.nombre ?? 'Reservar cancha',
            style: GoogleFonts.bricolageGrotesque(
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          loading: () => const SizedBox.shrink(),
          error: (_, _) => Text(
            'Reservar cancha',
            style: GoogleFonts.bricolageGrotesque(
                fontSize: 18, fontWeight: FontWeight.w700),
          ),
        ),
      ),
      body: canchaAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator(color: AppColors.acc)),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (cancha) {
          if (cancha == null) {
            return const Center(child: Text('Cancha no encontrada'));
          }
          return complejoAsync.when(
            loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.acc)),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (complejo) {
              if (complejo == null) {
                return const Center(child: Text('Complejo no encontrado'));
              }
              return _buildBody(
                context,
                cancha,
                complejo,
                disponibilidadAsync,
                isLoading,
              );
            },
          );
        },
      ),
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
                  // Normalizar siempre al seleccionar
                  _fechaSeleccionada = DateTime(d.year, d.month, d.day);
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

              disponibilidadAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.all(20),
                  child: Center(
                      child: CircularProgressIndicator(color: AppColors.acc)),
                ),
                error: (_, _) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _TimeSlotsGrid(
                    slots: slots,
                    ocupadas: const [],
                    fecha: _fechaSeleccionada,
                    precio: cancha.precioBase,
                    selectedTime: _horaSeleccionada,
                    onTimeSelected: (t) =>
                        setState(() => _horaSeleccionada = t),
                  ),
                ),
                data: (reservas) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _TimeSlotsGrid(
                    slots: slots,
                    ocupadas: reservas
                        .where((r) => r.estado != 'cancelada')
                        .map((r) => r.horaInicio)
                        .toList(),
                    fecha: _fechaSeleccionada,
                    precio: cancha.precioBase,
                    selectedTime: _horaSeleccionada,
                    onTimeSelected: (t) =>
                        setState(() => _horaSeleccionada = t),
                  ),
                ),
              ),

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
            onConfirm: () => _confirmarReserva(cancha),
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

  Future<void> _confirmarReserva(CanchaModel cancha) async {
    if (_horaSeleccionada == null) return;

    final horaFin = _calcularHoraFin(_horaSeleccionada!);
    final reservaId =
        await ref.read(reservaNotifierProvider.notifier).crearReserva(
              complejoId: widget.complejoId,
              canchaId: widget.canchaId,
              fecha: _fechaSeleccionada,
              horaInicio: _horaSeleccionada!,
              horaFin: horaFin,
              duracionHoras: 1.0,
              precioTotal: cancha.precioBase,
              metodoPago: _metodoPago,
            );

    if (reservaId != null && mounted) {
      context.pushReplacement('/confirmacion/$reservaId');
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error al crear la reserva. Intenta nuevamente.'),
          backgroundColor: AppColors.red,
        ),
      );
    }
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
        separatorBuilder: (_, _) => const SizedBox(width: 8),
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
    // Mismo día → comparar hora
    final hora = int.parse(slot.split(':')[0]);
    return hora <= now.hour;
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
