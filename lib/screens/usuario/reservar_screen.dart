// screens/usuario/reservar_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/precio_utils.dart';
import '../../models/cancha_model.dart';
import '../../models/complejo_model.dart';
import '../../providers/complejos_provider.dart';
import '../../providers/reservas_provider.dart';
import '../../widgets/common/error_widget.dart';
import '../../widgets/common/loading_skeleton.dart';

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
  DateTime _fechaSeleccionada = DateTime.now();
  String? _horaSeleccionada;
  int _duracion = 1;
  String _metodoPago = 'yape';

  // Horas disponibles (07:00 - 22:00)
  final List<String> _todasLasHoras = List.generate(
    16,
    (i) => '${(i + 7).toString().padLeft(2, '0')}:00',
  );

  @override
  Widget build(BuildContext context) {
    final complejoAsync =
        ref.watch(complejoFutureProvider(widget.complejoId));
    final canchaAsync = ref.watch(canchaFutureProvider(
        (complejoId: widget.complejoId, canchaId: widget.canchaId)));

    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: AppBar(
        backgroundColor: AppColors.paper,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Reservar cancha',
          style: GoogleFonts.bricolageGrotesque(
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: complejoAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.green),
        ),
        error: (e, _) => AppErrorWidget(
          mensaje: 'No se pudo cargar la cancha',
          onReintentar: () => ref.invalidate(
              complejoFutureProvider(widget.complejoId)),
        ),
        data: (complejo) {
          if (complejo == null) {
            return const AppErrorWidget(
                mensaje: 'Complejo no encontrado');
          }
          return canchaAsync.when(
            loading: () => const Center(
              child: CircularProgressIndicator(color: AppColors.green),
            ),
            error: (e, _) =>
                const AppErrorWidget(mensaje: 'Cancha no encontrada'),
            data: (cancha) {
              if (cancha == null) {
                return const AppErrorWidget(
                    mensaje: 'Cancha no encontrada');
              }
              return _buildContenido(complejo, cancha);
            },
          );
        },
      ),
    );
  }

  Widget _buildContenido(ComplejoModel complejo, CanchaModel cancha) {
    final reservasAsync = ref.watch(disponibilidadProvider((
      complejoId: widget.complejoId,
      canchaId: widget.canchaId,
      fecha: _fechaSeleccionada,
    )));

    final reservasOcupadas = reservasAsync.valueOrNull ?? [];
    final horasOcupadas = reservasOcupadas
        .map((r) => r.horaInicio)
        .toSet();

    final precioCalculado = _horaSeleccionada != null
        ? cancha.precioBase * _duracion
        : 0.0;

    return Column(
      children: [
        // Contenido scrollable
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Info cancha
              _CanchaInfoCard(complejo: complejo, cancha: cancha),
              const SizedBox(height: 20),

              // Selector de fecha
              const _SeccionTitulo(titulo: 'Selecciona la fecha', icono: '📅'),
              const SizedBox(height: 10),
              _SelectorFecha(
                fechaSeleccionada: _fechaSeleccionada,
                onFechaChanged: (f) =>
                    setState(() {
                      _fechaSeleccionada = f;
                      _horaSeleccionada = null;
                    }),
              ),
              const SizedBox(height: 20),

              // Selector de duración
              const _SeccionTitulo(titulo: 'Duración', icono: '⏱️'),
              const SizedBox(height: 10),
              _SelectorDuracion(
                duracion: _duracion,
                onChanged: (d) => setState(() => _duracion = d),
              ),
              const SizedBox(height: 20),

              // Grid de horas
              const _SeccionTitulo(titulo: 'Horario disponible', icono: '🕐'),
              const SizedBox(height: 10),
              reservasAsync.when(
                loading: () => const HorarioGridSkeleton(),
                error: (_, __) => const AppErrorWidget(
                    mensaje: 'Error cargando disponibilidad'),
                data: (_) => _GridHoras(
                  horas: _todasLasHoras,
                  horasOcupadas: horasOcupadas,
                  horaSeleccionada: _horaSeleccionada,
                  duracion: _duracion,
                  precioBase: cancha.precioBase,
                  onHoraSelected: (h) =>
                      setState(() => _horaSeleccionada = h),
                ),
              ),
              const SizedBox(height: 20),

              // Método de pago
              const _SeccionTitulo(titulo: 'Método de pago', icono: '💳'),
              const SizedBox(height: 10),
              _SelectorPago(
                seleccionado: _metodoPago,
                onChanged: (m) => setState(() => _metodoPago = m),
              ),
              const SizedBox(height: 100), // espacio para el botón
            ],
          ),
        ),

        // Botón confirmar (fijo abajo)
        _BarraConfirmar(
          horaSeleccionada: _horaSeleccionada,
          duracion: _duracion,
          precio: precioCalculado,
          onConfirmar: _horaSeleccionada != null
              ? () => _confirmarReserva(cancha)
              : null,
        ),
      ],
    );
  }

  Future<void> _confirmarReserva(CanchaModel cancha) async {
    if (_horaSeleccionada == null) return;

    final horaInicioH = int.parse(_horaSeleccionada!.split(':')[0]);
    final horaFin =
        '${(horaInicioH + _duracion).toString().padLeft(2, '0')}:00';

    final notifier = ref.read(reservaNotifierProvider.notifier);
    final reservaId = await notifier.crearReserva(
      complejoId: widget.complejoId,
      canchaId: widget.canchaId,
      fecha: _fechaSeleccionada,
      horaInicio: _horaSeleccionada!,
      horaFin: horaFin,
      duracionHoras: _duracion.toDouble(),
      precioTotal: cancha.precioBase * _duracion,
      metodoPago: _metodoPago,
    );

    if (reservaId != null && mounted) {
      context.pushReplacement('/confirmacion/$reservaId');
    } else if (mounted) {
      final state = ref.read(reservaNotifierProvider);
      if (state.hasError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error al reservar. Intenta de nuevo.',
              style: GoogleFonts.outfit(),
            ),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    }
  }
}

