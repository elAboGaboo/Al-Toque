// screens/admin/admin_setup_complejo_screen.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';

import '../../core/constants/app_constants.dart';
import '../../core/services/places_service.dart';
import '../../core/theme/app_colors.dart';
import '../../models/complejo_model.dart';
import '../../providers/auth_provider.dart';
import '../../repositories/complejos_repository.dart';
import '../../repositories/usuarios_repository.dart';

class AdminSetupComplejoScreen extends ConsumerStatefulWidget {
  const AdminSetupComplejoScreen({super.key});

  @override
  ConsumerState<AdminSetupComplejoScreen> createState() =>
      _AdminSetupComplejoScreenState();
}

class _AdminSetupComplejoScreenState
    extends ConsumerState<AdminSetupComplejoScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  // ── Modo CREAR ─────────────────────────────────────────────
  final _formKey = GlobalKey<FormState>();
  final _nombreCtrl = TextEditingController();
  final _direccionCtrl = TextEditingController();
  String _horaApertura = '07:00';
  String _horaCierre = '23:00';
  double _lat = AppConstants.huancayoLat;
  double _lng = AppConstants.huancayoLng;
  bool _gpsDetectado = false;
  bool _gpsLoading = false;

  // ── Autocomplete de direccion ───────────────────────────────
  final _placesService = PlacesService();
  List<PlacePrediction> _sugerencias = [];
  bool _buscandoDireccion = false;
  bool _cargandoUbicacion = false;
  Timer? _debounce;

  // ── Modo RECLAMAR ───────────────────────────────────────────
  List<ComplejoModel>? _complejosLibres;
  bool _cargandoComplejos = false;
  ComplejoModel? _complejoSeleccionado;

  // ── Estado compartido ───────────────────────────────────────
  bool _guardando = false;
  bool _guardado = false;

  static const _horasApertura = [
    '05:00', '06:00', '07:00', '08:00', '09:00', '10:00',
  ];
  static const _horasCierre = [
    '18:00', '19:00', '20:00', '21:00', '22:00', '23:00', '00:00',
  ];

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _tabs.addListener(() {
      if (_tabs.index == 1 && _complejosLibres == null) {
        _cargarComplejosLibres();
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _tabs.dispose();
    _nombreCtrl.dispose();
    _direccionCtrl.dispose();
    super.dispose();
  }

  // ── Autocompletado de direccion ──────────────────────────────

  void _onDireccionChanged(String v) {
    _debounce?.cancel();
    if (v.trim().length < 3) {
      if (_sugerencias.isNotEmpty) setState(() => _sugerencias = []);
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 450), () async {
      if (!mounted) return;
      setState(() => _buscandoDireccion = true);
      final results = await _placesService.autocomplete(v);
      if (mounted) {
        setState(() {
          _sugerencias = results;
          _buscandoDireccion = false;
        });
      }
    });
  }

  Future<void> _seleccionarDireccion(PlacePrediction p) async {
    _direccionCtrl.text = p.text;
    setState(() {
      _sugerencias = [];
      _cargandoUbicacion = true;
    });
    final loc = await _placesService.getPlaceDetails(p.placeId);
    if (mounted) {
      setState(() {
        _cargandoUbicacion = false;
        if (loc != null) {
          _lat = loc.lat;
          _lng = loc.lng;
          _gpsDetectado = true;
        }
      });
    }
  }

  // ── GPS ─────────────────────────────────────────────────────

  Future<void> _detectarGPS() async {
    setState(() => _gpsLoading = true);
    try {
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        _snack('GPS denegado — se usará Huancayo centro',
            color: AppColors.ablu);
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(accuracy: LocationAccuracy.high),
      );
      setState(() {
        _lat = pos.latitude;
        _lng = pos.longitude;
        _gpsDetectado = true;
      });
    } catch (_) {
      _snack('GPS no disponible', color: AppColors.ablu);
    } finally {
      if (mounted) setState(() => _gpsLoading = false);
    }
  }

  // ── Cargar complejos sin admin asignado ──────────────────────

  Future<void> _cargarComplejosLibres() async {
    setState(() => _cargandoComplejos = true);
    try {
      final libres = await ComplejosRepository().getComplejosLibres();
      if (mounted) setState(() => _complejosLibres = libres);
    } catch (e) {
      if (mounted) _snack('Error al cargar: $e', color: AppColors.ared);
    } finally {
      if (mounted) setState(() => _cargandoComplejos = false);
    }
  }

  // ── Guardar (crear nuevo) ────────────────────────────────────

  Future<void> _crearComplejo() async {
    if (!_formKey.currentState!.validate()) return;
    if (_guardando || _guardado) return;
    setState(() => _guardando = true);

    try {
      final uid = ref.read(uidProvider);
      if (uid == null) throw Exception('Sesión expirada');

      final repo = ComplejosRepository();
      final complejoId = await repo.crearComplejoNuevo(
        ComplejoModel(
          id: '',
          nombre: _nombreCtrl.text.trim(),
          direccion: _direccionCtrl.text.trim(),
          ciudad: 'Huancayo',
          lat: _lat,
          lng: _lng,
          rating: 0,
          totalResenias: 0,
          horarioApertura: _horaApertura,
          horarioCierre: _horaCierre,
          imagenes: const [],
          duenoUid: uid,
          activo: true,
        ),
      );

      await UsuariosRepository().actualizarComplejoId(uid, complejoId);

      if (mounted) {
        setState(() {
          _guardado = true;
          _guardando = false;
        });
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) context.go('/admin/dashboard');
      }
    } catch (e) {
      if (mounted) {
        _snack('Error: $e', color: AppColors.ared);
        setState(() => _guardando = false);
      }
    }
  }

  // ── Reclamar complejo existente ──────────────────────────────

  Future<void> _reclamarComplejo() async {
    final complejo = _complejoSeleccionado;
    if (complejo == null) {
      _snack('Selecciona un complejo primero', color: AppColors.ablu);
      return;
    }
    if (_guardando || _guardado) return;
    setState(() => _guardando = true);

    try {
      final uid = ref.read(uidProvider);
      if (uid == null) throw Exception('Sesión expirada');

      // Vincular admin al complejo
      await ComplejosRepository().asignarAdmin(complejo.id, uid);

      await UsuariosRepository().actualizarComplejoId(uid, complejo.id);

      if (mounted) {
        setState(() {
          _guardado = true;
          _guardando = false;
        });
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) context.go('/admin/dashboard');
      }
    } catch (e) {
      if (mounted) {
        _snack('Error: $e', color: AppColors.ared);
        setState(() => _guardando = false);
      }
    }
  }

  void _snack(String msg, {Color? color}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.outfit()),
      backgroundColor: color ?? AppColors.asur,
      behavior: SnackBarBehavior.floating,
    ));
  }

  // ── Build ────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.abg,
      body: SafeArea(
        child: _guardado
            ? _buildExito()
            : Column(
                children: [
                  // ── Header ─────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.aaccD,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.stadium_rounded,
                              color: AppColors.aacc, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Configura tu complejo',
                                style: GoogleFonts.bricolageGrotesque(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.atx,
                                ),
                              ),
                              Text(
                                'Paso necesario para acceder al panel',
                                style: GoogleFonts.outfit(
                                    fontSize: 12, color: AppColors.atx3),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ── Tabs ────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Container(
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.asur,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.abdr),
                      ),
                      child: TabBar(
                        controller: _tabs,
                        indicator: BoxDecoration(
                          color: AppColors.aacc,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        indicatorSize: TabBarIndicatorSize.tab,
                        dividerColor: Colors.transparent,
                        labelColor: Colors.black,
                        unselectedLabelColor: AppColors.atx2,
                        labelStyle: GoogleFonts.outfit(
                            fontSize: 13, fontWeight: FontWeight.w700),
                        unselectedLabelStyle:
                            GoogleFonts.outfit(fontSize: 13),
                        tabs: const [
                          Tab(text: 'Crear nuevo'),
                          Tab(text: 'Usar uno existente'),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 4),

                  // ── Tab content ─────────────────────────────
                  Expanded(
                    child: TabBarView(
                      controller: _tabs,
                      children: [
                        _buildTabCrear(),
                        _buildTabReclamar(),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  // ── Tab 1: Crear nuevo ───────────────────────────────────────

  Widget _buildTabCrear() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 48),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Label('Nombre del complejo'),
            const SizedBox(height: 8),
            _Input(
              controller: _nombreCtrl,
              hint: 'Ej: El Tambo Sport',
              icon: Icons.stadium_outlined,
              validator: (v) => (v == null || v.trim().length < 3)
                  ? 'Mínimo 3 caracteres'
                  : null,
            ),
            const SizedBox(height: 20),

            _Label('Dirección'),
            const SizedBox(height: 8),
            // Campo con autocompletado via RapidAPI Google Map Places
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _direccionCtrl,
                  onChanged: _onDireccionChanged,
                  style: GoogleFonts.outfit(
                      fontSize: 15, color: AppColors.atx),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Ingresa la dirección del complejo'
                      : null,
                  decoration: InputDecoration(
                    hintText: 'Ej: Av. Ferrocarril 245, El Tambo',
                    hintStyle: GoogleFonts.outfit(
                        fontSize: 14, color: AppColors.atx3),
                    prefixIcon: const Icon(Icons.location_on_outlined,
                        size: 18, color: AppColors.atx3),
                    suffixIcon: _buscandoDireccion || _cargandoUbicacion
                        ? const Padding(
                            padding: EdgeInsets.all(12),
                            child: SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.aacc),
                            ),
                          )
                        : _gpsDetectado && _direccionCtrl.text.isNotEmpty
                            ? const Icon(Icons.check_circle_rounded,
                                color: AppColors.aacc, size: 18)
                            : null,
                    filled: true,
                    fillColor: AppColors.asur,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: AppColors.abdr),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: AppColors.abdr),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                          color: AppColors.aacc, width: 1.5),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide:
                          const BorderSide(color: AppColors.ared),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                          color: AppColors.ared, width: 1.5),
                    ),
                  ),
                ),
                // Dropdown de sugerencias
                if (_sugerencias.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    decoration: BoxDecoration(
                      color: AppColors.asur,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.abdr),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: _sugerencias
                          .take(5)
                          .map((p) => InkWell(
                                onTap: () => _seleccionarDireccion(p),
                                borderRadius: BorderRadius.circular(14),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 12),
                                  child: Row(
                                    children: [
                                      const Icon(
                                          Icons.location_on_rounded,
                                          size: 16,
                                          color: AppColors.aacc),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          p.text,
                                          style: GoogleFonts.outfit(
                                              fontSize: 13,
                                              color: AppColors.atx),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ))
                          .toList(),
                    ),
                  ),
                // Muestra coordenadas confirmadas
                if (_gpsDetectado && !_cargandoUbicacion)
                  Padding(
                    padding: const EdgeInsets.only(top: 6, left: 4),
                    child: Row(
                      children: [
                        const Icon(Icons.pin_drop_rounded,
                            size: 13, color: AppColors.aacc),
                        const SizedBox(width: 4),
                        Text(
                          'Lat ${_lat.toStringAsFixed(5)}, '
                          'Lng ${_lng.toStringAsFixed(5)}',
                          style: GoogleFonts.outfit(
                              fontSize: 11, color: AppColors.atx3),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),

            _Label('Horario de atención'),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _Dropdown(
                    horas: _horasApertura,
                    valor: _horaApertura,
                    onChanged: (v) => setState(() => _horaApertura = v!),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Text('→',
                      style: GoogleFonts.outfit(
                          fontSize: 18, color: AppColors.atx2)),
                ),
                Expanded(
                  child: _Dropdown(
                    horas: _horasCierre,
                    valor: _horaCierre,
                    onChanged: (v) => setState(() => _horaCierre = v!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            _Label('Ubicación en el mapa'),
            const SizedBox(height: 4),
            Text(
              'Opcional — default: Huancayo centro',
              style: GoogleFonts.outfit(
                  fontSize: 11, color: AppColors.atx3),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _gpsLoading ? null : _detectarGPS,
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.asur,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: _gpsDetectado
                        ? AppColors.aacc
                        : AppColors.abdr,
                    width: _gpsDetectado ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: _gpsDetectado
                            ? AppColors.aaccD
                            : AppColors.asur2,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: _gpsLoading
                          ? const Center(
                              child: SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.aacc,
                                ),
                              ),
                            )
                          : Icon(
                              _gpsDetectado
                                  ? Icons.my_location_rounded
                                  : Icons.location_searching_rounded,
                              size: 18,
                              color: _gpsDetectado
                                  ? AppColors.aacc
                                  : AppColors.atx3,
                            ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _gpsDetectado
                                ? 'Ubicación detectada ✓'
                                : 'Usar mi ubicación actual',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: _gpsDetectado
                                  ? AppColors.aacc
                                  : AppColors.atx,
                            ),
                          ),
                          if (_gpsDetectado)
                            Text(
                              '${_lat.toStringAsFixed(4)}, ${_lng.toStringAsFixed(4)}',
                              style: GoogleFonts.outfit(
                                  fontSize: 11, color: AppColors.atx3),
                            ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded,
                        color: AppColors.atx3, size: 18),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 36),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.aacc,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                onPressed: _guardando ? null : _crearComplejo,
                child: _guardando
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.black),
                      )
                    : Text(
                        'Crear complejo y empezar',
                        style: GoogleFonts.bricolageGrotesque(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Tab 2: Reclamar existente ────────────────────────────────

  Widget _buildTabReclamar() {
    if (_cargandoComplejos) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.aacc),
      );
    }

    final libres = _complejosLibres ?? [];

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
          child: Text(
            'Selecciona el complejo que administras. Solo aparecen los que aún no tienen dueño asignado.',
            style: GoogleFonts.outfit(fontSize: 13, color: AppColors.atx2),
          ),
        ),

        if (libres.isEmpty)
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.search_off_rounded,
                    color: AppColors.atx3, size: 48),
                const SizedBox(height: 12),
                Text(
                  'No hay complejos disponibles',
                  style: GoogleFonts.outfit(
                      fontSize: 14, color: AppColors.atx2),
                ),
                const SizedBox(height: 6),
                Text(
                  'Primero pobla la base de datos\ndesde el perfil → "Poblar base de datos"',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                      fontSize: 12, color: AppColors.atx3),
                ),
                const SizedBox(height: 20),
                TextButton(
                  onPressed: _cargarComplejosLibres,
                  child: Text('Recargar',
                      style: GoogleFonts.outfit(color: AppColors.aacc)),
                ),
              ],
            ),
          )
        else ...[
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
              itemCount: libres.length,
              itemBuilder: (_, i) {
                final c = libres[i];
                final selected = _complejoSeleccionado?.id == c.id;
                return GestureDetector(
                  onTap: () =>
                      setState(() => _complejoSeleccionado = c),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.aaccD
                          : AppColors.asur,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: selected
                            ? AppColors.aacc
                            : AppColors.abdr,
                        width: selected ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: selected
                                ? AppColors.aacc.withValues(alpha: 0.2)
                                : AppColors.asur2,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.stadium_rounded,
                            color: selected
                                ? AppColors.aacc
                                : AppColors.atx3,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                c.nombre,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: selected
                                      ? AppColors.aacc
                                      : AppColors.atx,
                                ),
                              ),
                              Text(
                                c.direccion,
                                style: GoogleFonts.outfit(
                                    fontSize: 12,
                                    color: AppColors.atx3),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                '${c.horarioApertura} – ${c.horarioCierre}  ·  ${c.rating.toStringAsFixed(1)} ★',
                                style: GoogleFonts.outfit(
                                    fontSize: 11,
                                    color: AppColors.atx3),
                              ),
                            ],
                          ),
                        ),
                        if (selected)
                          const Icon(Icons.check_circle_rounded,
                              color: AppColors.aacc, size: 20),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _complejoSeleccionado != null
                      ? AppColors.aacc
                      : AppColors.asur2,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                onPressed: (_guardando || _complejoSeleccionado == null)
                    ? null
                    : _reclamarComplejo,
                child: _guardando
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.black),
                      )
                    : Text(
                        _complejoSeleccionado != null
                            ? 'Administrar ${_complejoSeleccionado!.nombre}'
                            : 'Selecciona un complejo',
                        style: GoogleFonts.bricolageGrotesque(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: _complejoSeleccionado != null
                              ? Colors.black
                              : AppColors.atx3,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  // ── Pantalla de éxito ────────────────────────────────────────

  Widget _buildExito() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.aaccD,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(Icons.check_rounded,
                color: AppColors.aacc, size: 34),
          ),
          const SizedBox(height: 20),
          Text(
            '¡Complejo vinculado!',
            style: GoogleFonts.bricolageGrotesque(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: AppColors.atx,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Entrando al dashboard...',
            style:
                GoogleFonts.outfit(fontSize: 14, color: AppColors.atx2),
          ),
          const SizedBox(height: 28),
          const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
                strokeWidth: 2, color: AppColors.aacc),
          ),
        ],
      ),
    );
  }
}

