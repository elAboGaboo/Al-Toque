// screens/admin/admin_ingresos_screen.dart
import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../models/reserva_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/ingresos_provider.dart';

class AdminIngresosScreen extends ConsumerWidget {
  const AdminIngresosScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final complejoId = ref.watch(complejoIdProvider) ?? '';
    final statsAsync = ref.watch(ingresosStatsProvider(complejoId));

    return Scaffold(
      backgroundColor: AppColors.abg,
      appBar: AppBar(
        backgroundColor: AppColors.abg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              size: 18, color: AppColors.atx),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Finanzas & Ingresos',
          style: GoogleFonts.bricolageGrotesque(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.atx,
          ),
        ),
      ),
      body: statsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.aacc),
        ),
        error: (e, _) => Center(
          child: Text('Error cargando datos: $e',
              style: GoogleFonts.outfit(color: AppColors.ared)),
        ),
        data: (stats) => _IngresosBody(stats: stats),
      ),
    );
  }
}

// ── Cuerpo principal ──────────────────────────────────────────────────────────

class _IngresosBody extends StatelessWidget {
  final IngresosStats stats;
  const _IngresosBody({required this.stats});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── KPI principal ────────────────────────
          _MainRevenueCard(stats: stats),

          const SizedBox(height: 24),

          // ── KPIs secundarios ─────────────────────
          Row(
            children: [
              Expanded(
                child: _SmallKpi(
                  label: 'Ticket Prom.',
                  val: 'S/ ${stats.ticketPromedio.toStringAsFixed(2)}',
                  color: AppColors.aacc,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SmallKpi(
                  label: 'Tasa Cancel.',
                  val: '${stats.tasaCancelacionPct.toStringAsFixed(1)}%',
                  color: AppColors.red,
                ),
              ),
            ],
          ),

          const SizedBox(height: 32),

          // ── Gráfico semanal ───────────────────────
          Text(
            'Rendimiento Semanal',
            style: GoogleFonts.bricolageGrotesque(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.atx,
            ),
          ),
          const SizedBox(height: 16),
          _RevenueBarChart(datos: stats.ingresosPorDia),

          const SizedBox(height: 32),

          // ── Transacciones recientes ───────────────
          Text(
            'Transacciones Recientes',
            style: GoogleFonts.bricolageGrotesque(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.atx,
            ),
          ),
          const SizedBox(height: 16),

          if (stats.recientes.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  'Sin reservas aún',
                  style:
                      GoogleFonts.outfit(fontSize: 14, color: AppColors.atx3),
                ),
              ),
            )
          else
            ...stats.recientes.map((r) => _TransactionItem(reserva: r)),
        ],
      ),
    );
  }
}

// ── KPI principal ─────────────────────────────────────────────────────────────

class _MainRevenueCard extends StatelessWidget {
  final IngresosStats stats;
  const _MainRevenueCard({required this.stats});

  @override
  Widget build(BuildContext context) {
    final variacion = stats.variacionPct;
    final subiendo = variacion >= 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF00E87A), Color(0xFF00C466)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
              color: AppColors.aacc.withValues(alpha: 0.3),
              blurRadius: 24,
              offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ingresos del Mes',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.black.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'S/ ${NumberFormat('#,##0.00', 'es').format(stats.totalMes)}',
            style: GoogleFonts.bricolageGrotesque(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                subiendo
                    ? Icons.trending_up_rounded
                    : Icons.trending_down_rounded,
                size: 16,
                color: Colors.black,
              ),
              const SizedBox(width: 4),
              Text(
                stats.totalMesAnterior == 0
                    ? 'Primer mes de datos'
                    : '${subiendo ? '+' : ''}${variacion.toStringAsFixed(1)}% vs mes anterior',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.black.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── KPI secundario ────────────────────────────────────────────────────────────

class _SmallKpi extends StatelessWidget {
  final String label;
  final String val;
  final Color color;
  const _SmallKpi(
      {required this.label, required this.val, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.asur,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.asur3),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style:
                  GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColors.atx3)),
          const SizedBox(height: 4),
          Text(
            val,
            style: GoogleFonts.bricolageGrotesque(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Gráfico de barras semanal ─────────────────────────────────────────────────

class _RevenueBarChart extends StatelessWidget {
  final List<double> datos;
  const _RevenueBarChart({required this.datos});

  @override
  Widget build(BuildContext context) {
    final maxVal = datos.fold<double>(0, max);
    final maxY = maxVal == 0 ? 100.0 : (maxVal * 1.3).ceilToDouble();

    return Container(
      height: 200,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.asur,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.asur3),
      ),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxY,
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (_, _, rod, _) => BarTooltipItem(
                'S/ ${rod.toY.toStringAsFixed(0)}',
                GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600),
              ),
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (v, _) => Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    ['L', 'M', 'M', 'J', 'V', 'S', 'D'][v.toInt() % 7],
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 10, color: AppColors.atx3),
                  ),
                ),
              ),
            ),
            leftTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          barGroups: List.generate(7, (i) {
            return BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: datos[i],
                  color: datos[i] == maxVal && maxVal > 0
                      ? AppColors.aacc
                      : AppColors.aacc.withValues(alpha: 0.45),
                  width: 14,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }
}

// ── Ítem de transacción ───────────────────────────────────────────────────────

class _TransactionItem extends StatelessWidget {
  final ReservaModel reserva;
  const _TransactionItem({required this.reserva});

  String get _metodoLabel {
    return switch (reserva.metodoPago) {
      'yape' => '💜 Yape',
      'plin' => '💙 Plin',
      'efectivo' => '💵 Efectivo',
      'tarjeta' => '💳 Tarjeta',
      'transferencia' => '🏦 Transferencia',
      _ => reserva.metodoPago,
    };
  }

  String get _fechaLabel {
    final now = DateTime.now();
    final hoy = DateTime(now.year, now.month, now.day);
    final ayer = hoy.subtract(const Duration(days: 1));
    final dia =
        DateTime(reserva.creadoEn.year, reserva.creadoEn.month, reserva.creadoEn.day);
    final hora =
        '${reserva.creadoEn.hour.toString().padLeft(2, '0')}:${reserva.creadoEn.minute.toString().padLeft(2, '0')}';
    if (dia == hoy) return 'Hoy, $hora';
    if (dia == ayer) return 'Ayer, $hora';
    return '${reserva.creadoEn.day}/${reserva.creadoEn.month}, $hora';
  }

  String get _idCorto =>
      reserva.id.length >= 6 ? '#${reserva.id.substring(0, 6).toUpperCase()}' : '#—';

  Color get _estadoColor {
    if (reserva.estaConfirmada) return AppColors.aacc;
    if (reserva.estaCancelada) return AppColors.ared;
    return AppColors.aamber;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.asur,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.asur3),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
                color: AppColors.asur2,
                borderRadius: BorderRadius.circular(12)),
            child: Icon(Icons.payment_rounded, size: 18, color: _estadoColor),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Reserva $_idCorto',
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.atx),
                ),
                Text(
                  '$_fechaLabel · $_metodoLabel',
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 11, color: AppColors.atx3),
                ),
              ],
            ),
          ),
          Text(
            'S/ ${reserva.precioTotal.toStringAsFixed(2)}',
            style: GoogleFonts.bricolageGrotesque(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.atx,
            ),
          ),
        ],
      ),
    );
  }
}