// ── Sub-widgets ──────────────────────────────────────────────

class _CanchaInfoCard extends StatelessWidget {
  final ComplejoModel complejo;
  final CanchaModel cancha;

  const _CanchaInfoCard({required this.complejo, required this.cancha});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.greenLight,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Text(cancha.deporteEmoji,
                  style: const TextStyle(fontSize: 26)),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  complejo.nombre,
                  style: GoogleFonts.bricolageGrotesque(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
                Text(
                  '${cancha.nombre} · ${cancha.deporteLabel}',
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    color: AppColors.ink.withValues(alpha: 0.55),
                  ),
                ),
                Text(
                  cancha.superficieLabel,
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    color: AppColors.ink.withValues(alpha: 0.4),
                  ),
                ),
              ],
            ),
          ),
          Text(
            PrecioUtils.formatear(cancha.precioBase),
            style: GoogleFonts.bricolageGrotesque(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.green,
            ),
          ),
        ],
      ),
    );
  }
}

class _SeccionTitulo extends StatelessWidget {
  final String titulo;
  final String icono;

  const _SeccionTitulo({required this.titulo, required this.icono});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(icono, style: const TextStyle(fontSize: 16)),
        const SizedBox(width: 8),
        Text(
          titulo,
          style: GoogleFonts.outfit(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppColors.ink,
          ),
        ),
      ],
    );
  }
}

class _SelectorFecha extends StatelessWidget {
  final DateTime fechaSeleccionada;
  final void Function(DateTime) onFechaChanged;

  const _SelectorFecha({
    required this.fechaSeleccionada,
    required this.onFechaChanged,
  });

