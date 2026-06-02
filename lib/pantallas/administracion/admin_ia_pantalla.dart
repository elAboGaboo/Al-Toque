// screens/admin/admin_ia_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../nucleo/tema/app_colores.dart';
import '../../proveedores/auth_proveedor.dart';
import '../../proveedores/ingresos_proveedor.dart';

class AdminIAScreen extends ConsumerWidget {
  const AdminIAScreen({super.key});

  static const _franjaLabels = ['10am', '1pm', '4pm', '7pm', '10pm'];
  static const _diaLabels = ['Lu', 'Ma', 'Mi', 'Ju', 'Vi', 'Sa', 'Do'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final complejoId = ref.watch(complejoIdProvider) ?? '';
    final statsAsync = ref.watch(ocupacionStatsProvider(complejoId));

    return Scaffold(
      backgroundColor: AppColors.abg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Predicción IA',
                style: GoogleFonts.bricolageGrotesque(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppColors.atx,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Demanda real por día y franja horaria',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: AppColors.atx2,
                ),
              ),
              const SizedBox(height: 16),

              // ── Heatmap ───────────────────────────────
              statsAsync.when(
                loading: () => const SizedBox(
                  height: 160,
                  child: Center(
                      child: CircularProgressIndicator(color: AppColors.aacc)),
                ),
                error: (e, _) => _Card(
                  child: Text('Error cargando datos: $e',
                      style: GoogleFonts.outfit(color: AppColors.ared)),
                ),
                data: (stats) => _HeatmapCard(
                  heatmap: stats.heatmap,
                  horas: _franjaLabels,
                  dias: _diaLabels,
                ),
              ),

              const SizedBox(height: 16),

              // ── Insights dinámicos ────────────────────
              _Card(
                child: statsAsync.when(
                  loading: () => const Center(
                      child: CircularProgressIndicator(color: AppColors.aacc)),
                  error: (_, _) => const SizedBox.shrink(),
                  data: (stats) => _InsightsSection(stats: stats),
                ),
              ),

              const SizedBox(height: 16),

              // ── Parámetros (estáticos — describen el modelo conceptual) ──
              _Card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Parámetros del modelo',
                      style: GoogleFonts.bricolageGrotesque(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.atx,
                      ),
                    ),
                    const SizedBox(height: 14),
                    _ParamRow(
                      label: 'Algoritmo',
                      valueWidget: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.aaccD,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'LSTM + Random Forest',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.aacc,
                          ),
                        ),
                      ),
                    ),
                    const _InsightDivider(),
                    _ParamRow(
                      label: 'Variables',
                      valueWidget: Text(
                        'Clima · día · feriados',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: AppColors.atx,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const _InsightDivider(),
                    _ParamRow(
                      label: 'Fuente de datos',
                      valueWidget: Text(
                        'Reservas históricas · Firestore',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: AppColors.atx,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Sección de insights dinámicos ─────────────────────────────────────────────

class _InsightsSection extends StatelessWidget {
  final OcupacionStats stats;
  const _InsightsSection({required this.stats});

  @override
  Widget build(BuildContext context) {
    if (stats.totalReservas == 0) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text(
          'Sin datos suficientes para generar insights.\nCuando haya reservas registradas aparecerán aquí.',
          style: GoogleFonts.outfit(
              fontSize: 13, color: AppColors.atx2, height: 1.5),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Insights del modelo',
          style: GoogleFonts.bricolageGrotesque(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.atx,
          ),
        ),
        const SizedBox(height: 12),

        // Pico
        _InsightItem(
          icon: Icons.auto_graph_rounded,
          iconColor: AppColors.aacc,
          title: 'Pico: ${stats.picoDia} ${stats.picoHora} · '
              '${stats.picoOcupacionPct.toInt()}% relativo',
          description:
              'Franja de mayor demanda histórica. Considera precio dinámico en este horario.',
          tagText: 'Alta demanda',
          tagColor: AppColors.aacc,
        ),
        const _InsightDivider(),

        // Valle
        _InsightItem(
          icon: Icons.warning_amber_rounded,
          iconColor: AppColors.aamber,
          title: 'Valle: ${stats.valleDia} ${stats.valleHora}',
          description:
              'Franja con menor ocupación. Flash Slots con descuento automático pueden ayudar.',
          tagText: 'Oportunidad',
          tagColor: AppColors.aamber,
        ),
        const _InsightDivider(),

        // Total
        _InsightItem(
          icon: Icons.bar_chart_rounded,
          iconColor: AppColors.ablu,
          title: '${stats.totalReservas} reservas analizadas',
          description:
              'El mapa de calor se actualiza en tiempo real con cada nueva reserva.',
          tagText: 'Datos en vivo',
          tagColor: AppColors.ablu,
        ),
      ],
    );
  }
}

// ── Heatmap ───────────────────────────────────────────────────────────────────

class _HeatmapCard extends StatelessWidget {
  final List<List<double>> heatmap;
  final List<String> horas;
  final List<String> dias;
  const _HeatmapCard({
    required this.heatmap,
    required this.horas,
    required this.dias,
  });

  Color _colorForValue(double v) {
    if (v < 0.3) return const Color(0xFF1A3A28);
    if (v < 0.5) return const Color(0xFF1F5236);
    if (v < 0.7) return const Color(0xFF2A7A4D);
    if (v < 0.85) return const Color(0xFF22A864);
    return AppColors.aacc;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: BoxDecoration(
        color: AppColors.asur,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.abdr),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cabecera días
          Padding(
            padding: const EdgeInsets.only(left: 40, bottom: 6),
            child: Row(
              children: dias
                  .map((d) => Expanded(
                        child: Center(
                          child: Text(d,
                              style: GoogleFonts.plusJakartaSans(
                                  fontSize: 9, color: AppColors.atx3)),
                        ),
                      ))
                  .toList(),
            ),
          ),
          // Filas
          ...List.generate(horas.length, (row) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 5),
              child: Row(
                children: [
                  SizedBox(
                    width: 32,
                    child: Text(
                      horas[row],
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        color: AppColors.atx3,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Row(
                      children: [
                        for (int col = 0; col < dias.length; col++) ...[
                          Expanded(
                            child: AspectRatio(
                              aspectRatio: 1,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: _colorForValue(heatmap[row][col]),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ),
                          ),
                          if (col < dias.length - 1)
                            const SizedBox(width: 4),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),

          const SizedBox(height: 6),

          // Leyenda
          Row(
            children: [
              const SizedBox(width: 40),
              Text('Bajo',
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 9, color: AppColors.atx3)),
              const SizedBox(width: 6),
              ...[
                const Color(0xFF1A3A28),
                const Color(0xFF1F5236),
                const Color(0xFF2A7A4D),
                const Color(0xFF22A864),
                AppColors.aacc,
              ].map(
                (c) => Container(
                  width: 14,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 1),
                  decoration: BoxDecoration(
                    color: c,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Text('Alto',
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 9, color: AppColors.atx3)),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Sub-widgets reutilizados ──────────────────────────────────────────────────

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.asur,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.abdr),
      ),
      child: child,
    );
  }
}

class _InsightItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String description;
  final String tagText;
  final Color tagColor;

  const _InsightItem({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.description,
    required this.tagText,
    required this.tagColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: iconColor, size: 16),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.atx,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                description,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  color: AppColors.atx2,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: tagColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Text(
                  tagText,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: tagColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _InsightDivider extends StatelessWidget {
  const _InsightDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1,
      margin: const EdgeInsets.symmetric(vertical: 12),
      color: AppColors.abdr2,
    );
  }
}

class _ParamRow extends StatelessWidget {
  final String label;
  final Widget valueWidget;
  const _ParamRow({required this.label, required this.valueWidget});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style:
                GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.atx2),
          ),
        ),
        valueWidget,
      ],
    );
  }
}
