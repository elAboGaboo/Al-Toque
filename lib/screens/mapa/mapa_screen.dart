import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../core/theme/app_colors.dart';
import '../../models/complejo_model.dart';
import '../../models/flash_slot_model.dart';
import '../../providers/map_provider.dart';
import 'widgets/cancha_card_horizontal.dart';
import 'widgets/demand_chip.dart';
import 'widgets/filter_bar.dart';
import 'widgets/map_marker_painter.dart';

// Coordenadas centro de Huancayo
const _huancayo = LatLng(-12.0651, -75.2049);

class MapaScreen extends ConsumerStatefulWidget {
  const MapaScreen({super.key});

  @override
  ConsumerState<MapaScreen> createState() => _MapaScreenState();
}

class _MapaScreenState extends ConsumerState<MapaScreen>
    with TickerProviderStateMixin {
  GoogleMapController? _mapController;
  final DraggableScrollableController _sheetController =
      DraggableScrollableController();

  // Marcadores
  final Map<String, Marker> _markers = {};

  // Animación flash pulse
  late AnimationController _pulseController;
  Timer? _markerRefreshTimer;

  // Última posición conocida del usuario
  LatLng? _userPos;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    // Refresca los markers flash cada 30 s para actualizar countdown
    _markerRefreshTimer =
        Timer.periodic(const Duration(seconds: 30), (_) => _rebuildMarkers());
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _markerRefreshTimer?.cancel();
    _mapController?.dispose();
    _sheetController.dispose();
    super.dispose();
  }

  // ── Construcción de marcadores ─────────────────────────────

  Future<void> _rebuildMarkers() async {
    if (!mounted) return;
    final pos = _userPos ?? _huancayo;
    final filter = ref.read(mapFilterProvider);

    final complejosAsync =
        ref.read(complejosCercanosProvider(pos));
    final flashAsync = ref.read(flashSlotsActivosProvider);
    final partidosAsync = ref.read(partidosAbiertosProvider);

    final complejos = complejosAsync.valueOrNull ?? [];
    final flashSlots = flashAsync.valueOrNull ?? [];
    final partidos = partidosAsync.valueOrNull ?? [];

    final newMarkers = <String, Marker>{};

    // Pin usuario
    newMarkers['me'] = Marker(
      markerId: const MarkerId('me'),
      position: pos,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      zIndexInt: 10,
    );

    // Filtra según filtro activo
    final showNormal =
        filter == MapFilter.todos || filter == MapFilter.disponibles;
    final showFlash =
        filter == MapFilter.todos || filter == MapFilter.flash;
    final showPartidos =
        filter == MapFilter.todos || filter == MapFilter.partidos;

    // Pins complejos normales
    if (showNormal) {
      for (final c in complejos) {
        // Si hay flash slot activo en este complejo → no mostrar como normal
        final tieneFlash =
            flashSlots.any((f) => f.complejoId == c.id && f.isActivo);
        if (tieneFlash && filter != MapFilter.disponibles) continue;

        final icon = await MapMarkerPainter.pinNormal(
          precio: '40',
          nombre: c.nombre,
        );
        newMarkers[c.id] = Marker(
          markerId: MarkerId(c.id),
          position: LatLng(c.lat, c.lng),
          icon: icon,
          onTap: () => _onComplejoTap(c),
          zIndexInt: 1,
        );
      }
    }

    // Pins flash
    if (showFlash) {
      for (final slot in flashSlots) {
        final c =
            complejos.where((x) => x.id == slot.complejoId).firstOrNull;
        if (c == null) continue;

        final icon = await MapMarkerPainter.pinFlash(
          precio: slot.precioFlash.toStringAsFixed(0),
          countdown: slot.tiempoRestanteLabel,
        );
        newMarkers['flash_${slot.id}'] = Marker(
          markerId: MarkerId('flash_${slot.id}'),
          position: LatLng(c.lat, c.lng),
          icon: icon,
          onTap: () => _onFlashTap(slot, c),
          zIndexInt: 3,
        );
      }
    }

    // Pins partidos
    if (showPartidos) {
      for (final partido in partidos) {
        final c =
            complejos.where((x) => x.id == partido.complejoId).firstOrNull;
        if (c == null) continue;

        final icon = await MapMarkerPainter.pinPartido(
          deporte: partido.deporteEmoji,
          hora: partido.horaInicio,
          progreso:
              '${partido.jugadoresActuales}/${partido.jugadoresNecesarios}',
        );
        newMarkers['partido_${partido.id}'] = Marker(
          markerId: MarkerId('partido_${partido.id}'),
          position: LatLng(c.lat, c.lng),
          icon: icon,
          onTap: () => context.push('/partido/${partido.id}'),
          zIndexInt: 2,
        );
      }
    }

    if (mounted) {
      setState(() => _markers
        ..clear()
        ..addAll(newMarkers));
    }
  }

  // ── Handlers de tap ────────────────────────────────────────

  void _onComplejoTap(ComplejoModel complejo) {
    ref.read(complejoSeleccionadoProvider.notifier).state = complejo;
    _sheetController.animateTo(
      0.55,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
  }

  void _onFlashTap(FlashSlotModel slot, ComplejoModel complejo) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _FlashSlotSheet(slot: slot, complejo: complejo),
    );
  }

  void _recenter() {
    if (_userPos != null && _mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: _userPos!, zoom: 15),
        ),
      );
    }
  }

  // ── Build ──────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final ubicacionAsync = ref.watch(ubicacionProvider);

    // Cuando cambia la ubicación, actualizar pos y markers
    ref.listen(ubicacionProvider, (_, next) {
      next.whenData((pos) {
        if (pos != null) {
          _userPos = pos;
          _rebuildMarkers();
        }
      });
    });

    // Cuando cambian los datos (flash, partidos, complejos), reconstruir
    ref.listen(flashSlotsActivosProvider, (_, _) => _rebuildMarkers());
    ref.listen(partidosAbiertosProvider, (_, _) => _rebuildMarkers());
    ref.listen(mapFilterProvider, (_, _) => _rebuildMarkers());

    final initialTarget = ubicacionAsync.valueOrNull ?? _huancayo;

    return Scaffold(
      body: Stack(
        children: [
          // ── Mapa ──────────────────────────────────────────
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: initialTarget,
              zoom: 14.5,
            ),
            onMapCreated: (ctrl) {
              _mapController = ctrl;
              _rebuildMarkers();
            },
            markers: Set<Marker>.of(_markers.values),
            myLocationEnabled: false,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            compassEnabled: false,
            padding: const EdgeInsets.only(bottom: 180),
          ),

          // ── Gradiente superior ────────────────────────────
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 160,
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppColors.paper.withValues(alpha: 0.95),
                      AppColors.paper.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── SearchBar ─────────────────────────────────────
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            left: 16,
            right: 16,
            child: _SearchBar(onTap: () => context.push('/partidos')),
          ),

          // ── FilterChips ───────────────────────────────────
          Positioned(
            top: MediaQuery.of(context).padding.top + 72,
            left: 0,
            right: 0,
            child: const MapFilterBar(),
          ),

          // ── Demand chip (abajo izquierda) ─────────────────
          Positioned(
            bottom: 200,
            left: 16,
            child: _DemandChipWrapper(),
          ),

          // ── Botón recenter ────────────────────────────────
          Positioned(
            bottom: 200,
            right: 16,
            child: _RecenterButton(onTap: _recenter),
          ),

          // ── Bottom sheet ──────────────────────────────────
          DraggableScrollableSheet(
            controller: _sheetController,
            initialChildSize: 0.18,
            minChildSize: 0.12,
            maxChildSize: 0.85,
            snap: true,
            snapSizes: const [0.18, 0.45, 0.85],
            builder: (context, scrollController) {
              return _BottomSheetContent(
                scrollController: scrollController,
                userPos: _userPos ?? _huancayo,
                onComplejoTap: _onComplejoTap,
              );
            },
          ),

          // ── FAB Crear partido ─────────────────────────────
          Positioned(
            bottom: 16,
            right: 16,
            child: _CrearPartidoFab(
              onTap: () => context.push('/crear-partido'),
            ),
          ),
        ],
      ),
    );
  }
}