  @override
  Widget build(BuildContext context) {
    final hoy = DateTime.now();
    final dias = List.generate(14, (i) => hoy.add(Duration(days: i)));

    return SizedBox(
      height: 72,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: dias.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final dia = dias[i];
          final seleccionado = dia.day == fechaSeleccionada.day &&
              dia.month == fechaSeleccionada.month;
          final diaNombre =
              ['lun', 'mar', 'mié', 'jue', 'vie', 'sáb', 'dom']
                  [dia.weekday - 1];

          return GestureDetector(
            onTap: () => onFechaChanged(dia),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 52,
              decoration: BoxDecoration(
                color: seleccionado ? AppColors.green : AppColors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: seleccionado ? AppColors.green : AppColors.line,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    diaNombre,
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: seleccionado
                          ? Colors.white.withValues(alpha: 0.8)
                          : AppColors.ink.withValues(alpha: 0.5),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${dia.day}',
                    style: GoogleFonts.bricolageGrotesque(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: seleccionado ? Colors.white : AppColors.ink,
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

class _SelectorDuracion extends StatelessWidget {
  final int duracion;
  final void Function(int) onChanged;

  const _SelectorDuracion(
      {required this.duracion, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [1, 2, 3].map((d) {
        final sel = duracion == d;
        return Padding(
          padding: const EdgeInsets.only(right: 10),
          child: GestureDetector(
            onTap: () => onChanged(d),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: sel ? AppColors.green : AppColors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: sel ? AppColors.green : AppColors.line,
                ),
              ),
              child: Text(
                '$d hora${d > 1 ? 's' : ''}',
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: sel ? Colors.white : AppColors.ink,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _GridHoras extends StatelessWidget {
  final List<String> horas;
  final Set<String> horasOcupadas;
  final String? horaSeleccionada;
  final int duracion;
  final double precioBase;
  final void Function(String) onHoraSelected;

  const _GridHoras({
    required this.horas,
    required this.horasOcupadas,
    required this.horaSeleccionada,
    required this.duracion,
    required this.precioBase,
    required this.onHoraSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: horas.map((hora) {
        final ocupada = horasOcupadas.contains(hora);
        final seleccionada = hora == horaSeleccionada;

        Color bgColor = AppColors.white;
        Color borderColor = AppColors.line;
        Color textColor = AppColors.ink;

        if (ocupada) {
          bgColor = AppColors.line.withValues(alpha: 0.6);
          textColor = AppColors.ink.withValues(alpha: 0.3);
        } else if (seleccionada) {
          bgColor = AppColors.green;
          borderColor = AppColors.green;
          textColor = Colors.white;
        }

        return GestureDetector(
          onTap: ocupada ? null : () => onHoraSelected(hora),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: borderColor),
            ),
            child: Column(
              children: [
                Text(
                  hora,
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
                if (!ocupada)
                  Text(
                    'S/${(precioBase * duracion).toStringAsFixed(0)}',
                    style: GoogleFonts.outfit(
                      fontSize: 10,
                      color: seleccionada
                          ? Colors.white.withValues(alpha: 0.8)
                          : AppColors.green,
                    ),
                  ),
                if (ocupada)
                  Text(
                    'Ocupada',
                    style: GoogleFonts.outfit(
                      fontSize: 10,
                      color: AppColors.ink.withValues(alpha: 0.3),
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

class _SelectorPago extends StatelessWidget {
  final String seleccionado;
  final void Function(String) onChanged;

  const _SelectorPago(
      {required this.seleccionado, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final metodos = [
      ('yape', '💜', 'Yape'),
      ('plin', '💙', 'Plin'),
      ('tarjeta', '💳', 'Tarjeta'),
      ('efectivo', '💵', 'Efectivo'),
    ];

    return Row(
      children: metodos.map((m) {
        final (id, emoji, nombre) = m;
        final sel = seleccionado == id;
        return Expanded(
          child: GestureDetector(
            onTap: () => onChanged(id),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: sel ? AppColors.greenLight : AppColors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: sel ? AppColors.green : AppColors.line,
                  width: sel ? 1.5 : 1,
                ),
              ),
              child: Column(
                children: [
                  Text(emoji, style: const TextStyle(fontSize: 18)),
                  const SizedBox(height: 4),
                  Text(
                    nombre,
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      fontWeight: sel ? FontWeight.w600 : FontWeight.w400,
                      color: sel ? AppColors.green : AppColors.ink,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _BarraConfirmar extends StatelessWidget {
  final String? horaSeleccionada;
  final int duracion;
  final double precio;
  final VoidCallback? onConfirmar;

  const _BarraConfirmar({
    required this.horaSeleccionada,
    required this.duracion,
    required this.precio,
    required this.onConfirmar,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          16, 16, 16, MediaQuery.of(context).padding.bottom + 16),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: const Border(top: BorderSide(color: AppColors.line)),
        boxShadow: [
          BoxShadow(
            color: AppColors.ink.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          if (horaSeleccionada != null) ...[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    horaSeleccionada!,
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      color: AppColors.ink.withValues(alpha: 0.5),
                    ),
                  ),
                  Text(
                    PrecioUtils.formatear(precio),
                    style: GoogleFonts.bricolageGrotesque(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppColors.green,
                    ),
                  ),
                ],
              ),
            ),
          ],
          Expanded(
            flex: horaSeleccionada != null ? 2 : 1,
            child: ElevatedButton(
              onPressed: onConfirmar,
              style: ElevatedButton.styleFrom(
                backgroundColor: onConfirmar != null
                    ? AppColors.green
                    : AppColors.line,
              ),
              child: Text(
                onConfirmar != null
                    ? 'Confirmar reserva'
                    : 'Selecciona una hora',
                style: GoogleFonts.outfit(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
