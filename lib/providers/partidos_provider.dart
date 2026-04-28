// providers/partidos_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/partido_model.dart';
import '../repositories/partidos_repository.dart';
import 'auth_provider.dart';

final partidosRepositoryProvider = Provider<PartidosRepository>(
  (_) => PartidosRepository(),
);

/// Stream de partidos abiertos (para el mapa y búsqueda).
final partidosAbiertosProvider =
    StreamProvider<List<PartidoModel>>((ref) {
  return ref.watch(partidosRepositoryProvider).streamPartidosAbiertos();
});

/// Stream de un partido específico (tiempo real).
final partidoProvider =
    StreamProvider.family<PartidoModel?, String>((ref, partidoId) {
  return ref.watch(partidosRepositoryProvider).streamPartido(partidoId);
});

/// Mis partidos (como organizador o jugador).
final misPartidosProvider = StreamProvider<List<PartidoModel>>((ref) {
  final uid = ref.watch(uidProvider);
  if (uid == null) return const Stream.empty();
  return ref.watch(partidosRepositoryProvider).streamMisPartidos(uid);
});

/// Partidos de un complejo (admin).
final partidosComplejoProvider =
    StreamProvider.family<List<PartidoModel>, String>((ref, complejoId) {
  return ref
      .watch(partidosRepositoryProvider)
      .streamPartidosComplejo(complejoId);
});

// ── Filtros para búsqueda de partidos ─────────────────────────

class FiltrosPartidos {
  final String? deporte;
  final DateTime? fecha;

  const FiltrosPartidos({this.deporte, this.fecha});

  FiltrosPartidos copyWith({String? deporte, DateTime? fecha}) =>
      FiltrosPartidos(
        deporte: deporte ?? this.deporte,
        fecha: fecha ?? this.fecha,
      );
}

final filtrosPartidosProvider =
    StateProvider<FiltrosPartidos>((_) => const FiltrosPartidos());

/// Partidos abiertos filtrados por deporte/fecha.
final partidosFiltradosProvider =
    Provider<AsyncValue<List<PartidoModel>>>((ref) {
  final partidos = ref.watch(partidosAbiertosProvider);
  final filtros = ref.watch(filtrosPartidosProvider);

  return partidos.whenData((list) {
    var filtered = list;

    if (filtros.deporte != null) {
      filtered =
          filtered.where((p) => p.deporte == filtros.deporte).toList();
    }

    if (filtros.fecha != null) {
      filtered = filtered.where((p) {
        final f = filtros.fecha!;
        return p.fecha.year == f.year &&
            p.fecha.month == f.month &&
            p.fecha.day == f.day;
      }).toList();
    }

    return filtered;
  });
});

// ── Notifier para crear/unirse/salir de partidos ──────────────

class PartidoNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<String?> crearPartido(PartidoModel partido) async {
    state = const AsyncLoading();
    String? id;
    state = await AsyncValue.guard(() async {
      id = await ref.read(partidosRepositoryProvider).crearPartido(partido);
    });
    return id;
  }

  Future<void> unirse({
    required String partidoId,
    required JugadorPartido jugador,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(partidosRepositoryProvider).unirseAlPartido(
            partidoId: partidoId,
            jugador: jugador,
          );
    });
  }

  Future<void> salir({
    required String partidoId,
    required String userId,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(partidosRepositoryProvider).salirDelPartido(
            partidoId: partidoId,
            userId: userId,
          );
    });
  }

  Future<void> cancelar(String partidoId) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(partidosRepositoryProvider).cancelarPartido(partidoId);
    });
  }
}

final partidoNotifierProvider =
    AsyncNotifierProvider<PartidoNotifier, void>(PartidoNotifier.new);
