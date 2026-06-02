// providers/ingresos_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../modelos/reserva_modelo.dart';
import 'reservas_proveedor.dart';

// ── Modelos de estadísticas ───────────────────────────────────────────────────

/// Estadísticas financieras derivadas de las reservas del complejo.
class IngresosStats {
  final double totalMes;
  final double totalMesAnterior;
  final double ticketPromedio;
  final double tasaCancelacionPct;

  /// Ingresos confirmados por día de la semana actual [Lu..Do].
  final List<double> ingresosPorDia;

  /// Últimas 10 reservas (sin importar estado) ordenadas por creadoEn desc.
  final List<ReservaModel> recientes;

  const IngresosStats({
    required this.totalMes,
    required this.totalMesAnterior,
    required this.ticketPromedio,
    required this.tasaCancelacionPct,
    required this.ingresosPorDia,
    required this.recientes,
  });

  /// Variación porcentual vs mes anterior (positivo = crecimiento).
  double get variacionPct {
    if (totalMesAnterior == 0) return 0;
    return ((totalMes - totalMesAnterior) / totalMesAnterior) * 100;
  }

  static IngresosStats empty() => const IngresosStats(
        totalMes: 0,
        totalMesAnterior: 0,
        ticketPromedio: 0,
        tasaCancelacionPct: 0,
        ingresosPorDia: [0, 0, 0, 0, 0, 0, 0],
        recientes: [],
      );
}

/// Mapa de ocupación por (franja_horaria × día_semana) normalizado 0..1.
/// Filas: 5 franjas — ['10am','1pm','4pm','7pm','10pm'].
/// Columnas: 7 días — [Lu, Ma, Mi, Ju, Vi, Sa, Do].
class OcupacionStats {
  final List<List<double>> heatmap;
  final String picoDia;
  final String picoHora;
  final double picoOcupacionPct; // 0..100
  final String valleDia;
  final String valleHora;
  final int totalReservas;

  const OcupacionStats({
    required this.heatmap,
    required this.picoDia,
    required this.picoHora,
    required this.picoOcupacionPct,
    required this.valleDia,
    required this.valleHora,
    required this.totalReservas,
  });

  static OcupacionStats empty() => OcupacionStats(
        heatmap: List.generate(5, (_) => List.filled(7, 0.0)),
        picoDia: '—',
        picoHora: '—',
        picoOcupacionPct: 0,
        valleDia: '—',
        valleHora: '—',
        totalReservas: 0,
      );
}

// ── Providers ─────────────────────────────────────────────────────────────────

final ingresosStatsProvider =
    StreamProvider.family<IngresosStats, String>((ref, complejoId) {
  return ref
      .watch(reservasRepositoryProvider)
      .streamReservasComplejo(complejoId)
      .map(_calcularIngresos);
});

final ocupacionStatsProvider =
    StreamProvider.family<OcupacionStats, String>((ref, complejoId) {
  return ref
      .watch(reservasRepositoryProvider)
      .streamReservasComplejo(complejoId)
      .map(_calcularOcupacion);
});

// ── Cálculos internos ─────────────────────────────────────────────────────────

IngresosStats _calcularIngresos(List<ReservaModel> todas) {
  final now = DateTime.now();
  final inicioMes = DateTime(now.year, now.month, 1);
  final inicioMesAnterior = now.month == 1
      ? DateTime(now.year - 1, 12, 1)
      : DateTime(now.year, now.month - 1, 1);
  final finMesAnterior = inicioMes.subtract(const Duration(seconds: 1));

  // Lunes de la semana actual
  final lunesSemana = now.subtract(Duration(days: now.weekday - 1));

  final delMes =
      todas.where((r) => !r.fecha.isBefore(inicioMes)).toList();
  final delMesAnterior = todas
      .where((r) =>
          !r.fecha.isBefore(inicioMesAnterior) &&
          !r.fecha.isAfter(finMesAnterior))
      .toList();

  final confirmadas = delMes.where((r) => r.estaConfirmada).toList();
  final canceladas = delMes.where((r) => r.estaCancelada).toList();

  final totalMes =
      confirmadas.fold<double>(0, (s, r) => s + r.precioTotal);
  final totalMesAnterior = delMesAnterior
      .where((r) => r.estaConfirmada)
      .fold<double>(0, (s, r) => s + r.precioTotal);
  final ticketPromedio =
      confirmadas.isEmpty ? 0.0 : totalMes / confirmadas.length;
  final tasaCancelacion =
      delMes.isEmpty ? 0.0 : (canceladas.length / delMes.length) * 100;

  // Ingresos por día de la semana actual [Lu..Do]
  final ingresosDia = List.filled(7, 0.0);
  for (final r in confirmadas) {
    for (int i = 0; i < 7; i++) {
      final dia = lunesSemana.add(Duration(days: i));
      if (r.fecha.year == dia.year &&
          r.fecha.month == dia.month &&
          r.fecha.day == dia.day) {
        ingresosDia[i] += r.precioTotal;
        break;
      }
    }
  }

  // Últimas 10 reservas (ya vienen ordenadas desc por creadoEn del repo)
  final recientes = todas.take(10).toList();

  return IngresosStats(
    totalMes: totalMes,
    totalMesAnterior: totalMesAnterior,
    ticketPromedio: ticketPromedio,
    tasaCancelacionPct: tasaCancelacion,
    ingresosPorDia: ingresosDia,
    recientes: recientes,
  );
}

OcupacionStats _calcularOcupacion(List<ReservaModel> todas) {
  // Franjas horarias: [inicio_hora_incl, fin_hora_incl]
  const franjas = [
    [7, 9],   // 10am
    [10, 13], // 1pm
    [14, 16], // 4pm
    [17, 20], // 7pm
    [21, 23], // 10pm
  ];
  const franjaLabels = ['10am', '1pm', '4pm', '7pm', '10pm'];
  const diaLabels = [
    'Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'
  ];

  // count[franja][dia_semana 0..6]
  final counts = List.generate(5, (_) => List.filled(7, 0));
  int total = 0;

  for (final r in todas) {
    if (r.estaCancelada) continue;
    total++;
    final hora = int.tryParse(r.horaInicio.split(':')[0]) ?? 0;
    final dia = r.fecha.weekday - 1; // 0=Lunes, 6=Domingo
    for (int f = 0; f < franjas.length; f++) {
      if (hora >= franjas[f][0] && hora <= franjas[f][1]) {
        counts[f][dia]++;
        break;
      }
    }
  }

  // Valor máximo para normalizar (mínimo 1 para evitar /0)
  int maxCount = 1;
  for (final row in counts) {
    for (final c in row) {
      if (c > maxCount) maxCount = c;
    }
  }

  final heatmap = List.generate(
    5,
    (f) => List.generate(7, (d) => counts[f][d] / maxCount),
  );

  // Encontrar pico y valle
  int picoF = 0, picoD = 0, valleF = 0, valleD = 0;
  int picoV = 0, valleV = maxCount;
  for (int f = 0; f < 5; f++) {
    for (int d = 0; d < 7; d++) {
      if (counts[f][d] > picoV) {
        picoV = counts[f][d];
        picoF = f;
        picoD = d;
      }
      if (counts[f][d] < valleV) {
        valleV = counts[f][d];
        valleF = f;
        valleD = d;
      }
    }
  }

  return OcupacionStats(
    heatmap: heatmap,
    picoDia: diaLabels[picoD],
    picoHora: franjaLabels[picoF],
    picoOcupacionPct: (picoV / maxCount) * 100,
    valleDia: diaLabels[valleD],
    valleHora: franjaLabels[valleF],
    totalReservas: total,
  );
}
