// repositories/usuarios_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/constants/firestore_paths.dart';
import '../models/usuario_model.dart';

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

  /// Crea un perfil inicial al registrarse — solo los campos del modelo.
  Future<void> crearPerfil({
    required String uid,
    required String nombre,
    required String email,
    String rol = 'jugador',
    String dni = '',
    String? complejoId,
  }) async {
    final iniciales = nombre
        .trim()
        .split(' ')
        .where((w) => w.isNotEmpty)
        .take(2)
        .map((w) => w[0].toUpperCase())
        .join();

    await _db.doc(FirestorePaths.usuarioDoc(uid)).set({
      'nombre':        nombre,
      'iniciales':     iniciales,
      'email':         email,
      'telefono':      '',
      'dni':           dni,
      'avatarUrl':     '',
      'rol':           rol,
      'complejoId':    complejoId,
      'numeroCanchas': 0,
      'creadoEn':      FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
