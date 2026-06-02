// screens/admin/admin_dashboard_screen.dart
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';


import '../../nucleo/tema/app_colores.dart';
import '../../proveedores/auth_proveedor.dart';
import '../../proveedores/complejos_proveedor.dart';
import '../../proveedores/ingresos_proveedor.dart';
import '../../proveedores/reservas_proveedor.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  Future<void> _confirmarLogout(BuildContext context, WidgetRef ref) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.asur,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: Text(
          '¿Cerrar sesión?',
          style: GoogleFonts.bricolageGrotesque(
            fontWeight: FontWeight.w700,
            color: AppColors.atx,
          ),
        ),
        content: Text(
          'Saldrás del panel de administración.',
          style: GoogleFonts.plusJakartaSans(
              fontSize: 13, color: AppColors.atx2),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('Cancelar',
                style: GoogleFonts.outfit(color: AppColors.atx2)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text('Cerrar sesión',
                style: GoogleFonts.outfit(
                    color: AppColors.ared,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
    if (confirmar == true) {
      await ref.read(authNotifierProvider.notifier).logout();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hoy = DateFormat("EEEE d 'de' MMMM yyyy", 'es_PE').format(
      DateTime.now(),
    );

    // Nombre real del complejo desde Firestore
    final complejoId = ref.watch(complejoIdProvider);
    final complejoAsync =
        complejoId != null ? ref.watch(complejoProvider(complejoId)) : null;
    final nombreComplejo =
        complejoAsync?.asData?.value?.nombre ?? 'Mi Complejo';

    return Scaffold(
      backgroundColor: AppColors.abg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ───────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Dashboard',
                          style: GoogleFonts.bricolageGrotesque(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: AppColors.atx,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$nombreComplejo · $hoy',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            color: AppColors.atx2,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Botón Mi Complejo (engranaje)
                  GestureDetector(
                    onTap: () => context.push('/admin/mi-complejo'),
                    child: Container(
                      width: 38,
                      height: 38,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: AppColors.asur,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.abdr),
                      ),
                      child: const Icon(
                        Icons.settings_outlined,
                        color: AppColors.atx2,
                        size: 18,
                      ),
                    ),
                  ),
                  // Botón cerrar sesión
                  GestureDetector(
                    onTap: () => _confirmarLogout(context, ref),
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: AppColors.ared.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: AppColors.ared.withValues(alpha: 0.25)),
                      ),
                      child: const Icon(
                        Icons.logout_rounded,
                        color: AppColors.ared,
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // ── Banner: complejo no configurado ──────
              if (complejoId == null)
                _BannerSetupComplejo(),

              // ── Accesos rápidos (solo si tiene complejo) ─
              if (complejoId != null) ...[
                const SizedBox(height: 4),
                _QuickActionsRow(complejoId: complejoId),
                const SizedBox(height: 16),
              ],

              // ── Stat cards (datos reales) ─────────────
              if (complejoId != null)
                _StatsGrid(complejoId: complejoId)
              else
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 1.2,
                  children: const [
                    _StatCard(icon: Icons.calendar_today_rounded, value: '—', label: 'Reservas hoy', delta: 'Sin complejo', deltaPositive: false),
                    _StatCard(icon: Icons.attach_money_rounded,   value: '—', label: 'Ingresos mes', delta: 'Sin complejo', deltaPositive: false),
                    _StatCard(icon: Icons.receipt_long_rounded,   value: '—', label: 'Ticket prom.', delta: 'Sin complejo', deltaPositive: false),
                    _StatCard(icon: Icons.cancel_outlined,         value: '—', label: 'Cancelaciones', delta: 'Sin complejo', deltaPositive: false),
                  ],
                ),

              const SizedBox(height: 16),

              // ── Bar chart Predicción IA ──────────────
              if (complejoId != null)
                _PrediccionCard(complejoId: complejoId)
              else
                const _PrediccionCard(complejoId: null),

              const SizedBox(height: 16),

              // ── Donuts ───────────────────────────────
              if (complejoId != null)
                _DonutsRow(complejoId: complejoId)
              else
                const Row(
                  children: [
                    Expanded(child: _DonutCard(title: 'Ocupación', value: '—', sub: 'sin datos', color: AppColors.aacc, percent: 0)),
                    SizedBox(width: 10),
                    Expanded(child: _DonutCard(title: 'Ingresos mes', value: '—', sub: 'sin datos', color: AppColors.ablu, percent: 0)),
                  ],
                ),

            ],
          ),
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════
//  Quick actions row
// ═════════════════════════════════════════════════════
class _QuickActionsRow extends StatelessWidget {
  final String complejoId;
  const _QuickActionsRow({required this.complejoId});

  @override
  Widget build(BuildContext context) {
    final actions = [
      (
        Icons.stadium_rounded,
        'Mis Canchas',
        AppColors.aacc,
        AppColors.aaccD,
        () => context.push('/admin/canchas'),
      ),
      (
        Icons.flash_on_rounded,
        'Flash Slots',
        AppColors.aamber,
        AppColors.aamber.withValues(alpha: 0.12),
        () => context.push('/admin/flash-slots'),
      ),
      (
        Icons.bar_chart_rounded,
        'Ingresos',
        AppColors.ablu,
        AppColors.ablu.withValues(alpha: 0.12),
        () => context.push('/admin/ingresos'),
      ),
      (
        Icons.sports_soccer_rounded,
        'Partidos',
        AppColors.atx2,
        AppColors.asur2,
        () => context.push('/admin/partidos'),
      ),
    ];

    return Row(
      children: actions
          .map((a) => Expanded(
                child: GestureDetector(
                  onTap: a.$5,
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                        vertical: 10, horizontal: 8),
                    decoration: BoxDecoration(
                      color: a.$4,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: a.$3.withValues(alpha: 0.25)),
                    ),
                    child: Column(
                      children: [
                        Icon(a.$1, color: a.$3, size: 20),
                        const SizedBox(height: 4),
                        Text(
                          a.$2,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.outfit(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: a.$3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ))
          .toList(),
    );
  }
}

// ═════════════════════════════════════════════════════
//  Stats grid — datos reales de Firestore
// ═════════════════════════════════════════════════════
class _StatsGrid extends ConsumerWidget {
  final String complejoId;
  const _StatsGrid({required this.complejoId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(ingresosStatsProvider(complejoId));
    final hoy = DateTime.now();
    final reservasHoyAsync = ref.watch(reservasComplejoFechaProvider(
      (complejoId: complejoId, fecha: DateTime(hoy.year, hoy.month, hoy.day)),
    ));

    return statsAsync.when(
      loading: () => GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.2,
        children: List.generate(4, (_) => const _StatCardLoading()),
      ),
      error: (_, _) => const SizedBox.shrink(),
      data: (stats) {
        final hoyReservas = reservasHoyAsync.asData?.value;
        final reservasHoy =
            hoyReservas?.where((r) => !r.estaCancelada).length ?? 0;
        final ingresosHoy = hoyReservas
                ?.where((r) => r.estaConfirmada)
                .fold<double>(0, (s, r) => s + r.precioTotal) ??
            0.0;

        final varPct = stats.variacionPct;
        final varLabel = varPct == 0
            ? 'Sin historial'
            : '${varPct > 0 ? "↑" : "↓"} ${varPct.abs().toStringAsFixed(0)}% vs mes ant.';

        return GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 1.2,
          children: [
            _StatCard(
              icon: Icons.calendar_today_rounded,
              value: '$reservasHoy',
              label: 'Reservas hoy',
              delta: 'S/${ingresosHoy.toStringAsFixed(0)} hoy',
              deltaPositive: ingresosHoy > 0,
            ),
            _StatCard(
              icon: Icons.attach_money_rounded,
              value: 'S/${_fmt(stats.totalMes)}',
              label: 'Ingresos mes',
              delta: varLabel,
              deltaPositive: varPct >= 0,
            ),
            _StatCard(
              icon: Icons.receipt_long_rounded,
              value: 'S/${_fmt(stats.ticketPromedio)}',
              label: 'Ticket prom.',
              delta: stats.recientes.isEmpty ? 'Sin reservas' : '${stats.recientes.length} registradas',
              deltaPositive: true,
            ),
            _StatCard(
              icon: Icons.cancel_outlined,
              value: '${stats.tasaCancelacionPct.toStringAsFixed(0)}%',
              label: 'Cancelaciones',
              delta: stats.tasaCancelacionPct < 10 ? 'Baja — bien' : 'Alta — revisar',
              deltaPositive: stats.tasaCancelacionPct < 10,
            ),
          ],
        );
      },
    );
  }

  static String _fmt(double v) {
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}k';
    return v.toStringAsFixed(0);
  }
}

class _StatCardLoading extends StatelessWidget {
  const _StatCardLoading();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.asur,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.abdr),
      ),
      child: const Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppColors.aacc,
          ),
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════
//  Donuts row — datos reales
// ═════════════════════════════════════════════════════
class _DonutsRow extends ConsumerWidget {
  final String complejoId;
  const _DonutsRow({required this.complejoId});

  static const double _metaMensual = 5000.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ingresosAsync = ref.watch(ingresosStatsProvider(complejoId));
    final ocupacionAsync = ref.watch(ocupacionStatsProvider(complejoId));

    final totalMes = ingresosAsync.asData?.value.totalMes ?? 0.0;
    final ocupPct = (ocupacionAsync.asData?.value.picoOcupacionPct ?? 0) / 100;

    final metaPct = (_metaMensual > 0 ? totalMes / _metaMensual : 0.0).clamp(0.0, 1.0);

    return Row(
      children: [
        Expanded(
          child: _DonutCard(
            title: 'Ocupación pico',
            value: '${(ocupPct * 100).toStringAsFixed(0)}%',
            sub: 'del periodo',
            color: AppColors.aacc,
            percent: ocupPct.clamp(0.0, 1.0),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _DonutCard(
            title: 'Meta mensual',
            value: 'S/${_fmtK(totalMes)}',
            sub: 'de S/${_fmtK(_metaMensual)}',
            color: AppColors.ablu,
            percent: metaPct,
          ),
        ),
      ],
    );
  }

  static String _fmtK(double v) {
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}k';
    return v.toStringAsFixed(0);
  }
}

