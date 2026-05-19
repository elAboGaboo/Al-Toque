// providers/complejos_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/cancha_model.dart';
import '../models/complejo_model.dart';
import '../repositories/complejos_repository.dart';
import 'auth_provider.dart';

final complejosRepositoryProvider = Provider<ComplejosRepository>(
  (_) => ComplejosRepository(),
);

/// Stream de todos los complejos activos.
final complejosProvider = StreamProvider<List<ComplejoModel>>((ref) {
  return ref.watch(complejosRepositoryProvider).streamComplejos();
});

/// Stream de un complejo específico.
final complejoProvider =
    StreamProvider.family<ComplejoModel?, String>((ref, complejoId) {
  return ref.watch(complejosRepositoryProvider).streamComplejo(complejoId);
});

/// Stream de canchas de un complejo.
final canchasProvider =
    StreamProvider.family<List<CanchaModel>, String>((ref, complejoId) {
  return ref.watch(complejosRepositoryProvider).streamCanchas(complejoId);
});

/// Complejo seleccionado en el mapa (para bottom sheet detalle).
class ComplejoSeleccionadoNotifier extends Notifier<ComplejoModel?> {
  @override
  ComplejoModel? build() => null;
}

final complejoSeleccionadoProvider =
    NotifierProvider<ComplejoSeleccionadoNotifier, ComplejoModel?>(
  ComplejoSeleccionadoNotifier.new,
);

/// Cancha seleccionada (para flujo de reserva).
class CanchaSeleccionadaNotifier extends Notifier<CanchaModel?> {
  @override
  CanchaModel? build() => null;
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

/// Stream de todos los complejos del admin logueado
final misComplejosProvider = StreamProvider<List<ComplejoModel>>((ref) {
  final perfil = ref.watch(perfilUsuarioProvider);
  final complejosIds = perfil.asData?.value?.complejosIds ?? [];

  if (complejosIds.isEmpty) {
    return Stream.value([]);
  }

  return ref
      .watch(complejosRepositoryProvider)
      .streamComplejos()
      .map((todos) => todos.where((c) => complejosIds.contains(c.id)).toList());
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
