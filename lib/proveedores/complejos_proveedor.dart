// providers/complejos_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../modelos/cancha_modelo.dart';
import '../modelos/complejo_modelo.dart';
import '../repositorios/complejos_repositorio.dart';
import 'auth_proveedor.dart';

final complejosRepositoryProvider = Provider<ComplejosRepository>(
  (_) => ComplejosRepository(),
);

/// One-shot fetch de complejos activos con timeout de 8 s.
/// Úsalo en InicioScreen para evitar loading infinito si Firestore no responde.
final complejosFutureProvider = FutureProvider<List<ComplejoModel>>((ref) {
  return ref.watch(complejosRepositoryProvider).getComplejos();
});

/// Stream de todos los complejos activos (tiempo real).
/// Úsalo en MapaScreen u otras vistas que necesiten actualizaciones live.
final complejosProvider = StreamProvider<List<ComplejoModel>>((ref) {
  return ref.watch(complejosRepositoryProvider).streamComplejos();
});

/// Stream de un complejo específico.
final complejoProvider =
    StreamProvider.family<ComplejoModel?, String>((ref, complejoId) {
  return ref.watch(complejosRepositoryProvider).streamComplejo(complejoId);
});

/// Stream de canchas de un complejo (tiempo real).
final canchasProvider =
    StreamProvider.family<List<CanchaModel>, String>((ref, complejoId) {
  return ref.watch(complejosRepositoryProvider).streamCanchas(complejoId);
});

/// One-shot fetch de canchas — usa .get() en lugar de .snapshots().
/// Resuelve inmediatamente o lanza error explícito (nunca queda colgado).
final canchasFutureProvider =
    FutureProvider.family<List<CanchaModel>, String>((ref, complejoId) {
  return ref.watch(complejosRepositoryProvider).getCanchas(complejoId);
});

/// Complejo seleccionado en el mapa (para bottom sheet detalle).
class ComplejoSeleccionadoNotifier extends Notifier<ComplejoModel?> {
  @override
  ComplejoModel? build() => null;

  /// Llama esto ANTES de navegar a /complejo/:id para que la pantalla de
  /// detalle muestre el header inmediatamente sin llamada extra a Firestore.
  void select(ComplejoModel? complejo) => state = complejo;
}

final complejoSeleccionadoProvider =
    NotifierProvider<ComplejoSeleccionadoNotifier, ComplejoModel?>(
  ComplejoSeleccionadoNotifier.new,
);


/// Cancha seleccionada (para flujo de reserva).
class CanchaSeleccionadaNotifier extends Notifier<CanchaModel?> {
  @override
  CanchaModel? build() => null;

  /// Llama esto ANTES de navegar a /reservar/:complejoId/:canchaId para que
  /// ReservarScreen muestre la info al instante sin request extra a Firestore.
  void select(CanchaModel? cancha) => state = cancha;
}

final canchaSeleccionadaProvider =
    NotifierProvider<CanchaSeleccionadaNotifier, CanchaModel?>(
  CanchaSeleccionadaNotifier.new,
);

/// One-shot: obtener un complejo por ID.
final complejoFutureProvider =
    FutureProvider.family<ComplejoModel?, String>((ref, complejoId) {
  return ref.watch(complejosRepositoryProvider).getComplejo(complejoId);
});

/// One-shot robusto para el detalle del jugador.
/// Si `canchasActivas` falta en el doc raíz, intenta recuperarlas desde la
/// subcolección una sola vez y repara el documento.
final complejoDetalleJugadorProvider =
    FutureProvider.family<ComplejoModel?, String>((ref, complejoId) {
  return ref
      .watch(complejosRepositoryProvider)
      .getComplejoParaDetalleJugador(complejoId);
});

/// One-shot: obtener una cancha por IDs.
final canchaFutureProvider =
    FutureProvider.family<CanchaModel?, ({String complejoId, String canchaId})>(
        (ref, ids) {
  return ref
      .watch(complejosRepositoryProvider)
      .getCancha(ids.complejoId, ids.canchaId);
});

/// Stream admin de canchas — incluye activas E inactivas.
final canchasAdminProvider =
    StreamProvider.family<List<CanchaModel>, String>((ref, complejoId) {
  return ref
      .watch(complejosRepositoryProvider)
      .streamCanchasAdmin(complejoId);
});

/// Stream del complejo del dueño logueado (uno solo).
final misComplejosProvider = StreamProvider<List<ComplejoModel>>((ref) {
  final perfil = ref.watch(perfilUsuarioProvider);
  final complejoId = perfil.asData?.value?.complejoId;

  if (complejoId == null || complejoId.isEmpty) {
    return Stream.value([]);
  }

  return ref
      .watch(complejosRepositoryProvider)
      .streamComplejo(complejoId)
      .map((c) => c != null ? [c] : <ComplejoModel>[]);
});

/// Notifier para invalidar canchas cuando se crea/edita una
class CanchasAdminNotifier extends Notifier<void> {
  @override
  void build() {}

  void invalidate() {
    ref.invalidateSelf();
  }
}

final canchasAdminNotifierProvider =
    NotifierProvider<CanchasAdminNotifier, void>(
  CanchasAdminNotifier.new,
);
