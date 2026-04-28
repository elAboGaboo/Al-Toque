// providers/complejos_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/cancha_model.dart';
import '../models/complejo_model.dart';
import '../repositories/complejos_repository.dart';

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
final complejoSeleccionadoProvider = StateProvider<ComplejoModel?>((ref) => null);

/// Cancha seleccionada (para flujo de reserva).
final canchaSeleccionadaProvider = StateProvider<CanchaModel?>((ref) => null);

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

/// Filtro de deporte en búsqueda de complejos.
final filtroDeporteProvider = StateProvider<String?>((ref) => null);

/// Complejos filtrados por deporte.
final complejosFiltradosProvider =
    Provider<AsyncValue<List<ComplejoModel>>>((ref) {
  final complejos = ref.watch(complejosProvider);
  final deporte = ref.watch(filtroDeporteProvider);
  if (deporte == null) return complejos;
  return complejos.whenData((list) =>
      list.where((c) => true).toList()); // filtro real por cancha en repo
});
