// providers/reservas_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../models/reserva_model.dart';
import '../repositories/reservas_repository.dart';
import 'auth_provider.dart';

final reservasRepositoryProvider = Provider<ReservasRepository>(
  (_) => ReservasRepository(),
);

/// Stream de disponibilidad de una cancha en una fecha (tiempo real).
final disponibilidadProvider = StreamProvider.family<List<ReservaModel>,
    ({String complejoId, String canchaId, DateTime fecha})>((ref, params) {
  return ref.watch(reservasRepositoryProvider).streamReservasDelDia(
        complejoId: params.complejoId,
        canchaId: params.canchaId,
        fecha: params.fecha,
      );
});

/// Mis reservas del usuario actual.
final misReservasProvider = StreamProvider<List<ReservaModel>>((ref) {
  final uid = ref.watch(uidProvider);
  if (uid == null) return const Stream.empty();
  return ref.watch(reservasRepositoryProvider).streamMisReservas(uid);
});

/// Una reserva específica en tiempo real.
final reservaProvider =
    StreamProvider.family<ReservaModel?, String>((ref, reservaId) {
  return ref.watch(reservasRepositoryProvider).streamReserva(reservaId);
});

/// Reservas del complejo (admin).
final reservasComplejoProvider =
    StreamProvider.family<List<ReservaModel>, String>((ref, complejoId) {
  return ref
      .watch(reservasRepositoryProvider)
      .streamReservasComplejo(complejoId);
});

/// Reservas del complejo para una fecha (admin horarios).
final reservasComplejoFechaProvider = StreamProvider.family<List<ReservaModel>,
    ({String complejoId, DateTime fecha})>((ref, params) {
  return ref
      .watch(reservasRepositoryProvider)
      .streamReservasComplejoFecha(
          complejoId: params.complejoId, fecha: params.fecha);
});

// ── Notifier para crear/cancelar reservas ─────────────────────

class ReservaNotifier extends AsyncNotifier<ReservaModel?> {
  @override
  Future<ReservaModel?> build() async => null;

  Future<String?> crearReserva({
    required String complejoId,
    required String canchaId,
    required DateTime fecha,
    required String horaInicio,
    required String horaFin,
    required double duracionHoras,
    required double precioTotal,
    required String metodoPago,
    String tipo = 'normal',
    String? flashSlotId,
    String? partidoId,
  }) async {
    state = const AsyncLoading();
    final uid = ref.read(uidProvider);
    if (uid == null) {
      state = AsyncError('No autenticado', StackTrace.current);
      return null;
    }

    final codigoAcceso = const Uuid().v4();
    final reserva = ReservaModel(
      id: '',
      complejoId: complejoId,
      canchaId: canchaId,
      userId: uid,
      fecha: fecha,
      horaInicio: horaInicio,
      horaFin: horaFin,
      duracionHoras: duracionHoras,
      precioTotal: precioTotal,
      estado: 'confirmada',
      tipo: tipo,
      flashSlotId: flashSlotId,
      partidoId: partidoId,
      metodoPago: metodoPago,
      codigoAcceso: codigoAcceso,
      creadoEn: DateTime.now(),
    );

    String? reservaId;
    state = await AsyncValue.guard(() async {
      reservaId = await ref
          .read(reservasRepositoryProvider)
          .crearReserva(reserva);
      return reserva;
    });

    return reservaId;
  }

  Future<void> cancelarReserva(String reservaId) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(reservasRepositoryProvider).cancelarReserva(reservaId);
      return null;
    });
  }
}

final reservaNotifierProvider =
    AsyncNotifierProvider<ReservaNotifier, ReservaModel?>(ReservaNotifier.new);
