// repositorios/admins_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';

import '../nucleo/constantes/firestore_rutas.dart';
import '../modelos/admin_modelo.dart';

class AdminsRepository {
  final _db = FirebaseFirestore.instance;

  /// Devuelve el admin con ese uid, o null si no lo es.
  Future<AdminModel?> getAdmin(String uid) async {
    final doc = await _db.doc(FirestorePaths.adminDoc(uid)).get();
    return doc.exists ? AdminModel.fromFirestore(doc) : null;
  }

  /// True si el uid corresponde a un admin activo.
  Future<bool> esAdmin(String uid) async {
    final admin = await getAdmin(uid);
    return admin != null && admin.activo;
  }

  /// Lista de administradores activos.
  Stream<List<AdminModel>> streamAdmins() {
    return _db
        .collection(FirestorePaths.admins)
        .where('activo', isEqualTo: true)
        .snapshots()
        .map((s) => s.docs.map(AdminModel.fromFirestore).toList());
  }

  /// Registra el acceso del admin.
  Future<void> registrarAcceso(String uid) async {
    await _db
        .doc(FirestorePaths.adminDoc(uid))
        .set({'ultimoAcceso': FieldValue.serverTimestamp()},
            SetOptions(merge: true));
  }
}
