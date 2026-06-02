// providers/reservas_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../modelos/reserva_modelo.dart';
import '../repositorios/reservas_repositorio.dart';
import 'auth_proveedor.dart';

final reservasRepositoryProvider = Provider<ReservasRepository>(
  (_) => ReservasRepository(),
);

/// One-shot de disponibilidad con timeout (para ReservarScreen).
/// Evita el spinner eterno del StreamProvider cuando Firestore tarda.
/// El usuario puede refrescar al cambiar de fecha (el provider se invalida
/// automáticamente porque la clave cambia con cada fecha seleccionada).
final disponibilidadFutureProvider = FutureProvider.family<List<ReservaModel>,
    ({String complejoId, String canchaId, DateTime fecha})>((ref, params) {
  return ref.watch(reservasRepositoryProvider).getReservasDelDia(
        complejoId: params.complejoId,
        canchaId: params.canchaId,
        fecha: params.fecha,
      );
});

/// Stream de disponibilidad de una cancha en una fecha (tiempo real).
/// Úsalo solo donde sea crítica la actualización en vivo.
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
/// NOTA: Usado solo en pantallas admin o donde se necesite actualización live.
/// Para ConfirmacionScreen usar reservaFutureProvider (tiene timeout).
final reservaProvider =
    StreamProvider.family<ReservaModel?, String>((ref, reservaId) {
  return ref.watch(reservasRepositoryProvider).streamReserva(reservaId);
});

/// One-shot fetch de una reserva por ID con timeout de 8 s.
/// Úsalo en ConfirmacionScreen para evitar spinner eterno si Firestore tarda.
final reservaFutureProvider =
    FutureProvider.family<ReservaModel?, String>((ref, reservaId) {
  return ref.watch(reservasRepositoryProvider).getReserva(reservaId);
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
      // Guardar la reserva con el ID real para que ConfirmacionScreen
      // pueda leerla del caché sin hacer otro request a Firestore.
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