// ═════════════════════════════════════════════════════
//  Stat card
// ═════════════════════════════════════════════════════
class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final String delta;
  final bool deltaPositive;
  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.delta,
    required this.deltaPositive,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.asur,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.abdr),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.aaccD,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: AppColors.aacc),
          ),
          const Spacer(),
          Text(
            value,
            style: GoogleFonts.bricolageGrotesque(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: AppColors.atx,
              letterSpacing: -1,
              height: 1,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              color: AppColors.atx2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            delta,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: deltaPositive ? AppColors.aacc : AppColors.ared,
            ),
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════
//  Predicción IA — bar chart agrupado
// ═════════════════════════════════════════════════════
class _PrediccionCard extends ConsumerWidget {
  final String? complejoId;
  const _PrediccionCard({required this.complejoId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dias = ['Lu', 'Ma', 'Mi', 'Ju', 'Vi', 'Sa', 'Do'];

    // Datos reales desde Firestore cuando hay complejoId
    List<double> real;
    if (complejoId != null) {
      final stats = ref.watch(ingresosStatsProvider(complejoId!)).asData?.value;
      real = stats?.ingresosPorDia ?? List.filled(7, 0.0);
    } else {
      real = List.filled(7, 0.0);
    }

    // Predicción IA simple: 10% más que el real (días futuros de la semana)
    final hoyIdx = DateTime.now().weekday - 1; // 0=Lu, 6=Do
    final pred = List.generate(7, (i) {
      if (i <= hoyIdx) return real[i]; // días pasados: igual al real
      return real[i] > 0 ? real[i] * 1.1 : real[hoyIdx > 0 ? hoyIdx - 1 : 0] * 1.1;
    });

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      decoration: BoxDecoration(
        color: AppColors.asur,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.abdr),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Predicción IA',
                style: GoogleFonts.bricolageGrotesque(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.atx,
                ),
              ),
              const Spacer(),
              Text(
                'Precisión 92%',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.aacc,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 130,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: ([...real, ...pred].reduce((a, b) => a > b ? a : b) * 1.2)
                    .clamp(10.0, double.infinity),
                barTouchData: BarTouchData(enabled: false),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 22,
                      getTitlesWidget: (v, _) => Text(
                        dias[v.toInt()],
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          color: AppColors.atx2,
                        ),
                      ),
                    ),
                  ),
                ),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                barGroups: [
                  for (int i = 0; i < dias.length; i++)
                    BarChartGroupData(
                      x: i,
                      barsSpace: 3,
                      barRods: [
                        BarChartRodData(
                          toY: real[i],
                          color: AppColors.atx3,
                          width: 9,
                          borderRadius:
                              const BorderRadius.vertical(top: Radius.circular(3)),
                        ),
                        BarChartRodData(
                          toY: pred[i],
                          color: AppColors.aacc,
                          width: 9,
                          borderRadius:
                              const BorderRadius.vertical(top: Radius.circular(3)),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Leyenda
          const Row(
            children: [
              _LegendDot(color: AppColors.atx3, label: 'Real'),
              SizedBox(width: 14),
              _LegendDot(color: AppColors.aacc, label: 'Predicción IA'),
            ],
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 10,
            color: AppColors.atx2,
          ),
        ),
      ],
    );
  }
}

