// providers/flash_slots_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../modelos/flash_slot_modelo.dart';
import '../repositorios/flash_slots_repositorio.dart';

final flashSlotsRepositoryProvider = Provider<FlashSlotsRepository>(
  (_) => FlashSlotsRepository(),
);

/// Stream de flash slots activos (tiempo real).
final flashSlotsActivosProvider =
    StreamProvider<List<FlashSlotModel>>((ref) {
  return ref.watch(flashSlotsRepositoryProvider).streamSlotsActivos();
});

/// Flash slots de un complejo (admin).
final flashSlotsComplejoProvider =
    StreamProvider.family<List<FlashSlotModel>, String>((ref, complejoId) {
  return ref
      .watch(flashSlotsRepositoryProvider)
      .streamSlotsComplejo(complejoId);
});

/// Notifier para crear flash slots (admin).
class FlashSlotNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<String?> crearSlot(FlashSlotModel slot) async {
    state = const AsyncLoading();
    String? id;
    state = await AsyncValue.guard(() async {
      id = await ref.read(flashSlotsRepositoryProvider).crearSlot(slot);
    });
    return id;
  }

  Future<void> incrementarVistas(String slotId) async {
    await ref.read(flashSlotsRepositoryProvider).incrementarVistas(slotId);
  }

  Future<void> marcarReservado(String slotId) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(flashSlotsRepositoryProvider).marcarReservado(slotId);
    });
  }
}

final flashSlotNotifierProvider =
    AsyncNotifierProvider<FlashSlotNotifier, void>(FlashSlotNotifier.new);
