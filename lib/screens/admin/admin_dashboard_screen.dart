// screens/admin/admin_dashboard_screen.dart
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/precio_utils.dart';
import '../../providers/auth_provider.dart';
import '../../providers/flash_slots_provider.dart';
import '../../providers/partidos_provider.dart';
import '../../providers/reservas_provider.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final complejoId =
        ref.watch(complejoIdAdminProvider) ?? 'demo_complejo';
    final reservasAsync =
        ref.watch(reservasComplejoProvider(complejoId));
    final flashAsync =
        ref.watch(flashSlotsComplejoProvider(complejoId));
    final partidosAsync =
        ref.watch(partidosComplejoProvider(complejoId));
    final perfil = ref.watch(perfilUsuarioProvider).valueOrNull;

    return Theme(
      data: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: AppColors.adminBg,
      ),
      child: Scaffold(
        backgroundColor: AppColors.adminBg,
        body: CustomScrollView(
          slivers: [
            // Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Panel de control',
                            style: GoogleFonts.bricolageGrotesque(
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            perfil?.nombre ?? 'Administrador',
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              color: Colors.white.withValues(alpha: 0.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.adminS2,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.notifications_outlined,
                          color: Colors.white, size: 20),
                    ),
                  ],
                ),
              ),
            ),

            // KPIs
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: reservasAsync.when(
                  loading: () => const _KpiSkeleton(),
                  error: (_, __) => const SizedBox.shrink(),
                  data: (reservas) {
                    final hoy = DateTime.now();
                    final reservasHoy = reservas
                        .where((r) =>
                            r.fecha.day == hoy.day &&
                            r.fecha.month == hoy.month &&
                            r.fecha.year == hoy.year)
                        .toList();
                    final ingresos = reservas
                        .where((r) => r.estaConfirmada)
                        .fold(0.0, (s, r) => s + r.precioTotal);
                    final flash = flashAsync.valueOrNull ?? [];
                    final partidos = partidosAsync.valueOrNull ?? [];

                    return Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _KpiCard(
                                label: 'Reservas hoy',
                                valor: '${reservasHoy.length}',
                                icono: '📋',
                                color: AppColors.adminGreen,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _KpiCard(
                                label: 'Ingresos totales',
                                valor: PrecioUtils.formatear(ingresos),
                                icono: '💰',
                                color: AppColors.adminGreen,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _KpiCard(
                                label: 'Flash activos',
                                valor: '${flash.where((f) => f.isActivo).length}',
                                icono: '⚡',
                                color: AppColors.adminFlash,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _KpiCard(
                                label: 'Partidos abiertos',
                                valor:
                                    '${partidos.where((p) => p.estaAbierto).length}',
                                icono: '⚽',
                                color: AppColors.adminParty,
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),

            // Accesos rápidos
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Accesos rápidos',
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.5),
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: GridView.count(
                  crossAxisCount: 3,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  childAspectRatio: 1.1,
                  children: [
                    _AccesoRapido(
                      label: 'Horarios',
                      icono: Icons.calendar_month_rounded,
                      color: AppColors.adminGreen,
                      onTap: () => context.go('/admin/horarios'),
                    ),
                    _AccesoRapido(
                      label: 'Flash Slots',
                      icono: Icons.flash_on_rounded,
                      color: AppColors.adminFlash,
                      onTap: () => context.go('/admin/flash-slots'),
                    ),
                    _AccesoRapido(
                      label: 'Partidos',
                      icono: Icons.group_rounded,
                      color: AppColors.adminParty,
                      onTap: () => context.go('/admin/partidos'),
                    ),
                    _AccesoRapido(
                      label: 'IA',
                      icono: Icons.auto_awesome_rounded,
                      color: const Color(0xFFA78BFA),
                      onTap: () => context.go('/admin/ia'),
                    ),
                    _AccesoRapido(
                      label: 'Ingresos',
                      icono: Icons.bar_chart_rounded,
                      color: AppColors.adminGreen,
                      onTap: () => context.go('/admin/ingresos'),
                    ),
                    _AccesoRapido(
                      label: 'Cerrar sesión',
                      icono: Icons.logout_rounded,
                      color: AppColors.adminRed,
                      onTap: () async {
                        await ref
                            .read(authNotifierProvider.notifier)
                            .logout();
                        if (context.mounted) context.go('/login');
                      },
                    ),
                  ],
                ),
              ),
            ),

            // Gráfica de ingresos
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: _RevenueChart(
                  reservasAsync: reservasAsync,
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ),
      ),
    );
  }
}

