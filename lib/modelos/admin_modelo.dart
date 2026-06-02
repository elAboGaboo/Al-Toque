import 'package:cloud_firestore/cloud_firestore.dart';

/// Administrador del sistema (panel interno / moderación).
class AdminModel {
  final String id;
  final String nombre;
  final String email;
  final String rolAdmin;        // super_admin | moderador
  final List<String> permisos;
  final bool activo;
  final DateTime creadoEn;
  final DateTime? ultimoAcceso;

  const AdminModel({
    required this.id,
    required this.nombre,
    required this.email,
    this.rolAdmin = 'moderador',
    this.permisos = const [],
    this.activo = true,
    required this.creadoEn,
    this.ultimoAcceso,
  });

  bool get esSuperAdmin => rolAdmin == 'super_admin';

  factory AdminModel.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return AdminModel(
      id: doc.id,
      nombre: d['nombre'] as String? ?? '',
      email: d['email'] as String? ?? '',
      rolAdmin: d['rolAdmin'] as String? ?? 'moderador',
      permisos: List<String>.from(d['permisos'] as List? ?? []),
      activo: d['activo'] as bool? ?? true,
      creadoEn: (d['creadoEn'] as Timestamp?)?.toDate() ?? DateTime.now(),
      ultimoAcceso: (d['ultimoAcceso'] as Timestamp?)?.toDate(),
    );
  }

  factory AdminModel.fromFirestore(DocumentSnapshot doc) =>
      AdminModel.fromDoc(doc);

  Map<String, dynamic> toMap() => {
        'nombre': nombre,
        'email': email,
        'rolAdmin': rolAdmin,
        'permisos': permisos,
        'activo': activo,
        'creadoEn': Timestamp.fromDate(creadoEn),
        if (ultimoAcceso != null) 'ultimoAcceso': Timestamp.fromDate(ultimoAcceso!),
      };
}
