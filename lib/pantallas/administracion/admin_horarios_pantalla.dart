// screens/admin/admin_horarios_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../nucleo/tema/app_colores.dart';
import '../../nucleo/utilidades/app_fecha_utilidades.dart';
import '../../modelos/cancha_modelo.dart';
import '../../modelos/complejo_modelo.dart';
import '../../modelos/reserva_modelo.dart';
import '../../proveedores/auth_proveedor.dart';
import '../../proveedores/complejos_proveedor.dart';
import '../../proveedores/reservas_proveedor.dart';
import '../../repositorios/reservas_repositorio.dart';
import 'admin_agregar_cancha_pantalla.dart';

class AdminHorariosScreen extends ConsumerStatefulWidget {
  const AdminHorariosScreen({super.key});

  @override
  ConsumerState<AdminHorariosScreen> createState() =>
      _AdminHorariosScreenState();
}

class _AdminHorariosScreenState extends ConsumerState<AdminHorariosScreen>
    with SingleTickerProviderStateMixin {
  DateTime _fecha = AppDateUtils.hoy();
  int _canchaIdx = 0;

  // Genera los 14 días del strip (3 atrás + hoy + 10 adelante)
  late final List<DateTime> _dias = List.generate(
    14,
    (i) => AppDateUtils.hoy().subtract(const Duration(days: 3)).add(Duration(days: i)),
  );

  static const _diasSemana = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
  static const _meses = [
    '', 'ene', 'feb', 'mar', 'abr', 'may', 'jun',
    'jul', 'ago', 'sep', 'oct', 'nov', 'dic',
  ];

  // Construye un mapa hora→reserva incluyendo horas de continuación
  Map<String, ({ReservaModel reserva, bool esInicio})> _buildOcupado(
      List<ReservaModel> reservas, List<String> slots) {
    final mapa = <String, ({ReservaModel reserva, bool esInicio})>{};
    for (final r in reservas) {
      final startIdx = slots.indexOf(r.horaInicio);
      if (startIdx == -1) continue;
      final duracion = r.duracionHoras.ceil();
      for (int i = 0; i < duracion; i++) {
        final idx = startIdx + i;
        if (idx < slots.length) {
          mapa[slots[idx]] = (reserva: r, esInicio: i == 0);
        }
      }
    }
    return mapa;
  }

  @override
  Widget build(BuildContext context) {
    final complejoId = ref.watch(complejoIdProvider);
    if (complejoId == null) {
      return const Scaffold(
        backgroundColor: AppColors.adminBg,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.adminGreen),
        ),
      );
    }

    final complejoAsync = ref.watch(complejoProvider(complejoId));
    final canchasAsync = ref.watch(canchasAdminProvider(complejoId));
    final reservasAsync = ref.watch(reservasComplejoFechaProvider(
        (complejoId: complejoId, fecha: _fecha)));

    return Scaffold(
      backgroundColor: AppColors.adminBg,
      appBar: AppBar(
        backgroundColor: AppColors.adminS1,
        elevation: 0,
        title: Text(
          'Horarios',
          style: GoogleFonts.bricolageGrotesque(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.atx,
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: _seleccionarFecha,
            icon: const Icon(Icons.calendar_today_rounded,
                color: AppColors.adminGreen, size: 16),
            label: Text(
              AppDateUtils.fechaRelativa(_fecha),
              style: GoogleFonts.outfit(
                color: AppColors.adminGreen,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
      body: canchasAsync.when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.adminGreen)),
        error: (e, _) => _ErrorView(
          msg: 'Error al cargar canchas',
          onRetry: () => ref.invalidate(canchasAdminProvider(complejoId)),
        ),
        data: (canchas) {
          if (canchas.isEmpty) {
            return _EmptyCanchas(complejoId: complejoId);
          }

          // Ajustar índice si se eliminó una cancha
          if (_canchaIdx >= canchas.length) _canchaIdx = 0;
          final cancha = canchas[_canchaIdx];

          final complejo = complejoAsync.asData?.value;
          final slots = AppDateUtils.generarSlots(
            apertura: complejo?.horarioApertura ?? '07:00',
            cierre: complejo?.horarioCierre ?? '23:00',
          );

          return Column(
            children: [
              // ── Strip de fechas ─────────────────────────────
              _DateStrip(
                dias: _dias,
                selected: _fecha,
                onSelect: (d) => setState(() => _fecha = d),
                diasSemana: _diasSemana,
                meses: _meses,
              ),

              // ── Resumen del día ─────────────────────────────
              reservasAsync.when(
                loading: () => const SizedBox(height: 52),
                error: (_, _) => const SizedBox(height: 52),
                data: (res) => _DaySummary(reservas: res),
              ),

              // ── Selector de canchas ─────────────────────────
              _CanchaTabBar(
                canchas: canchas,
                selectedIdx: _canchaIdx,
                onSelect: (i) => setState(() => _canchaIdx = i),
                onAgregarCancha: () async {
                  await Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => AdminAgregarCanchaScreen(
                      complejoId: complejoId,
                    ),
                  ));
                  // El stream canchasAdminProvider se actualiza solo vía Firestore
                },
              ),

              // ── Schedule ────────────────────────────────────
              Expanded(
                child: reservasAsync.when(
                  loading: () => const Center(
                      child: CircularProgressIndicator(
                          color: AppColors.adminGreen)),
                  error: (e, _) => _ErrorView(
                    msg: 'Error al cargar reservas',
                    onRetry: () => ref.invalidate(
                        reservasComplejoFechaProvider(
                            (complejoId: complejoId, fecha: _fecha))),
                  ),
                  data: (todasReservas) {
                    final reservas = todasReservas
                        .where((r) => r.canchaId == cancha.id)
                        .toList();
                    final ocupado = _buildOcupado(reservas, slots);
                    return _ScheduleList(
                      slots: slots,
                      ocupado: ocupado,
                      cancha: cancha,
                      complejo: complejo,
                      fecha: _fecha,
                      complejoId: complejoId,
                      onAction: () => ref.invalidate(
                          reservasComplejoFechaProvider(
                              (complejoId: complejoId, fecha: _fecha))),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _seleccionarFecha() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _fecha,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 60)),
      builder: (ctx, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(primary: AppColors.adminGreen),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _fecha = picked);
  }
}

// ── Strip de fechas ────────────────────────────────────────────────────────────

class _DateStrip extends StatefulWidget {
  final List<DateTime> dias;
  final DateTime selected;
  final void Function(DateTime) onSelect;
  final List<String> diasSemana;
  final List<String> meses;

  const _DateStrip({
    required this.dias,
    required this.selected,
    required this.onSelect,
    required this.diasSemana,
    required this.meses,
  });

  @override
  State<_DateStrip> createState() => _DateStripState();
}

class _DateStripState extends State<_DateStrip> {
  final _sc = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToToday());
  }

  void _scrollToToday() {
    final todayIdx = widget.dias.indexWhere((d) {
      final hoy = AppDateUtils.hoy();
      return d.year == hoy.year && d.month == hoy.month && d.day == hoy.day;
    });
    if (todayIdx < 0) return;
    final offset = (todayIdx - 1) * 60.0;
    _sc.animateTo(
      offset.clamp(0, double.infinity),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _sc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hoy = AppDateUtils.hoy();
    return Container(
      height: 72,
      color: AppColors.adminS1,
      child: ListView.builder(
        controller: _sc,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        itemCount: widget.dias.length,
        itemBuilder: (_, i) {
          final d = widget.dias[i];
          final esHoy = d.year == hoy.year && d.month == hoy.month && d.day == hoy.day;
          final esSel = d.year == widget.selected.year &&
              d.month == widget.selected.month &&
              d.day == widget.selected.day;
          final diaLabel = widget.diasSemana[d.weekday - 1];
          final mesLabel = widget.meses[d.month];
          return GestureDetector(
            onTap: () => widget.onSelect(d),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 52,
              margin: const EdgeInsets.only(right: 6),
              decoration: BoxDecoration(
                color: esSel
                    ? AppColors.adminGreen
                    : esHoy
                        ? AppColors.aaccD
                        : AppColors.adminS2,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: esHoy && !esSel
                      ? AppColors.adminGreen.withValues(alpha: 0.4)
                      : Colors.transparent,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    diaLabel,
                    style: GoogleFonts.outfit(
                      fontSize: 10,
                      color: esSel
                          ? Colors.black
                          : esHoy
                              ? AppColors.adminGreen
                              : AppColors.atx3,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    '${d.day}',
                    style: GoogleFonts.bricolageGrotesque(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: esSel ? Colors.black : AppColors.atx,
                    ),
                  ),
                  Text(
                    mesLabel,
                    style: GoogleFonts.outfit(
                      fontSize: 9,
                      color: esSel ? Colors.black54 : AppColors.atx3,
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

// ── Resumen del día ────────────────────────────────────────────────────────────

class _DaySummary extends StatelessWidget {
  final List<ReservaModel> reservas;
  const _DaySummary({required this.reservas});

  @override
  Widget build(BuildContext context) {
    final activas = reservas.where((r) => !r.estaCancelada).toList();
    final pendientes = activas.where((r) => r.estaPendiente).length;
    final ingresos = activas
        .where((r) => r.estaConfirmada)
        .fold<double>(0, (s, r) => s + r.precioTotal);

    return Container(
      color: AppColors.adminS1,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Row(
        children: [
          _Stat(label: 'Reservas', value: '${activas.length}',
              color: AppColors.adminGreen),
          const SizedBox(width: 20),
          _Stat(
              label: 'Ingresos',
              value: 'S/ ${ingresos.toStringAsFixed(0)}',
              color: AppColors.aamber),
          const SizedBox(width: 20),
          if (pendientes > 0)
            _Stat(
                label: 'Pendientes',
                value: '$pendientes',
                color: AppColors.ared),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _Stat({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          value,
          style: GoogleFonts.bricolageGrotesque(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.atx,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: GoogleFonts.outfit(fontSize: 11, color: AppColors.atx3),
        ),
      ],
    );
  }
}

// ── Cancha tabs ────────────────────────────────────────────────────────────────

class _CanchaTabBar extends StatelessWidget {
  final List<CanchaModel> canchas;
  final int selectedIdx;
  final void Function(int) onSelect;
  final VoidCallback? onAgregarCancha;

  const _CanchaTabBar({
    required this.canchas,
    required this.selectedIdx,
    required this.onSelect,
    this.onAgregarCancha,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      color: AppColors.adminS1,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
        // +1 por el botón "+"
        itemCount: canchas.length + 1,
        itemBuilder: (_, i) {
          // Último ítem: botón agregar cancha
          if (i == canchas.length) {
            return GestureDetector(
              onTap: onAgregarCancha,
              child: Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: AppColors.aaccD,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: AppColors.aacc.withValues(alpha: 0.4)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.add_rounded,
                        size: 15, color: AppColors.aacc),
                    const SizedBox(width: 4),
                    Text(
                      'Agregar',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.aacc,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          final c = canchas[i];
          final sel = i == selectedIdx;
          return GestureDetector(
            onTap: () => onSelect(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: sel ? AppColors.adminGreen : AppColors.adminS2,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Text(c.deporteEmoji, style: const TextStyle(fontSize: 13)),
                  const SizedBox(width: 5),
                  Text(
                    c.nombre,
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: sel ? Colors.black : AppColors.atx2,
                    ),
                  ),
                  if (!c.activa) ...[
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: AppColors.ared.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'inactiva',
                        style: GoogleFonts.outfit(
                            fontSize: 9, color: AppColors.ared),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── Schedule list ──────────────────────────────────────────────────────────────

class _ScheduleList extends StatelessWidget {
  final List<String> slots;
  final Map<String, ({ReservaModel reserva, bool esInicio})> ocupado;
  final CanchaModel cancha;
  final ComplejoModel? complejo;
  final DateTime fecha;
  final String complejoId;
  final VoidCallback onAction;

  const _ScheduleList({
    required this.slots,
    required this.ocupado,
    required this.cancha,
    required this.complejo,
    required this.fecha,
    required this.complejoId,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    if (slots.isEmpty) {
      return const Center(
        child: Text('Sin horarios configurados',
            style: TextStyle(color: AppColors.atx3)),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      itemCount: slots.length,
      separatorBuilder: (_, _) => const SizedBox(height: 4),
      itemBuilder: (_, i) {
        final hora = slots[i];
        final entry = ocupado[hora];

        if (entry == null) {
          // Slot libre
          return _SlotLibre(
            hora: hora,
            precio: cancha.precioBase,
          );
        }

        if (!entry.esInicio) {
          // Continuación de reserva multi-hora
          return _SlotContinuacion(
            hora: hora,
            reserva: entry.reserva,
          );
        }

        // Reserva activa
        return _SlotReservado(
          hora: hora,
          reserva: entry.reserva,
          onTap: () => _mostrarDetalle(context, entry.reserva),
          onConfirmar: entry.reserva.estaPendiente
              ? () => _confirmar(context, entry.reserva.id)
              : null,
          onRechazar: entry.reserva.estaPendiente
              ? () => _rechazar(context, entry.reserva.id)
              : null,
        );
      },
    );
  }

  Future<void> _confirmar(BuildContext ctx, String reservaId) async {
    try {
      await ReservasRepository().confirmarReserva(reservaId);
      onAction();
      if (ctx.mounted) {
        ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(
          content: Text('Reserva confirmada'),
          backgroundColor: AppColors.adminGreen,
        ));
      }
    } catch (e) {
      if (ctx.mounted) {
        ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppColors.ared,
        ));
      }
    }
  }

  Future<void> _rechazar(BuildContext ctx, String reservaId) async {
    final ok = await showDialog<bool>(
      context: ctx,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.adminS2,
        title: Text('Rechazar reserva',
            style: GoogleFonts.bricolageGrotesque(color: AppColors.atx)),
        content: Text(
          '¿Rechazar esta solicitud? El pago será devuelto al jugador.',
          style: GoogleFonts.outfit(color: AppColors.atx2),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancelar',
                style: GoogleFonts.outfit(color: AppColors.atx3)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.ared),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Rechazar',
                style: GoogleFonts.outfit(color: Colors.white)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ReservasRepository().rechazarReserva(reservaId);
      onAction();
      if (ctx.mounted) {
        ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(
          content: Text('Reserva rechazada — pago devuelto'),
          backgroundColor: AppColors.ared,
        ));
      }
    } catch (e) {
      if (ctx.mounted) {
        ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppColors.ared,
        ));
      }
    }
  }

  void _mostrarDetalle(BuildContext ctx, ReservaModel r) {
    showModalBottomSheet(
      context: ctx,
      backgroundColor: AppColors.adminS2,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _ReservaDetalle(reserva: r, onAction: onAction),
    );
  }
}

// ── Slot widgets ───────────────────────────────────────────────────────────────

class _SlotLibre extends StatelessWidget {
  final String hora;
  final double precio;
  const _SlotLibre({required this.hora, required this.precio});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.adminS2,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.abdr),
      ),
      child: Row(
        children: [
          Text(
            hora,
            style: GoogleFonts.outfit(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.atx3,
            ),
          ),
          const Spacer(),
          Text(
            'Libre',
            style: GoogleFonts.outfit(fontSize: 12, color: AppColors.atx3),
          ),
          const SizedBox(width: 8),
          Text(
            'S/ ${precio.toStringAsFixed(0)}',
            style: GoogleFonts.outfit(
              fontSize: 12,
              color: AppColors.adminGreen.withValues(alpha: 0.7),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _SlotContinuacion extends StatelessWidget {
  final String hora;
  final ReservaModel reserva;
  const _SlotContinuacion({required this.hora, required this.reserva});

  @override
  Widget build(BuildContext context) {
    final color = _colorForReserva(reserva);
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Text(
            hora,
            style: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: color.withValues(alpha: 0.5)),
          ),
          const SizedBox(width: 10),
          Icon(Icons.more_vert_rounded, size: 14, color: color.withValues(alpha: 0.4)),
          const SizedBox(width: 4),
          Text(
            'continúa',
            style: GoogleFonts.outfit(
                fontSize: 11, color: color.withValues(alpha: 0.5)),
          ),
        ],
      ),
    );
  }
}

class _SlotReservado extends StatelessWidget {
  final String hora;
  final ReservaModel reserva;
  final VoidCallback onTap;
  final VoidCallback? onConfirmar;
  final VoidCallback? onRechazar;

  const _SlotReservado({
    required this.hora,
    required this.reserva,
    required this.onTap,
    this.onConfirmar,
    this.onRechazar,
  });

  @override
  Widget build(BuildContext context) {
    final color = _colorForReserva(reserva);
    final esPendiente = reserva.estaPendiente;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.35), width: 1.2),
        ),
        child: Row(
          children: [
            // Indicador de color
            Container(
              width: 3,
              height: 32,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 10),
            // Hora
            Text(
              hora,
              style: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            const SizedBox(width: 10),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      _TipoBadge(reserva: reserva),
                      const SizedBox(width: 6),
                      Text(
                        '${reserva.duracionHoras.toStringAsFixed(0)}h · S/ ${reserva.precioTotal.toStringAsFixed(0)}',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          color: AppColors.atx,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '${reserva.metodoPago.toUpperCase()} · hasta ${reserva.horaFin}',
                    style: GoogleFonts.outfit(
                        fontSize: 10, color: AppColors.atx3),
                  ),
                ],
              ),
            ),
            // Acciones para pendientes
            if (esPendiente && onConfirmar != null) ...[
              _ActionBtn(
                icon: Icons.check_rounded,
                color: AppColors.adminGreen,
                onTap: onConfirmar!,
              ),
              const SizedBox(width: 6),
              _ActionBtn(
                icon: Icons.close_rounded,
                color: AppColors.ared,
                onTap: onRechazar!,
              ),
            ] else ...[
              const Icon(Icons.chevron_right_rounded,
                  size: 16, color: AppColors.atx3),
            ],
          ],
        ),
      ),
    );
  }
}

class _TipoBadge extends StatelessWidget {
  final ReservaModel reserva;
  const _TipoBadge({required this.reserva});

  @override
  Widget build(BuildContext context) {
    final (label, color) = reserva.estaPendiente
        ? ('PENDIENTE', AppColors.aamber)
        : reserva.esPartido
            ? ('PARTIDO', AppColors.ablu)
            : ('RESERVADA', AppColors.ared);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: GoogleFonts.outfit(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: color,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _ActionBtn(
      {required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Icon(icon, size: 16, color: color),
      ),
    );
  }
}

Color _colorForReserva(ReservaModel r) {
  if (r.estaPendiente) return AppColors.aamber;
  if (r.esPartido) return AppColors.ablu;
  return AppColors.ared;
}

// ── Detalle de reserva (bottom sheet) ─────────────────────────────────────────

class _ReservaDetalle extends StatelessWidget {
  final ReservaModel reserva;
  final VoidCallback onAction;
  const _ReservaDetalle({required this.reserva, required this.onAction});

  @override
  Widget build(BuildContext context) {
    final color = _colorForReserva(reserva);
    final dateLabel = DateFormat('EEEE d MMM', 'es').format(reserva.fecha);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
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
                color: AppColors.atx3,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Header
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  _estadoLabel(reserva),
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: color,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                'S/ ${reserva.precioTotal.toStringAsFixed(2)}',
                style: GoogleFonts.bricolageGrotesque(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.atx,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Info grid
          _InfoRow(
              icon: Icons.calendar_today_rounded,
              label: 'Fecha',
              value: dateLabel),
          _InfoRow(
              icon: Icons.access_time_rounded,
              label: 'Horario',
              value: '${reserva.horaInicio} – ${reserva.horaFin} '
                  '(${reserva.duracionHoras.toStringAsFixed(0)}h)'),
          _InfoRow(
              icon: Icons.payment_rounded,
              label: 'Pago',
              value: reserva.metodoPago.toUpperCase()),
          _InfoRow(
              icon: Icons.confirmation_number_rounded,
              label: 'Tipo',
              value: reserva.esPartido ? 'Partido grupal' : 'Reserva directa'),
          _InfoRow(
              icon: Icons.person_outline_rounded,
              label: 'Cliente',
              value: 'ID: …${reserva.userId.substring(reserva.userId.length > 8 ? reserva.userId.length - 8 : 0)}'),

          const SizedBox(height: 20),

          // Acciones
          if (reserva.estaPendiente)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.ared),
                      foregroundColor: AppColors.ared,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.close_rounded, size: 18),
                    label: Text('Rechazar',
                        style: GoogleFonts.outfit(
                            fontWeight: FontWeight.w600)),
                    onPressed: () async {
                      Navigator.pop(context);
                      await ReservasRepository()
                          .rechazarReserva(reserva.id);
                      onAction();
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.adminGreen,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.check_rounded, size: 18),
                    label: Text('Confirmar',
                        style: GoogleFonts.outfit(
                            fontWeight: FontWeight.w700)),
                    onPressed: () async {
                      Navigator.pop(context);
                      await ReservasRepository()
                          .confirmarReserva(reserva.id);
                      onAction();
                    },
                  ),
                ),
              ],
            )
          else if (reserva.estaConfirmada)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.ared),
                  foregroundColor: AppColors.ared,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.cancel_outlined, size: 18),
                label: Text('Cancelar reserva',
                    style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
                onPressed: () async {
                  Navigator.pop(context);
                  await ReservasRepository().cancelarReserva(reserva.id);
                  onAction();
                },
              ),
            ),
        ],
      ),
    );
  }

  String _estadoLabel(ReservaModel r) {
    if (r.estaPendiente) return 'PENDIENTE DE APROBACIÓN';
    if (r.estaConfirmada) return 'CONFIRMADA';
    if (r.estaCancelada) return 'CANCELADA';
    return r.estado.toUpperCase();
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 15, color: AppColors.atx3),
          const SizedBox(width: 8),
          Text('$label: ',
              style: GoogleFonts.outfit(
                  fontSize: 13, color: AppColors.atx3)),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.outfit(
                fontSize: 13,
                color: AppColors.atx,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── States ─────────────────────────────────────────────────────────────────────

class _EmptyCanchas extends StatelessWidget {
  final String complejoId;
  const _EmptyCanchas({required this.complejoId});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.stadium_outlined,
                color: AppColors.atx3, size: 56),
            const SizedBox(height: 16),
            Text(
              'Sin canchas configuradas',
              style: GoogleFonts.bricolageGrotesque(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.atx,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Agrega tu primera cancha para\ngestionar tus horarios.',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                  fontSize: 14, color: AppColors.atx2),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.adminGreen,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.add_rounded, size: 20),
              label: Text('Agregar cancha',
                  style: GoogleFonts.outfit(
                      fontWeight: FontWeight.w700)),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) =>
                      AdminAgregarCanchaScreen(complejoId: complejoId),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String msg;
  final VoidCallback onRetry;
  const _ErrorView({required this.msg, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.wifi_off_rounded,
              color: AppColors.atx3, size: 40),
          const SizedBox(height: 12),
          Text(msg,
              style: GoogleFonts.outfit(
                  color: AppColors.atx2, fontSize: 14)),
          const SizedBox(height: 12),
          TextButton(
            onPressed: onRetry,
            child: Text('Reintentar',
                style: GoogleFonts.outfit(color: AppColors.adminGreen)),
          ),
        ],
      ),
    );
  }
}
