// providers/reservas_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../modelos/reserva_modelo.dart';
import '../repositorios/reservas_repositorio.dart';
import 'auth_proveedor.dart';

final reservasRepositoryProvider = Provider<ReservasRepository>(
  (_) => ReservasRepository(),
);

final disponibilidadFutureProvider = FutureProvider.family<List<ReservaModel>,
    ({String complejoId, String canchaId, DateTime fecha})>((ref, params) {
  return ref.watch(reservasRepositoryProvider).getReservasDelDia(
        complejoId: params.complejoId,
        canchaId: params.canchaId,
        fecha: params.fecha,
      );
});

final disponibilidadProvider = StreamProvider.family<List<ReservaModel>,
    ({String complejoId, String canchaId, DateTime fecha})>((ref, params) {
  return ref.watch(reservasRepositoryProvider).streamReservasDelDia(
        complejoId: params.complejoId,
        canchaId: params.canchaId,
        fecha: params.fecha,
      );
});

final misReservasProvider = StreamProvider<List<ReservaModel>>((ref) {
  final uid = ref.watch(uidProvider);
  if (uid == null) return const Stream.empty();
  return ref.watch(reservasRepositoryProvider).streamMisReservas(uid);
});

final reservaProvider =
    StreamProvider.family<ReservaModel?, String>((ref, reservaId) {
  return ref.watch(reservasRepositoryProvider).streamReserva(reservaId);
});

final reservaFutureProvider =
    FutureProvider.family<ReservaModel?, String>((ref, reservaId) {
  return ref.watch(reservasRepositoryProvider).getReserva(reservaId);
});

final reservasComplejoProvider =
    StreamProvider.family<List<ReservaModel>, String>((ref, complejoId) {
  return ref
      .watch(reservasRepositoryProvider)
      .streamReservasComplejo(complejoId);
});

final reservasComplejoFechaProvider = StreamProvider.family<List<ReservaModel>,
    ({String complejoId, DateTime fecha})>((ref, params) {
  return ref
      .watch(reservasRepositoryProvider)
      .streamReservasComplejoFecha(
          complejoId: params.complejoId, fecha: params.fecha);
});

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
    String? partidoId,
  }) async {
    state = const AsyncLoading();

    final uid = ref.read(uidProvider);
    if (uid == null) {
      state = AsyncError('No autenticado', StackTrace.current);
      return null;
    }

    final codigoAcceso = const Uuid().v4();
    final userName =
        ref.read(perfilUsuarioProvider).asData?.value?.nombre ?? '';

    final reserva = ReservaModel(
      id: '',
      complejoId: complejoId,
      canchaId: canchaId,
      userId: uid,
      userName: userName,
      fecha: fecha,
      horaInicio: horaInicio,
      horaFin: horaFin,
      duracionHoras: duracionHoras,
      precioTotal: precioTotal,
      estado: 'confirmada',
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
      return reserva.copyWith(id: reservaId!);
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
