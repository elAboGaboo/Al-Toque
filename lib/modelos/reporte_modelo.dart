import 'package:cloud_firestore/cloud_firestore.dart';

/// Reporte enviado por un usuario sobre otro usuario o contenido.
class ReporteModel {
  final String id;
  final String reportanteId;
  final String reportadoId;
  final String motivo;
  final String descripcion;
  final List<String> evidencia; // urls de imágenes/capturas
  final String estado;          // pendiente | revisando | resuelto
  final DateTime creadoEn;
  final DateTime? resueltoEn;
  final bool esDemo;

  const ReporteModel({
    required this.id,
    required this.reportanteId,
    required this.reportadoId,
    required this.motivo,
    this.descripcion = '',
    this.evidencia = const [],
    this.estado = 'pendiente',
    required this.creadoEn,
    this.resueltoEn,
    this.esDemo = false,
  });

  factory ReporteModel.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return ReporteModel(
      id: doc.id,
      reportanteId: d['reportanteId'] as String? ?? '',
      reportadoId: d['reportadoId'] as String? ?? '',
      motivo: d['motivo'] as String? ?? '',
      descripcion: d['descripcion'] as String? ?? '',
      evidencia: List<String>.from(d['evidencia'] as List? ?? []),
      estado: d['estado'] as String? ?? 'pendiente',
      creadoEn: (d['creadoEn'] as Timestamp?)?.toDate() ?? DateTime.now(),
      resueltoEn: (d['resueltoEn'] as Timestamp?)?.toDate(),
      esDemo: d['esDemo'] as bool? ?? false,
    );
  }

  factory ReporteModel.fromFirestore(DocumentSnapshot doc) =>
      ReporteModel.fromDoc(doc);

  Map<String, dynamic> toMap() => {
        'reportanteId': reportanteId,
        'reportadoId': reportadoId,
        'motivo': motivo,
        'descripcion': descripcion,
        'evidencia': evidencia,
        'estado': estado,
        'creadoEn': Timestamp.fromDate(creadoEn),
        if (resueltoEn != null) 'resueltoEn': Timestamp.fromDate(resueltoEn!),
        'esDemo': esDemo,
      };

  ReporteModel copyWith({String? estado, DateTime? resueltoEn}) => ReporteModel(
        id: id,
        reportanteId: reportanteId,
        reportadoId: reportadoId,
        motivo: motivo,
        descripcion: descripcion,
        evidencia: evidencia,
        estado: estado ?? this.estado,
        creadoEn: creadoEn,
        resueltoEn: resueltoEn ?? this.resueltoEn,
        esDemo: esDemo,
      );
}