// ── SearchBar ────────────────────────────────────────────────

class _SearchBar extends StatelessWidget {
  final VoidCallback onTap;
  const _SearchBar({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.line),
          boxShadow: [
            BoxShadow(
              color: AppColors.ink.withValues(alpha: 0.08),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Row(
          children: [
            Icon(Icons.search_rounded,
                color: AppColors.ink.withValues(alpha: 0.4), size: 20),
            const SizedBox(width: 10),
            Text(
              'Buscar canchas en Huancayo…',
              style: GoogleFonts.outfit(
                fontSize: 14,
                color: AppColors.ink.withValues(alpha: 0.45),
              ),
            ),
            const Spacer(),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.greenLight,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'Buscar',
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.green,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Recenter button ──────────────────────────────────────────

class _RecenterButton extends StatelessWidget {
  final VoidCallback onTap;
  const _RecenterButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(12),
      elevation: 4,
      shadowColor: AppColors.ink.withValues(alpha: 0.15),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(10),
          child: const Icon(Icons.my_location_rounded,
              color: AppColors.green, size: 22),
        ),
      ),
    );
  }
}

// ── Demand chip wrapper ──────────────────────────────────────

class _DemandChipWrapper extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pos = ref.watch(ubicacionProvider).valueOrNull;
    if (pos == null) return const SizedBox.shrink();

    final complejos =
        ref.watch(complejosCercanosProvider(pos)).valueOrNull ?? [];
    if (complejos.isEmpty) return const SizedBox.shrink();

    final prediccionAsync =
        ref.watch(prediccionCercanosProvider(complejos.first.id));

    return prediccionAsync.when(
      data: (pred) =>
          pred != null ? DemandChip(prediccion: pred) : const SizedBox.shrink(),
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }
}

// ── FAB Crear partido ────────────────────────────────────────

class _CrearPartidoFab extends StatelessWidget {
  final VoidCallback onTap;
  const _CrearPartidoFab({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.party,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: AppColors.party.withValues(alpha: 0.4),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.group_add_rounded,
                color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(
              'Crear partido',
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Bottom sheet content ─────────────────────────────────────

class _BottomSheetContent extends ConsumerWidget {
  final ScrollController scrollController;
  final LatLng userPos;
  final void Function(ComplejoModel) onComplejoTap;

  const _BottomSheetContent({
    required this.scrollController,
    required this.userPos,
    required this.onComplejoTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final complejosAsync = ref.watch(complejosCercanosProvider(userPos));
    final svc = ref.read(complejosServiceProvider);

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 24,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: ListView(
        controller: scrollController,
        padding: EdgeInsets.zero,
        children: [
          // Handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 4),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.line,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
            child: Row(
              children: [
                Text(
                  'Canchas cercanas',
                  style: GoogleFonts.bricolageGrotesque(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
                const Spacer(),
                complejosAsync.when(
                  data: (list) => Text(
                    '${list.length} resultados',
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      color: AppColors.ink.withValues(alpha: 0.5),
                    ),
                  ),
                  loading: () => const SizedBox.shrink(),
                  error: (_, _) => const SizedBox.shrink(),
                ),
              ],
            ),
          ),

          // Lista horizontal de complejos
          SizedBox(
            height: 230,
            child: complejosAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.green),
              ),
              error: (e, _) => Center(
                child: Text(
                  'Error cargando canchas',
                  style: GoogleFonts.outfit(color: AppColors.ink),
                ),
              ),
              data: (complejos) {
                if (complejos.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.sports_soccer_outlined,
                            size: 40, color: AppColors.line),
                        const SizedBox(height: 8),
                        Text(
                          'No hay canchas en tu zona',
                          style: GoogleFonts.outfit(
                              fontSize: 14,
                              color: AppColors.ink.withValues(alpha: 0.5)),
                        ),
                      ],
                    ),
                  );
                }
                return ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: complejos.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 12),
                  itemBuilder: (context, i) {
                    final c = complejos[i];
                    final dist = svc.distanciaKm(
                        userPos.latitude, userPos.longitude, c);
                    return CanchaCardHorizontal(
                      complejo: c,
                      distanciaKm: dist,
                      onTap: () => onComplejoTap(c),
                    );
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ── Flash Slot sheet (inline) ─────────────────────────────────

class _FlashSlotSheet extends StatelessWidget {
  final FlashSlotModel slot;
  final ComplejoModel complejo;

  const _FlashSlotSheet({required this.slot, required this.complejo});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Badge Flash
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.flashLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('⚡', style: TextStyle(fontSize: 13)),
                    const SizedBox(width: 4),
                    Text(
                      'Flash Slot',
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.flash,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              // Countdown
              _CountdownTimer(expiraEn: slot.expiraEn),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            complejo.nombre,
            style: GoogleFonts.bricolageGrotesque(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
          Text(
            '${slot.horaInicio} – ${slot.horaFin}',
            style: GoogleFonts.outfit(
                fontSize: 14, color: AppColors.ink.withValues(alpha: 0.6)),
          ),
          const SizedBox(height: 20),
          // Precios
          Row(
            children: [
              Text(
                'S/${slot.precioOriginal.toStringAsFixed(0)}',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  decoration: TextDecoration.lineThrough,
                  color: AppColors.ink.withValues(alpha: 0.4),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'S/${slot.precioFlash.toStringAsFixed(0)}',
                style: GoogleFonts.bricolageGrotesque(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: AppColors.flash,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.flashLight,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '-${slot.descuentoPct}%',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.flash,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Urgencia
          LinearProgressIndicator(
            value: (slot.vistasCount / 20).clamp(0, 1),
            backgroundColor: AppColors.line,
            color: AppColors.flashPin,
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(height: 4),
          Text(
            '${slot.vistasCount} personas viendo este slot',
            style: GoogleFonts.outfit(
              fontSize: 11,
              color: AppColors.ink.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 20),
          // Callout IA
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.flashLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: AppColors.flashPin.withValues(alpha: 0.4)),
            ),
            child: Row(
              children: [
                const Text('🤖', style: TextStyle(fontSize: 18)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'La IA detectó que esta cancha lleva más de 1 hora sin reservas. '
                    'Precio reducido automáticamente.',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      color: AppColors.flash,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.flash,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: () {
                Navigator.pop(context);
                // Navegar a reservar con precio flash
              },
              child: Text(
                'Reservar por S/${slot.precioFlash.toStringAsFixed(0)} · Flash',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
        ],
      ),
    );
  }
}

// ── Countdown timer ──────────────────────────────────────────

class _CountdownTimer extends StatefulWidget {
  final DateTime expiraEn;
  const _CountdownTimer({required this.expiraEn});

  @override
  State<_CountdownTimer> createState() => _CountdownTimerState();
}

class _CountdownTimerState extends State<_CountdownTimer> {
  late Timer _timer;
  late Duration _remaining;

  @override
  void initState() {
    super.initState();
    _remaining = widget.expiraEn.difference(DateTime.now());
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() =>
          _remaining = widget.expiraEn.difference(DateTime.now()));
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isUrgent = _remaining.inMinutes < 10;
    final label = _remaining.isNegative
        ? 'Expirado'
        : '${_remaining.inMinutes.toString().padLeft(2, '0')}:'
            '${(_remaining.inSeconds % 60).toString().padLeft(2, '0')}';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isUrgent
            ? AppColors.errorRedLight
            : AppColors.flashLight,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.timer_rounded,
            size: 13,
            color: isUrgent ? AppColors.errorRed : AppColors.flash,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: isUrgent ? AppColors.errorRed : AppColors.flash,
            ),
          ),
        ],
      ),
    );
  }
}
