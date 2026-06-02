// models/prediccion_ia_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

enum DemandaNivel {
  baja,
  media,
  alta;

  String get label => switch (this) {
        DemandaNivel.baja => 'Baja demanda',
        DemandaNivel.media => 'Demanda media',
        DemandaNivel.alta => 'Alta demanda',
      };

  String get emoji => switch (this) {
        DemandaNivel.baja => '🟢',
        DemandaNivel.media => '🟡',
        DemandaNivel.alta => '🔴',
      };
}

class PrecioDinamicoSlot {
  final String horaInicio;
  final double multiplicador;
  final double precioSugerido;

  const PrecioDinamicoSlot({
    required this.horaInicio,
    required this.multiplicador,
    required this.precioSugerido,
  });

  factory PrecioDinamicoSlot.fromMap(Map<String, dynamic> m) =>
      PrecioDinamicoSlot(
        horaInicio: m['horaInicio'] as String? ?? '00:00',
        multiplicador: (m['multiplicador'] as num?)?.toDouble() ?? 1.0,
        precioSugerido: (m['precioSugerido'] as num?)?.toDouble() ?? 0,
      );

  Map<String, dynamic> toMap() => {
        'horaInicio': horaInicio,
        'multiplicador': multiplicador,
        'precioSugerido': precioSugerido,
      };
}

// Alias para compatibilidad con precio_utils.dart
typedef PrecioDinamico = PrecioDinamicoSlot;

class PrediccionIAModel {
  final String id;
  final String complejoId;
  final String semana;
  final double precision;
  final Map<String, double> heatmap;
  final List<PrecioDinamicoSlot> preciosDinamicos;
  final DateTime generadoEn;

  const PrediccionIAModel({
    required this.id,
    required this.complejoId,
    required this.semana,
    required this.precision,
    required this.heatmap,
    required this.preciosDinamicos,
    required this.generadoEn,
  });

  factory PrediccionIAModel.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    final heatRaw = d['heatmap'] as Map<String, dynamic>? ?? {};
    final preciosRaw = d['preciosDinamicos'] as List? ?? [];
    return PrediccionIAModel(
      id: doc.id,
      complejoId: d['complejoId'] as String? ?? '',
      semana: d['semana'] as String? ?? '',
      precision: (d['precision'] as num?)?.toDouble() ?? 0,
      heatmap: heatRaw.map((k, v) => MapEntry(k, (v as num).toDouble())),
      preciosDinamicos: preciosRaw
          .map((e) => PrecioDinamicoSlot.fromMap(e as Map<String, dynamic>))
          .toList(),
      generadoEn: (d['generadoEn'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  factory PrediccionIAModel.fromFirestore(DocumentSnapshot doc) =>
      PrediccionIAModel.fromDoc(doc);

  /// Retorna el multiplicador para la hora dada ("19:00").
  double multiplicadorParaHora(String hora) {
    final slot = preciosDinamicos
        .where((p) => p.horaInicio == hora)
        .firstOrNull;
    return slot?.multiplicador ?? 1.0;
  }

  /// Nivel de demanda actual según la hora del sistema.
  DemandaNivel nivelDemandaActual() {
    final hora = '${DateTime.now().hour.toString().padLeft(2, '0')}:00';
    final multiplicador = multiplicadorParaHora(hora);
    if (multiplicador >= 1.3) return DemandaNivel.alta;
    if (multiplicador >= 1.1) return DemandaNivel.media;
    return DemandaNivel.baja;
  }
}
