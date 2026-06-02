// repositories/usuarios_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';

import '../nucleo/constantes/firestore_rutas.dart';
import '../modelos/usuario_modelo.dart';

class UsuariosRepository {
  final _db = FirebaseFirestore.instance;

  /// Obtiene el perfil de un usuario (one-shot).
  Future<UsuarioModel?> getUsuario(String uid) async {
    final doc = await _db.doc(FirestorePaths.usuarioDoc(uid)).get();
    if (!doc.exists) return null;
    return UsuarioModel.fromFirestore(doc);
  }

  /// Stream del perfil del usuario en tiempo real.
  Stream<UsuarioModel?> streamUsuario(String uid) {
    return _db
        .doc(FirestorePaths.usuarioDoc(uid))
        .snapshots()
        .map((s) => s.exists ? UsuarioModel.fromFirestore(s) : null);
  }

  /// Crea o actualiza el perfil del usuario.
  Future<void> guardarUsuario(UsuarioModel usuario) async {
    await _db.doc(FirestorePaths.usuarioDoc(usuario.id)).set(
          usuario.toMap(),
          SetOptions(merge: true),
        );
  }

  /// Actualiza la ubicación del usuario dueño.
  Future<void> actualizarUbicacion({
    required String uid,
    required double lat,
    required double lng,
  }) async {
    await _db.doc(FirestorePaths.usuarioDoc(uid)).update({
      'ubicacionLat': lat,
      'ubicacionLng': lng,
    });
  }

  /// Vincula el complejoId al perfil del dueño después del setup inicial.
  Future<void> actualizarComplejoId(String uid, String complejoId) async {
    await _db.doc(FirestorePaths.usuarioDoc(uid)).set({
      'complejoId': complejoId,
    }, SetOptions(merge: true));
  }

  /// Crea el perfil mínimo al registrarse.
  /// Solo campos esenciales para el router y la app.
  /// El resto (telefono, genero, dni, avatarUrl…) se puede actualizar
  /// desde la pantalla de perfil cuando el usuario lo necesite.
  Future<void> crearPerfil({
    required String uid,
    required String nombre,
    required String email,
    required String rol, // 'jugador' | 'dueno'
  }) async {
    await _db.doc(FirestorePaths.usuarioDoc(uid)).set({
      'nombre':     nombre,
      'email':      email,
      'rol':        rol,
      'complejoId': null,
      'creadoEn':   FieldValue.serverTimestamp(),
    });
    // Nota: sin SetOptions.merge para asegurar escritura limpia.
    // Campos opcionales (telefono, genero, dni…) se agregan después.
  }
}
