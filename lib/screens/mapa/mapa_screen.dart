// screens/mapa/mapa_screen.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';

import '../../core/services/directions_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/geo_utils.dart';
import '../../models/complejo_model.dart';
import '../../providers/complejos_provider.dart';
import 'widgets/filter_bar.dart';
import 'widgets/map_marker_painter.dart';

class MapaScreen extends ConsumerStatefulWidget {
  const MapaScreen({super.key});

  @override
  ConsumerState<MapaScreen> createState() => _MapaScreenState();
}

class _MapaScreenState extends ConsumerState<MapaScreen> {
  final _mapController = MapController();

  // Posición real del usuario — arranca en Huancayo y se actualiza con GPS
  LatLng _userPos = const LatLng(-12.0651, -75.2049);
  bool _locationLoading = true;
  StreamSubscription<Position>? _posSub;

  ComplejoModel? _selectedComplejo;
  List<LatLng> _polylinePoints = [];
  bool _loadingRoute = false;

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  @override
  void dispose() {
    _posSub?.cancel();
    _mapController.dispose();
    super.dispose();
  }

  // ── GPS ──────────────────────────────────────────────────────────────────────

  Future<void> _initLocation() async {
    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }

    if (!mounted) return;

    if (perm == LocationPermission.deniedForever ||
        perm == LocationPermission.denied) {
      setState(() => _locationLoading = false);
      return;
    }

    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) setState(() => _locationLoading = false);
      return;
    }

    // Primera posición (rápida)
    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      ).timeout(const Duration(seconds: 15));

      if (!mounted) return;

      final latlng = LatLng(pos.latitude, pos.longitude);
      setState(() {
        _userPos = latlng;
        _locationLoading = false;
      });
      // Centrar mapa en la posición real obtenida
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _mapController.move(_userPos, 15),
      );
    } catch (_) {
      if (mounted) setState(() => _locationLoading = false);
    }

    // Stream de actualizaciones en tiempo real
    _posSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 15, // cada 15 metros
      ),
    ).listen((pos) {
      if (mounted) {
        setState(() => _userPos = LatLng(pos.latitude, pos.longitude));
      }
    });
  }

  // ── Acciones ─────────────────────────────────────────────────────────────────

  Future<void> _onComplejoTap(ComplejoModel complejo) async {
    final destination = LatLng(complejo.lat, complejo.lng);

    setState(() {
      _selectedComplejo = complejo;
      _polylinePoints = [];
      _loadingRoute = true;
    });

    _mapController.move(destination, 15.5);

    final puntos = await DirectionsService.getRoute(
      origin: _userPos,
      destination: destination,
    );

    if (!mounted) return;

    setState(() {
      _polylinePoints = puntos ?? [];
      _loadingRoute = false;
    });

    if (puntos == null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'No se encontró ruta hacia ${complejo.nombre}',
            style: GoogleFonts.outfit(fontSize: 13),
          ),
          backgroundColor: AppColors.tx,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 90),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  void _irAMiUbicacion() => _mapController.move(_userPos, 16);

  void _limpiarRuta() {
    setState(() {
      _selectedComplejo = null;
      _polylinePoints = [];
    });
  }

  // ── Build ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final complejosAsync = ref.watch(complejosProvider);

    if (complejosAsync.hasError) {
      debugPrint('[MapaScreen] Error cargando complejos: ${complejosAsync.error}');
    }

    final complejos = (complejosAsync.asData?.value ?? [])
        .where((c) =>
            GeoUtils.distanciaKm(
              lat1: _userPos.latitude,
              lng1: _userPos.longitude,
              lat2: c.lat,
              lng2: c.lng,
            ) <=
            50)
        .toList();

    final markers = <Marker>[
      // Punto azul del usuario
      Marker(
        point: _userPos,
        width: 22,
        height: 22,
        alignment: Alignment.center,
        child: MapMarkerPainter.pinUsuario(),
      ),
      // Pins de complejos
      for (final c in complejos)
        Marker(
          point: LatLng(c.lat, c.lng),
          width: 120,
          height: 60,
          alignment: Alignment.bottomCenter,
          child: GestureDetector(
            onTap: () => _onComplejoTap(c),
            child: MapMarkerPainter.pinNormal(
              precio: '40',
              nombre: _selectedComplejo?.id == c.id
                  ? '✓ ${c.nombre}'
                  : c.nombre,
            ),
          ),
        ),
    ];

    return Scaffold(
      body: SizedBox.expand(
        child: Stack(
          children: [
            // ── Mapa ─────────────────────────────────────────────
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _userPos,
                initialZoom: 14.5,
                onTap: (_, _) {
                  if (_selectedComplejo != null) _limpiarRuta();
                },
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png',
                  subdomains: const ['a', 'b', 'c', 'd'],
                  userAgentPackageName: 'com.altoque.app',
                  retinaMode: RetinaMode.isHighDensity(context),
                  maxZoom: 20,
                ),
                if (_polylinePoints.isNotEmpty)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: _polylinePoints,
                        color: AppColors.acc,
                        strokeWidth: 4,
                      ),
                    ],
                  ),
                MarkerLayer(markers: markers),
              ],
            ),

            // ── Barra de búsqueda ─────────────────────────────────
            Positioned(
              top: MediaQuery.of(context).padding.top + 16,
              left: 20,
              right: 20,
              child: _SearchBar(
                selectedComplejo: _selectedComplejo,
                onClearSelection: _limpiarRuta,
              ),
            ),

            // ── Filtros ──────────────────────────────────────────
            Positioned(
              top: MediaQuery.of(context).padding.top + 80,
              left: 0,
              right: 0,
              child: const MapFilterBar(),
            ),

            // ── Overlay: buscando ubicación ──────────────────────
            if (_locationLoading)
              Positioned(
                top: MediaQuery.of(context).padding.top + 128,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.sur,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.bdr),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.tx.withValues(alpha: 0.10),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.acc,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Buscando tu ubicación…',
                          style: GoogleFonts.outfit(
                              fontSize: 12, color: AppColors.tx2),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // ── Overlay: calculando ruta ─────────────────────────
            if (_loadingRoute)
              Positioned(
                top: MediaQuery.of(context).padding.top + 128,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.acc,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.acc.withValues(alpha: 0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Calculando ruta…',
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // ── Botón "Mi ubicación" ─────────────────────────────
            Positioned(
              bottom: complejos.isNotEmpty ? 242 : 40,
              right: 20,
              child: FloatingActionButton.small(
                heroTag: 'mi_ubicacion',
                onPressed: _irAMiUbicacion,
                backgroundColor: AppColors.sur,
                elevation: 4,
                child: const Icon(
                  Icons.my_location_rounded,
                  color: AppColors.acc,
                  size: 20,
                ),
              ),
            ),

            // ── Carousel inferior de complejos ───────────────────
            if (complejos.isNotEmpty)
              Align(
                alignment: Alignment.bottomCenter,
                child: _ComplejoCarousel(
                  complejos: complejos,
                  userPos: _userPos,
                  selectedId: _selectedComplejo?.id,
                  onTap: _onComplejoTap,
                ),
              ),

            // ── Empty state ──────────────────────────────────────
            if (complejos.isEmpty && !_loadingRoute && !_locationLoading)
              Positioned(
                bottom: 40,
                left: 20,
                right: 20,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.sur,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.bdr),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.search_off_rounded,
                          color: AppColors.tx3, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          complejosAsync.hasError
                              ? 'Error cargando complejos. Verifica tu conexión.'
                              : 'Aún no hay complejos registrados en Huancayo.',
                          style: GoogleFonts.outfit(
                              fontSize: 13, color: AppColors.tx2),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Barra de búsqueda / indicador de selección ──────────────────────────────

class _SearchBar extends StatelessWidget {
  final ComplejoModel? selectedComplejo;
  final VoidCallback onClearSelection;

  const _SearchBar({
    required this.selectedComplejo,
    required this.onClearSelection,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      height: 52,
      decoration: BoxDecoration(
        color: AppColors.sur,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.tx.withValues(alpha: 0.10),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: AppColors.bdr),
      ),
      child: selectedComplejo != null
          ? Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.acc,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        selectedComplejo!.nombre,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.tx,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        selectedComplejo!.direccion,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          color: AppColors.tx3,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: onClearSelection,
                  child: const Icon(Icons.close_rounded,
                      color: AppColors.tx3, size: 18),
                ),
              ],
            )
          : Row(
              children: [
                const Icon(Icons.search_rounded,
                    color: AppColors.tx3, size: 20),
                const SizedBox(width: 12),
                Text(
                  'Huancayo, Junín',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.tx,
                  ),
                ),
                const Spacer(),
                const VerticalDivider(indent: 12, endIndent: 12, width: 24),
                const Icon(Icons.tune_rounded,
                    color: AppColors.acc, size: 20),
              ],
            ),
    );
  }
}

