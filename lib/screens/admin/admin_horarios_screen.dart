// screens/admin/admin_horarios_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/app_date_utils.dart';
import '../../models/cancha_model.dart';
import '../../models/reserva_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/complejos_provider.dart';
import '../../providers/reservas_provider.dart';
import '../../widgets/common/error_widget.dart';
import '../../widgets/common/loading_skeleton.dart';

class AdminHorariosScreen extends ConsumerStatefulWidget {
  const AdminHorariosScreen({super.key});

  @override
  ConsumerState<AdminHorariosScreen> createState() =>
      _AdminHorariosScreenState();
}

class _AdminHorariosScreenState
    extends ConsumerState<AdminHorariosScreen> {
  DateTime _fecha = DateTime.now();

  final _horas = List.generate(
    16,
    (i) => '${(i + 7).toString().padLeft(2, '0')}:00',
  );

  @override
  Widget build(BuildContext context) {
    final complejoId =
        ref.watch(complejoIdAdminProvider) ?? 'demo_complejo';
    final canchasAsync = ref.watch(canchasProvider(complejoId));
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
            color: Colors.white,
          ),
        ),
        actions: [
          // Selector de fecha
          TextButton.icon(
            onPressed: _seleccionarFecha,
            icon: const Icon(Icons.calendar_today_rounded,
                color: AppColors.adminGreen, size: 18),
            label: Text(
              AppDateUtils.fechaRelativa(_fecha),
              style: GoogleFonts.outfit(
                color: AppColors.adminGreen,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: canchasAsync.when(
        loading: () =>
            const Center(child: HorarioGridSkeleton()),
        error: (e, _) => AppErrorWidget(
          mensaje: 'Error cargando canchas',
          onReintentar: () =>
              ref.invalidate(canchasProvider(complejoId)),
        ),
        data: (canchas) {
          if (canchas.isEmpty) {
            return Center(
              child: Text(
                'No hay canchas configuradas',
                style: GoogleFonts.outfit(color: Colors.white54),
              ),
            );
          }
          return reservasAsync.when(
            loading: () => const Center(
                child: CircularProgressIndicator(
                    color: AppColors.adminGreen)),
            error: (_, __) => const SizedBox.shrink(),
            data: (reservas) => _buildGrid(canchas, reservas),
          );
        },
      ),
    );
  }

  Widget _buildGrid(
      List<CanchaModel> canchas, List<ReservaModel> reservas) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Leyenda
              const Row(
                children: [
                  _LegendChip(
                      color: AppColors.slotFree, label: 'Disponible'),
                  SizedBox(width: 12),
                  _LegendChip(
                      color: AppColors.slotBooked, label: 'Ocupada'),
                  SizedBox(width: 12),
                  _LegendChip(
                      color: AppColors.slotFlash, label: 'Flash'),
                  SizedBox(width: 12),
                  _LegendChip(
                      color: AppColors.slotParty, label: 'Partido'),
                ],
              ),
              const SizedBox(height: 16),

              // Header canchas
              Row(
                children: [
                  const SizedBox(width: 52), // espacio para horas
                  ...canchas.map((c) => Container(
                        width: 88,
                        margin: const EdgeInsets.only(right: 4),
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.adminS2,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          children: [
                            Text(
                              c.deporteEmoji,
                              style: const TextStyle(fontSize: 16),
                            ),
                            Text(
                              c.nombre,
                              style: GoogleFonts.outfit(
                                fontSize: 11,
                                color: Colors.white.withValues(alpha: 0.7),
                                fontWeight: FontWeight.w500,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )),
                ],
              ),
              const SizedBox(height: 4),

              // Grid horas x canchas
              ..._horas.map((hora) {
                return Row(
                  children: [
                    // Hora
                    SizedBox(
                      width: 52,
                      child: Text(
                        hora,
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          color: Colors.white.withValues(alpha: 0.4),
                        ),
                      ),
                    ),
                    // Celdas por cancha
                    ...canchas.map((cancha) {
                      final reserva = reservas
                          .where((r) =>
                              r.canchaId == cancha.id &&
                              r.horaInicio == hora)
                          .firstOrNull;

                      Color color;
                      String label;
                      if (reserva == null) {
                        color = AppColors.slotFree;
                        label = 'Libre';
                      } else if (reserva.esFlash) {
                        color = AppColors.slotFlash;
                        label = 'Flash';
                      } else if (reserva.esPartido) {
                        color = AppColors.slotParty;
                        label = 'Partido';
                      } else {
                        color = AppColors.slotBooked;
                        label = 'Reservada';
                      }

                      return Container(
                        width: 88,
                        height: 44,
                        margin: const EdgeInsets.fromLTRB(0, 2, 4, 2),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                          border:
                              Border.all(color: color.withValues(alpha: 0.4)),
                        ),
                        child: Center(
                          child: Text(
                            label,
                            style: GoogleFonts.outfit(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: color,
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _seleccionarFecha() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _fecha,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null) setState(() => _fecha = picked);
  }
}

class _LegendChip extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendChip({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 11,
            color: Colors.white.withValues(alpha: 0.5),
          ),
        ),
      ],
    );
  }
}
