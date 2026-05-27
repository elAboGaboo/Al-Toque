// providers/auth_provider.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/usuario_model.dart';
import '../repositories/usuarios_repository.dart';

final _auth = FirebaseAuth.instance;

/// Stream del usuario Firebase Auth actual.
final authStateProvider = StreamProvider<User?>((ref) {
  try {
    return _auth.authStateChanges();
  } catch (_) {
    return const Stream.empty();
  }
});

/// Repositorio de usuarios.
final usuariosRepositoryProvider = Provider<UsuariosRepository>(
  (_) => UsuariosRepository(),
);

/// Perfil Firestore del usuario autenticado.
final perfilUsuarioProvider = StreamProvider<UsuarioModel?>((ref) {
  final authState = ref.watch(authStateProvider);
  final uid = authState.asData?.value?.uid;
  if (uid == null) return const Stream.empty();
  return ref.watch(usuariosRepositoryProvider).streamUsuario(uid);
});

/// UID del usuario actual (acceso rápido).
final uidProvider = Provider<String?>((ref) {
  return ref.watch(authStateProvider).asData?.value?.uid;
});

/// True si el usuario es dueño de un complejo.
final esDuenoProvider = Provider<bool>((ref) {
  return ref.watch(perfilUsuarioProvider).asData?.value?.esDueno ?? false;
});

/// complejoId del dueño logueado (null si es jugador).
final complejoIdProvider = Provider<String?>((ref) {
  return ref.watch(perfilUsuarioProvider).asData?.value?.complejoId;
});

// ── Notifier para operaciones de auth ─────────────────────────

class AuthNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  /// Login con email y contraseña.
  Future<void> login({required String email, required String password}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    });
  }

  /// Registro de nuevo usuario.
  Future<String?> registrar({
    required String nombre,
    required String email,
    required String password,
    String rol = 'jugador',
    String dni = '',
  }) async {
    state = const AsyncLoading();
    String? uid;
    state = await AsyncValue.guard(() async {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      uid = cred.user!.uid;
      try {
        await ref.read(usuariosRepositoryProvider).crearPerfil(
              uid: uid!,
              nombre: nombre,
              email: email.trim(),
              rol: rol,
              dni: dni,
            );
      } catch (_) {
        await cred.user!.delete();
        rethrow;
      }
    });
    return uid;
  }

  /// Cierra sesión.
  Future<void> logout() async {
    await _auth.signOut();
  }

  /// Enviar email de reseteo de contraseña.
  Future<void> resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email.trim());
  }
}

final authNotifierProvider =
    AsyncNotifierProvider<AuthNotifier, void>(AuthNotifier.new);