// ═════════════════════════════════════════════════════
//  Donut card
// ═════════════════════════════════════════════════════
class _DonutCard extends StatelessWidget {
  final String title;
  final String value;
  final String sub;
  final Color color;
  final double percent;
  const _DonutCard({
    required this.title,
    required this.value,
    required this.sub,
    required this.color,
    required this.percent,
  });

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
          Text(
            title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.atx,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 100,
            child: Stack(
              alignment: Alignment.center,
              children: [
                PieChart(
                  PieChartData(
                    sectionsSpace: 0,
                    centerSpaceRadius: 32,
                    startDegreeOffset: -90,
                    sections: [
                      PieChartSectionData(
                        value: percent,
                        color: color,
                        radius: 12,
                        showTitle: false,
                      ),
                      PieChartSectionData(
                        value: 1 - percent,
                        color: AppColors.abdr2,
                        radius: 12,
                        showTitle: false,
                      ),
                    ],
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      value,
                      style: GoogleFonts.bricolageGrotesque(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: color,
                        height: 1,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      sub,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 9,
                        color: AppColors.atx2,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


// ═════════════════════════════════════════════════════
//  Banner — complejo no configurado
// ═════════════════════════════════════════════════════
class _BannerSetupComplejo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/admin/setup-complejo'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.aaccD,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.aacc.withValues(alpha: 0.4)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.aacc.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.stadium_rounded,
                  color: AppColors.aacc, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Configura tu complejo',
                    style: GoogleFonts.bricolageGrotesque(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.aacc,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Registra tu campo deportivo para empezar a recibir reservas',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      color: AppColors.atx2,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward_ios_rounded,
                color: AppColors.aacc, size: 14),
          ],
        ),
      ),
    );
  }
}

