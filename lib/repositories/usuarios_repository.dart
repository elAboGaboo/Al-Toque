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

  /// Actualiza únicamente el FCM token.
  Future<void> actualizarFcmToken(String uid, String token) async {
    await _db.doc(FirestorePaths.usuarioDoc(uid)).update({
      'fcmToken': token,
    });
  }

  /// Actualiza la última ubicación conocida del usuario.
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

  /// Incrementa el contador de reservas y total gastado.
  Future<void> registrarReserva({
    required String uid,
    required double monto,
  }) async {
    await _db.doc(FirestorePaths.usuarioDoc(uid)).update({
      'totalReservas': FieldValue.increment(1),
      'totalGastado': FieldValue.increment(monto),
    });
  }

  /// Crea un perfil inicial al registrarse.
  Future<void> crearPerfil({
    required String uid,
    required String nombre,
    required String email,
    String rol = 'jugador',
    String? complejoId,
  }) async {
    final ahora = DateTime.now();
    await _db.doc(FirestorePaths.usuarioDoc(uid)).set({
      'nombre': nombre,
      'email': email,
      'telefono': '',
      'avatarUrl': '',
      'rol': rol,
      if (complejoId != null) 'complejoId': complejoId,
      'deporteFavorito': 'futbol5',
      'totalReservas': 0,
      'totalGastado': 0.0,
      'fcmToken': '',
      'creadoEn': Timestamp.fromDate(ahora),
    }, SetOptions(merge: true));
  }
}