// ── Widgets ──────────────────────────────────────────────────

class _KpiCard extends StatelessWidget {
  final String label;
  final String valor;
  final String icono;
  final Color color;

  const _KpiCard({
    required this.label,
    required this.valor,
    required this.icono,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.adminS1,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.adminS3),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(icono, style: const TextStyle(fontSize: 22)),
          const SizedBox(height: 8),
          Text(
            valor,
            style: GoogleFonts.bricolageGrotesque(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }
}

class _KpiSkeleton extends StatelessWidget {
  const _KpiSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _SkeletonCard()),
            const SizedBox(width: 12),
            Expanded(child: _SkeletonCard()),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _SkeletonCard()),
            const SizedBox(width: 12),
            Expanded(child: _SkeletonCard()),
          ],
        ),
      ],
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 90,
      decoration: BoxDecoration(
        color: AppColors.adminS1,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.adminS3),
      ),
    );
  }
}

class _AccesoRapido extends StatelessWidget {
  final String label;
  final IconData icono;
  final Color color;
  final VoidCallback onTap;

  const _AccesoRapido({
    required this.label,
    required this.icono,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.adminS1,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.adminS3),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icono, color: color, size: 22),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: Colors.white.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RevenueChart extends StatelessWidget {
  final AsyncValue reservasAsync;

  const _RevenueChart({required this.reservasAsync});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.adminS1,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.adminS3),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ingresos — últimos 7 días',
            style: GoogleFonts.outfit(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 160,
            child: reservasAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(
                    color: AppColors.adminGreen),
              ),
              error: (_, __) => const SizedBox.shrink(),
              data: (reservas) {
                // Agrupa por día de la semana
                final ahora = DateTime.now();
                final spots = <FlSpot>[];
                for (int i = 6; i >= 0; i--) {
                  final dia = ahora.subtract(Duration(days: i));
                  final ing = (reservas as List)
                      .where((r) =>
                          r.fecha.day == dia.day &&
                          r.fecha.month == dia.month &&
                          r.estaConfirmada)
                      .fold(0.0, (s, r) => s + r.precioTotal);
                  spots.add(FlSpot((6 - i).toDouble(), ing));
                }

                return LineChart(
                  LineChartData(
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      getDrawingHorizontalLine: (_) => const FlLine(
                        color: Color(0xFF1E293B),
                        strokeWidth: 1,
                      ),
                    ),
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 48,
                          getTitlesWidget: (v, _) => Text(
                            'S/${v.toInt()}',
                            style: GoogleFonts.outfit(
                              fontSize: 10,
                              color: Colors.white.withValues(alpha: 0.4),
                            ),
                          ),
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (v, _) {
                            final dias = [
                              'L', 'M', 'X', 'J', 'V', 'S', 'D'
                            ];
                            final day = ahora
                                .subtract(Duration(days: 6 - v.toInt()))
                                .weekday;
                            return Text(
                              dias[day - 1],
                              style: GoogleFonts.outfit(
                                fontSize: 11,
                                color: Colors.white.withValues(alpha: 0.4),
                              ),
                            );
                          },
                        ),
                      ),
                      topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                    ),
                    borderData: FlBorderData(show: false),
                    lineBarsData: [
                      LineChartBarData(
                        spots: spots,
                        isCurved: true,
                        color: AppColors.adminGreen,
                        barWidth: 2.5,
                        dotData: const FlDotData(show: false),
                        belowBarData: BarAreaData(
                          show: true,
                          color:
                              AppColors.adminGreen.withValues(alpha: 0.1),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
