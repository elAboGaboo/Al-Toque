// screens/admin/admin_ia_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_colors.dart';

class AdminIAScreen extends ConsumerWidget {
  const AdminIAScreen({super.key});

  // Heatmap: 5 horas × 7 días. Valor 0..1 = intensidad de demanda.
  static const _heatmap = <List<double>>[
    [0.55, 0.65, 0.20, 0.70, 0.85, 0.75, 0.50], // 10am
    [0.60, 0.70, 0.25, 0.78, 0.90, 0.80, 0.55], // 1pm
    [0.70, 0.75, 0.45, 0.82, 0.92, 0.88, 0.65], // 4pm
    [0.85, 0.90, 0.75, 0.92, 1.00, 0.95, 0.80], // 7pm — pico
    [0.65, 0.70, 0.50, 0.75, 0.85, 0.78, 0.55], // 10pm
  ];

  static const _horas = ['10am', '1pm', '4pm', '7pm', '10pm'];
  static const _dias = ['Lu', 'Ma', 'Mi', 'Ju', 'Vi', 'Sa', 'Do'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                'Demanda esperada por día y hora',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: AppColors.atx2,
                ),
              ),
              const SizedBox(height: 16),

              const _HeatmapCard(heatmap: _heatmap, horas: _horas, dias: _dias),

              const SizedBox(height: 16),

              _Card(
                child: Column(
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
                    const _InsightItem(
                      icon: Icons.auto_graph_rounded,
                      iconColor: AppColors.aacc,
                      title: 'Pico: Viernes 7pm · 95%',
                      description:
                          'Precio dinámico recomendado. Potencial +S/180 semanales.',
                      tagText: 'Alta confianza 94%',
                      tagColor: AppColors.aacc,
                    ),
                    const _InsightDivider(),
                    const _InsightItem(
                      icon: Icons.warning_amber_rounded,
                      iconColor: AppColors.aamber,
                      title: 'Valle: Miércoles 10am-1pm',
                      description:
                          '22% ocupación esperada. Descuentos automáticos sugeridos.',
                      tagText: 'Oportunidad',
                      tagColor: AppColors.aamber,
                    ),
                    const _InsightDivider(),
                    const _InsightItem(
                      icon: Icons.trending_up_rounded,
                      iconColor: AppColors.ablu,
                      title: 'Tendencia semanal +31%',
                      description:
                          'IA detecta temporada de campeonatos escolares.',
                      tagText: 'Confirmado',
                      tagColor: AppColors.ablu,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

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
                      label: 'Entrenamiento',
                      valueWidget: Text(
                        '18 meses · 24k registros',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: AppColors.atx,
                          fontWeight: FontWeight.w600,
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
                          if (col < dias.length - 1) const SizedBox(width: 4),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 6),
          Row(
            children: [
              const SizedBox(width: 40),
              Text(
                'Bajo',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 9,
                  color: AppColors.atx3,
                ),
              ),
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
              Text(
                'Alto',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 9,
                  color: AppColors.atx3,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

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
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
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
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: AppColors.atx2,
            ),
          ),
        ),
        valueWidget,
      ],
    );
  }
}
