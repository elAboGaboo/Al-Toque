// core/utils/date_utils.dart
import 'package:intl/intl.dart';

class AppDateUtils {
  AppDateUtils._();

  static final _dayNames = ['lu', 'ma', 'mi', 'ju', 'vi', 'sa', 'do'];
  static final _monthNames = [
    'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
    'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre',
  ];

  /// "sábado, 26 de abril"
  static String formatearFechaLarga(DateTime dt) {
    final dia = _diaSemana(dt.weekday);
    final mes = _monthNames[dt.month - 1];
    return '$dia, ${dt.day} de $mes';
  }

  /// "26/04/2026"
  static String formatearFechaCorta(DateTime dt) {
    return DateFormat('dd/MM/yyyy').format(dt);
  }

  /// "19:00"
  static String formatearHora(DateTime dt) {
    return DateFormat('HH:mm').format(dt);
  }

  /// Hoy como DateTime sin hora
  static DateTime hoy() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  /// "hoy", "mañana", o fecha corta
  static String fechaRelativa(DateTime dt) {
    final today = hoy();
    final target = DateTime(dt.year, dt.month, dt.day);
    final diff = target.difference(today).inDays;
    if (diff == 0) return 'Hoy';
    if (diff == 1) return 'Mañana';
    return formatearFechaLarga(dt);
  }

  /// Genera lista de slots de hora entre apertura y cierre.
  /// apertura: "07:00", cierre: "23:00", duracion: 1 (hora)
  static List<String> generarSlots({
    required String apertura,
    required String cierre,
    int duracionHoras = 1,
  }) {
    final inicio = _parseHora(apertura);
    final fin = _parseHora(cierre);
    final slots = <String>[];

    DateTime current = inicio;
    while (current.add(Duration(hours: duracionHoras)).compareTo(fin) <= 0) {
      slots.add(DateFormat('HH:mm').format(current));
      current = current.add(Duration(hours: duracionHoras));
    }
    return slots;
  }

  /// Clave para predicción IA: "lu_7", "vi_19"
  static String claveHeatmap(DateTime dt, String hora) {
    final dia = _dayNames[dt.weekday - 1];
    final h = int.parse(hora.split(':').first);
    return '${dia}_$h';
  }

  static DateTime _parseHora(String hora) {
    final parts = hora.split(':');
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day,
        int.parse(parts[0]), int.parse(parts[1]));
  }

  static String _diaSemana(int weekday) {
    const dias = [
      'lunes', 'martes', 'miércoles', 'jueves', 'viernes', 'sábado', 'domingo'
    ];
    return dias[weekday - 1];
  }
}
