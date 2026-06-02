// core/utils/precio_utils.dart
import '../../modelos/prediccion_ia_modelo.dart';

class PrecioUtils {
  PrecioUtils._();

  /// Calcula el precio dinámico según la predicción IA para la hora dada.
  static double calcularPrecio({
    required double precioBase,
    required String horaSlot, // "19:00"
    List<PrecioDinamicoSlot>? predicciones,
    double precioTechoMax = double.infinity,
  }) {
    if (predicciones == null || predicciones.isEmpty) return precioBase;

    final pred = predicciones
        .where((p) => p.horaInicio == horaSlot)
        .firstOrNull;

    if (pred == null) return precioBase;

    final precio = (precioBase * pred.multiplicador);
    return precio.clamp(precioBase, precioTechoMax).roundToDouble();
  }

  /// Formatea precio en soles peruanos: "S/ 80"
  static String formatear(double precio) {
    return 'S/ ${precio.toStringAsFixed(0)}';
  }

  /// Formatea precio con decimales: "S/ 80.50"
  static String formatearConDecimales(double precio) {
    return 'S/ ${precio.toStringAsFixed(2)}';
  }

  /// Calcula el porcentaje de descuento entre precio original y flash.
  static int calcularDescuento(double original, double flash) {
    if (original <= 0) return 0;
    return (((original - flash) / original) * 100).round();
  }

  /// Retorna label de demanda según multiplicador.
  static String labelDemanda(double multiplicador) {
    if (multiplicador >= 1.3) return 'Alta demanda';
    if (multiplicador >= 1.1) return 'Demanda media';
    return 'Baja demanda';
  }
}