// ── Carousel inferior con complejos reales ───────────────────────────────────

class _ComplejoCarousel extends StatefulWidget {
  final List<ComplejoModel> complejos;
  final LatLng userPos;
  final String? selectedId;
  final void Function(ComplejoModel) onTap;

  const _ComplejoCarousel({
    required this.complejos,
    required this.userPos,
    required this.selectedId,
    required this.onTap,
  });

  @override
  State<_ComplejoCarousel> createState() => _ComplejoCarouselState();
}

class _ComplejoCarouselState extends State<_ComplejoCarousel> {
  late final PageController _controller;

  @override
  void initState() {
    super.initState();
    _controller = PageController(viewportFraction: 0.88);
  }

  @override
  void didUpdateWidget(_ComplejoCarousel old) {
    super.didUpdateWidget(old);
    if (widget.selectedId != null && widget.selectedId != old.selectedId) {
      final idx =
          widget.complejos.indexWhere((c) => c.id == widget.selectedId);
      if (idx >= 0 && _controller.hasClients) {
        _controller.animateToPage(
          idx,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeInOut,
        );
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 210,
      child: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _controller,
              itemCount: widget.complejos.length,
              onPageChanged: (i) => widget.onTap(widget.complejos[i]),
              itemBuilder: (context, i) {
                final c = widget.complejos[i];
                final isSelected = c.id == widget.selectedId;
                final distKm = GeoUtils.distanciaKm(
                  lat1: widget.userPos.latitude,
                  lng1: widget.userPos.longitude,
                  lat2: c.lat,
                  lng2: c.lng,
                );

                return GestureDetector(
                  onTap: () => widget.onTap(c),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: EdgeInsets.fromLTRB(
                        6, isSelected ? 0 : 8, 6, isSelected ? 0 : 8),
                    decoration: BoxDecoration(
                      color: AppColors.sur,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected ? AppColors.acc : AppColors.bdr,
                        width: isSelected ? 2 : 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.tx.withValues(
                              alpha: isSelected ? 0.14 : 0.07),
                          blurRadius: isSelected ? 20 : 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        // Imagen
                        ClipRRect(
                          borderRadius: const BorderRadius.horizontal(
                              left: Radius.circular(18)),
                          child: SizedBox(
                            width: 110,
                            height: double.infinity,
                            child: c.imagenPrincipal.isNotEmpty
                                ? Image.network(
                                    c.imagenPrincipal,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, _, _) =>
                                        _placeholderImagen(),
                                  )
                                : _placeholderImagen(),
                          ),
                        ),

                        // Info
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      c.nombre,
                                      style:
                                          GoogleFonts.bricolageGrotesque(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.tx,
                                        letterSpacing: -0.3,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        const Icon(
                                            Icons.location_on_rounded,
                                            size: 11,
                                            color: AppColors.tx3),
                                        const SizedBox(width: 2),
                                        Text(
                                          GeoUtils.formatearDistancia(
                                              distKm),
                                          style: GoogleFonts.outfit(
                                              fontSize: 11,
                                              color: AppColors.tx3),
                                        ),
                                        const SizedBox(width: 8),
                                        const Icon(Icons.star_rounded,
                                            size: 11,
                                            color: AppColors.amber),
                                        const SizedBox(width: 2),
                                        Text(
                                          c.rating.toStringAsFixed(1),
                                          style: GoogleFonts.outfit(
                                              fontSize: 11,
                                              color: AppColors.tx3),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),

                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Desde S/40',
                                          style: GoogleFonts.outfit(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.acc,
                                          ),
                                        ),
                                        Text(
                                          '${c.horarioApertura} – ${c.horarioCierre}',
                                          style: GoogleFonts.outfit(
                                            fontSize: 10,
                                            color: AppColors.tx3,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        GestureDetector(
                                          onTap: () => context
                                              .push('/complejo/${c.id}'),
                                          child: Container(
                                            padding:
                                                const EdgeInsets.symmetric(
                                                    horizontal: 10,
                                                    vertical: 6),
                                            decoration: BoxDecoration(
                                              color: AppColors.acc,
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            child: Text(
                                              'Ver canchas',
                                              style: GoogleFonts.outfit(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w700,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        _RutaChip(isSelected: isSelected),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 8, top: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                widget.complejos.length,
                (i) {
                  final isActive =
                      widget.complejos[i].id == widget.selectedId;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: isActive ? 16 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: isActive
                          ? AppColors.acc
                          : AppColors.tx3.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _placeholderImagen() => Container(
        color: AppColors.sur2,
        child: const Center(
          child: Icon(Icons.sports_soccer_rounded,
              color: AppColors.acc, size: 28),
        ),
      );
}

// ── Chip de estado de ruta ────────────────────────────────────────────────────

class _RutaChip extends StatelessWidget {
  final bool isSelected;
  const _RutaChip({required this.isSelected});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.acc : AppColors.accLight,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isSelected
                ? Icons.directions_rounded
                : Icons.directions_outlined,
            size: 13,
            color: isSelected ? Colors.white : AppColors.acc,
          ),
          const SizedBox(width: 4),
          Text(
            isSelected ? 'Ruta activa' : 'Ver ruta',
            style: GoogleFonts.outfit(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : AppColors.acc,
            ),
          ),
        ],
      ),
    );
  }
}
