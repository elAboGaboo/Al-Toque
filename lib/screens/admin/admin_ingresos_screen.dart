// screens/admin/admin_ingresos_screen.dart
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_colors.dart';

class AdminIngresosScreen extends ConsumerWidget {
  const AdminIngresosScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.abg,
      appBar: AppBar(
        backgroundColor: AppColors.abg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: AppColors.atx),
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Main KPI ─────────────────────────────
            const _MainRevenueCard(),

            const SizedBox(height: 24),

            // ── Secondary KPIs ───────────────────────
            const Row(
              children: [
                Expanded(child: _SmallKpi(label: 'Ticket Med.', val: 'S/ 48.50', color: AppColors.aacc)),
                SizedBox(width: 12),
                Expanded(child: _SmallKpi(label: 'Tasa Cancel.', val: '2.4%', color: AppColors.red)),
              ],
            ),

            const SizedBox(height: 32),

            // ── Chart ───────────────────────────────
            Text(
              'Rendimiento Semanal',
              style: GoogleFonts.bricolageGrotesque(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.atx,
              ),
            ),
            const SizedBox(height: 16),
            const _RevenueBarChart(),

            const SizedBox(height: 32),

            // ── Recent Transactions ──────────────────
            Text(
              'Transacciones Recientes',
              style: GoogleFonts.bricolageGrotesque(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.atx,
              ),
            ),
            const SizedBox(height: 16),
            const _TransactionItem(user: 'Juan D.', date: 'Hoy, 18:24', amount: 'S/ 40.00', method: 'Yape'),
            const _TransactionItem(user: 'Maria P.', date: 'Hoy, 17:10', amount: 'S/ 60.00', method: 'Plin'),
            const _TransactionItem(user: 'Carlos R.', date: 'Hoy, 15:05', amount: 'S/ 40.00', method: 'Efectivo'),
          ],
        ),
      ),
    );
  }
}

class _MainRevenueCard extends StatelessWidget {
  const _MainRevenueCard();

  @override
  Widget build(BuildContext context) {
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
          BoxShadow(color: AppColors.aacc.withValues(alpha: 0.3), blurRadius: 24, offset: const Offset(0, 8)),
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
            'S/ 8,420.00',
            style: GoogleFonts.bricolageGrotesque(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.trending_up_rounded, size: 16, color: Colors.black),
              const SizedBox(width: 4),
              Text(
                '+14% vs mes anterior',
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

class _SmallKpi extends StatelessWidget {
  final String label;
  final String val;
  final Color color;
  const _SmallKpi({required this.label, required this.val, required this.color});

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
          Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColors.atx3)),
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

class _RevenueBarChart extends StatelessWidget {
  const _RevenueBarChart();

  @override
  Widget build(BuildContext context) {
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
          maxY: 1000,
          barTouchData: BarTouchData(enabled: false),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (v, _) => Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(['L', 'M', 'M', 'J', 'V', 'S', 'D'][v.toInt() % 7],
                      style: GoogleFonts.plusJakartaSans(fontSize: 10, color: AppColors.atx3)),
                ),
              ),
            ),
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          barGroups: List.generate(7, (i) {
            return BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: [400, 600, 450, 800, 950, 1000, 850][i].toDouble(),
                  color: AppColors.aacc,
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

class _TransactionItem extends StatelessWidget {
  final String user;
  final String date;
  final String amount;
  final String method;
  const _TransactionItem({required this.user, required this.date, required this.amount, required this.method});

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
            decoration: BoxDecoration(color: AppColors.asur2, borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.payment_rounded, size: 18, color: AppColors.aacc),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user,
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.atx)),
                Text('$date · $method', style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColors.atx3)),
              ],
            ),
          ),
          Text(
            amount,
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
