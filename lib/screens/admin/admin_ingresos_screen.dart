// screens/admin/admin_ingresos_screen.dart
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/app_date_utils.dart';
import '../../core/utils/precio_utils.dart';
import '../../models/reserva_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/reservas_provider.dart';
import '../../widgets/common/error_widget.dart';

class AdminIngresosScreen extends ConsumerWidget {
  const AdminIngresosScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final complejoId = ref.watch(complejoIdAdminProvider) ?? 'demo';
    final reservasAsync = ref.watch(reservasComplejoProvider(complejoId));

    return Scaffold(
      backgroundColor: AppColors.adminBg,
      appBar: AppBar(
        backgroundColor: AppColors.adminS1,
        elevation: 0,
        title: Text('Ingresos',
            style: GoogleFonts.bricolageGrotesque(
                fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
      ),
      body: reservasAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.adminGreen)),
        error: (e, _) => AppErrorWidget(mensaje: 'Error cargando ingresos', onReintentar: () => ref.invalidate(reservasComplejoProvider(complejoId))),
        data: (reservas) => _buildContent(reservas),
      ),
    );
  }

  Widget _buildContent(List<ReservaModel> reservas) {
    final confirmadas = reservas.where((r) => r.estaConfirmada).toList();
    final total = confirmadas.fold(0.0, (s, r) => s + r.precioTotal);
    final hoy = DateTime.now();
    final hoyR = confirmadas.where((r) => r.fecha.day == hoy.day && r.fecha.month == hoy.month && r.fecha.year == hoy.year).toList();
    final totalHoy = hoyR.fold(0.0, (s, r) => s + r.precioTotal);

    // Datos por día (últimos 7)
    final spots = <FlSpot>[];
    for (int i = 6; i >= 0; i--) {
      final dia = hoy.subtract(Duration(days: i));
      final ing = confirmadas.where((r) => r.fecha.day == dia.day && r.fecha.month == dia.month).fold(0.0, (s, r) => s + r.precioTotal);
      spots.add(FlSpot((6 - i).toDouble(), ing));
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // KPIs
        Row(children: [
          Expanded(child: _KpiTile(label: 'Total acumulado', valor: PrecioUtils.formatear(total), color: AppColors.adminGreen, icono: '💰')),
          const SizedBox(width: 12),
          Expanded(child: _KpiTile(label: 'Hoy', valor: PrecioUtils.formatear(totalHoy), color: AppColors.adminFlash, icono: '📅')),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: _KpiTile(label: 'Reservas confirmadas', valor: '${confirmadas.length}', color: AppColors.adminParty, icono: '📋')),
          const SizedBox(width: 12),
          Expanded(child: _KpiTile(label: 'Ticket promedio', valor: confirmadas.isEmpty ? 'S/ 0' : PrecioUtils.formatear(total / confirmadas.length), color: AppColors.adminGreen, icono: '🎫')),
        ]),
        const SizedBox(height: 20),

        // Gráfica 7 días
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: AppColors.adminS1, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.adminS3)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Ingresos — últimos 7 días', style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
            const SizedBox(height: 20),
            SizedBox(height: 180, child: BarChart(BarChartData(
              backgroundColor: Colors.transparent,
              borderData: FlBorderData(show: false),
              gridData: FlGridData(drawVerticalLine: false, getDrawingHorizontalLine: (_) => const FlLine(color: Color(0xFF1E293B), strokeWidth: 1)),
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 52, getTitlesWidget: (v, _) => Text('S/${v.toInt()}', style: GoogleFonts.outfit(fontSize: 10, color: Colors.white38)))),
                bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (v, _) {
                  final d = hoy.subtract(Duration(days: 6 - v.toInt()));
                  final dias = ['L','M','X','J','V','S','D'];
                  return Text(dias[d.weekday - 1], style: GoogleFonts.outfit(fontSize: 11, color: Colors.white38));
                })),
              ),
              barGroups: spots.asMap().entries.map((e) => BarChartGroupData(x: e.key, barRods: [
                BarChartRodData(toY: e.value.y, color: AppColors.adminGreen, width: 24, borderRadius: BorderRadius.circular(6)),
              ])).toList(),
            ))),
          ]),
        ),
        const SizedBox(height: 20),

        // Lista de últimas reservas
        Text('Últimas reservas', style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white70)),
        const SizedBox(height: 10),
        ...confirmadas.take(10).map((r) => Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: AppColors.adminS1, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.adminS3)),
          child: Row(children: [
            Text(r.esFlash ? '⚡' : r.esPartido ? '⚽' : '📋', style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(AppDateUtils.fechaRelativa(r.fecha), style: GoogleFonts.outfit(fontSize: 13, color: Colors.white, fontWeight: FontWeight.w500)),
              Text('${r.horaInicio} – ${r.horaFin} · ${r.metodoPago}', style: GoogleFonts.outfit(fontSize: 11, color: Colors.white38)),
            ])),
            Text(PrecioUtils.formatear(r.precioTotal), style: GoogleFonts.bricolageGrotesque(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.adminGreen)),
          ]),
        )),
      ],
    );
  }
}

class _KpiTile extends StatelessWidget {
  final String label, valor, icono;
  final Color color;
  const _KpiTile({required this.label, required this.valor, required this.color, required this.icono});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: AppColors.adminS1, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.adminS3)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(icono, style: const TextStyle(fontSize: 20)),
      const SizedBox(height: 6),
      Text(valor, style: GoogleFonts.bricolageGrotesque(fontSize: 20, fontWeight: FontWeight.w800, color: color)),
      Text(label, style: GoogleFonts.outfit(fontSize: 11, color: Colors.white38)),
    ]),
  );
}