// ── Sub-widgets ──────────────────────────────────────────────────────────────

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.atx2,
          letterSpacing: 0.3,
        ),
      );
}

class _Input extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final String? Function(String?)? validator;

  const _Input({
    required this.controller,
    required this.hint,
    required this.icon,
    this.validator,
  });

  @override
  Widget build(BuildContext context) => TextFormField(
        controller: controller,
        validator: validator,
        style: GoogleFonts.outfit(fontSize: 15, color: AppColors.atx),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle:
              GoogleFonts.outfit(fontSize: 14, color: AppColors.atx3),
          prefixIcon: Icon(icon, size: 18, color: AppColors.atx3),
          filled: true,
          fillColor: AppColors.asur,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: AppColors.abdr),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: AppColors.abdr),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.aacc, width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.ared),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.ared, width: 1.5),
          ),
        ),
      );
}

class _Dropdown extends StatelessWidget {
  final List<String> horas;
  final String valor;
  final void Function(String?) onChanged;

  const _Dropdown({
    required this.horas,
    required this.valor,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.asur,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.abdr),
        ),
        child: DropdownButton<String>(
          value: valor,
          isExpanded: true,
          underline: const SizedBox.shrink(),
          dropdownColor: AppColors.asur,
          style: GoogleFonts.outfit(fontSize: 14, color: AppColors.atx),
          items: horas
              .map((h) => DropdownMenuItem(value: h, child: Text(h)))
              .toList(),
          onChanged: onChanged,
        ),
      );
}

