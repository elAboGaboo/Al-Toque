// pantallas/usuario/complejo_detalle_pantalla.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../nucleo/tema/app_colores.dart';
import '../../nucleo/utilidades/mapas_lanzador.dart';
import '../../modelos/cancha_modelo.dart';
import '../../modelos/complejo_modelo.dart';
import '../../proveedores/complejos_proveedor.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Canchas: carga one-shot robusta con timeout.
// Primero lee `canchasActivas` del doc raíz; si faltan, usa un fallback puntual
// a la subcolección para reparar el dato y evitar pantallas en blanco.
// ─────────────────────────────────────────────────────────────────────────────

class ComplejoDetalleScreen extends ConsumerStatefulWidget {
  final String complejoId;
  const ComplejoDetalleScreen({super.key, required this.complejoId});

  @override
  ConsumerState<ComplejoDetalleScreen> createState() =>
      _ComplejoDetalleScreenState();
}

class _ComplejoDetalleScreenState
    extends ConsumerState<ComplejoDetalleScreen> {
  // Complejo capturado sincrónicamente en initState.
  // Para navegación normal (Inicio/Mapa) siempre está disponible.
  // Para deep links (_complejo == null) se usa complejoFutureProvider.
  ComplejoModel? _complejoCache;
  Timer? _timeoutTimer;
  bool _tiempoAgotado = false;

  @override
  void initState() {
    super.initState();
    final cached = ref.read(complejoSeleccionadoProvider);
    if (cached != null && cached.id == widget.complejoId) {
      _complejoCache = cached;
    }
    _timeoutTimer = Timer(const Duration(seconds: 8), () {
      if (mounted) setState(() => _tiempoAgotado = true);
    });
  }

  @override
  void dispose() {
    _timeoutTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final complejoAsync =
        ref.watch(complejoDetalleJugadorProvider(widget.complejoId));

    final complejoLive = complejoAsync.asData?.value;
    final complejo = complejoLive ?? _complejoCache;

    if (complejo == null) {
      return complejoAsync.when(
        loading: () => _Scaffold(child: _LoadingView(onBack: _goBack)),
        error: (e, _) => _Scaffold(
          child: _ErrorView(
            error: e.toString(),
            onRetry: () =>
                ref.invalidate(complejoDetalleJugadorProvider(widget.complejoId)),
          ),
        ),
        data: (_) => _Scaffold(child: _NotFoundView(onBack: _goBack)),
      );
    }

    final canchas = complejo.canchasActivas;
    final cargandoCanchas =
        canchas.isEmpty && complejoAsync.isLoading && !_tiempoAgotado;
    final errorCanchas = _tiempoAgotado && canchas.isEmpty && complejoAsync.isLoading
        ? 'No se pudo cargar las canchas. Verifica tu conexión.'
        : complejoAsync.hasError
            ? complejoAsync.error.toString()
            : null;

    return _Scaffold(
      child: _buildContent(
        complejo,
        canchas: canchas,
        cargando: cargandoCanchas,
        error: errorCanchas,
        onReintentar: () {
          setState(() => _tiempoAgotado = false);
          _timeoutTimer?.cancel();
          _timeoutTimer = Timer(const Duration(seconds: 8), () {
            if (mounted) setState(() => _tiempoAgotado = true);
          });
          ref.invalidate(complejoDetalleJugadorProvider(widget.complejoId));
        },
      ),
    );
  }

  void _goBack() => context.pop();

  // ── Contenido principal: header + canchas ─────────────────────────────

  Widget _buildContent(
    ComplejoModel complejo, {
    required List<CanchaModel> canchas,
    required bool cargando,
    String? error,
    VoidCallback? onReintentar,
  }) {
    return CustomScrollView(
      slivers: [
        // Header con imagen del complejo
        _SliverHeader(complejo: complejo, onBack: _goBack),

        // Botón "Cómo llegar" — abre Google Maps
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => MapsLauncher.irA(
                  lat: complejo.lat,
                  lng: complejo.lng,
                  nombre: complejo.nombre,
                ),
                icon: const Icon(Icons.directions_rounded, size: 16),
                label: Text(
                  'Cómo llegar',
                  style: GoogleFonts.outfit(
                      fontSize: 13, fontWeight: FontWeight.w600),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.acc,
                  side: const BorderSide(color: AppColors.acc),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ),
        ),

        // Título sección canchas
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
            child: Text(
              'Canchas disponibles',
              style: GoogleFonts.bricolageGrotesque(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.tx,
                letterSpacing: -0.3,
              ),
            ),
          ),
        ),

        ..._canchasSliver(
          complejo,
          canchas: canchas,
          cargando: cargando,
          error: error,
          onReintentar: onReintentar,
        ),
      ],
    );
  }

  // ── Slivers de canchas según estado ───────────────────────────────────

  List<Widget> _canchasSliver(
    ComplejoModel complejo, {
    required List<CanchaModel> canchas,
    required bool cargando,
    String? error,
    VoidCallback? onReintentar,
  }) {
    if (cargando) {
      return [
        const SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(
                  color: AppColors.acc,
                  strokeWidth: 2.5,
                ),
                SizedBox(height: 14),
                Text(
                  'Cargando canchas…',
                  style: TextStyle(color: AppColors.tx3, fontSize: 13),
                ),
              ],
            ),
          ),
        ),
      ];
    }

    if (error != null) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: _CanchasError(
            error: error,
            onRetry: onReintentar ?? () {},
          ),
        ),
      ];
    }

    if (canchas.isEmpty) {
      final msg = (complejo.numeroCanchas > 0 && complejo.canchasActivas.isEmpty)
          ? 'Este complejo tiene canchas registradas, pero aún no están publicadas para jugadores.\nPide al dueño que entre a Admin → Canchas → subir a la nube.'
          : 'Este complejo aún no tiene canchas activas.\nVuelve pronto.';
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: _EmptyStateCanchas(mensaje: msg),
        ),
      ];
    }

    return [
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 100),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate(
            (_, i) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _CanchaCard(
                cancha: canchas[i],
                onReservar: () {
                  ref.read(complejoSeleccionadoProvider.notifier).select(complejo);
                  ref.read(canchaSeleccionadaProvider.notifier).select(canchas[i]);
                  context.push('/reservar/${complejo.id}/${canchas[i].id}');
                },
              ),
            ),
            childCount: canchas.length,
          ),
        ),
      ),
    ];
  }
}

// ── Scaffold base (evita repetir backgroundColor en cada estado) ─────────────

class _Scaffold extends StatelessWidget {
  final Widget child;
  const _Scaffold({required this.child});

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.bg,
        body: child,
      );
}

// ── Vista: cargando complejo (deep links) ─────────────────────────────────────

class _LoadingView extends StatelessWidget {
  final VoidCallback onBack;
  const _LoadingView({required this.onBack});

  @override
  Widget build(BuildContext context) => SafeArea(
        child: Column(
          children: [
            _BackButton(onBack: onBack),
            const Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: AppColors.acc),
                    SizedBox(height: 16),
                    Text('Cargando complejo…',
                        style:
                            TextStyle(color: AppColors.tx2, fontSize: 13)),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
}

// ── Vista: error al cargar complejo (deep links) ──────────────────────────────

class _ErrorView extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;
  const _ErrorView({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final msg = _errorMsg(error);
    return SafeArea(
      child: Column(
        children: [
          _BackButton(onBack: () => context.pop()),
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _ErrorIcon(),
                    const SizedBox(height: 16),
                    Text('Error al cargar',
                        style: GoogleFonts.bricolageGrotesque(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.tx)),
                    const SizedBox(height: 8),
                    Text(msg,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.outfit(
                            fontSize: 13,
                            color: AppColors.tx2,
                            height: 1.5)),
                    const SizedBox(height: 20),
                    _RetryButton(onRetry: onRetry),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Vista: complejo no encontrado ─────────────────────────────────────────────

class _NotFoundView extends StatelessWidget {
  final VoidCallback onBack;
  const _NotFoundView({required this.onBack});

  @override
  Widget build(BuildContext context) => SafeArea(
        child: Column(
          children: [
            _BackButton(onBack: onBack),
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.search_off_rounded,
                        color: AppColors.tx3, size: 48),
                    const SizedBox(height: 16),
                    Text('Complejo no encontrado',
                        style: GoogleFonts.bricolageGrotesque(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.tx)),
                    const SizedBox(height: 8),
                    Text('Este complejo ya no está disponible.',
                        style: GoogleFonts.outfit(
                            fontSize: 13, color: AppColors.tx2)),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: onBack,
                      style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.acc,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12))),
                      child: Text('Volver',
                          style: GoogleFonts.outfit(
                              fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
}

// ── Error inline de canchas ───────────────────────────────────────────────────

class _CanchasError extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;
  const _CanchasError({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.sur,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.bdr2),
            boxShadow: [
              BoxShadow(
                color: AppColors.tx.withValues(alpha: 0.05),
                blurRadius: 12,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _ErrorIcon(),
              const SizedBox(height: 14),
              Text('No se pudieron cargar las canchas',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.bricolageGrotesque(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.tx)),
              const SizedBox(height: 8),
              Text(_errorMsg(error),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                      fontSize: 13, color: AppColors.tx2, height: 1.4)),
              const SizedBox(height: 16),
              _RetryButton(onRetry: onRetry),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Sliver header con imagen ──────────────────────────────────────────────────

class _SliverHeader extends StatelessWidget {
  final ComplejoModel complejo;
  final VoidCallback onBack;
  const _SliverHeader({required this.complejo, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 240,
      pinned: true,
      backgroundColor: AppColors.bg,
      automaticallyImplyLeading: false,
      leading: GestureDetector(
        onTap: onBack,
        child: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.arrow_back_rounded,
              color: AppColors.tx, size: 20),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            complejo.imagenPrincipal.isNotEmpty
                ? Image.network(
                    complejo.imagenPrincipal,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => _Placeholder(),
                  )
                : _Placeholder(),
            // Gradiente para legibilidad del texto
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    AppColors.tx.withValues(alpha: 0.75),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
            // Info del complejo
            Positioned(
              left: 20,
              right: 20,
              bottom: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    complejo.nombre,
                    style: GoogleFonts.bricolageGrotesque(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(children: [
                    const Icon(Icons.location_on_rounded,
                        size: 13, color: Colors.white70),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        complejo.direccion,
                        style: GoogleFonts.outfit(
                            fontSize: 12,
                            color: Colors.white.withValues(alpha: 0.8)),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ]),
                  const SizedBox(height: 6),
                  Row(children: [
                    const Icon(Icons.star_rounded,
                        size: 13, color: AppColors.amber),
                    const SizedBox(width: 4),
                    Text(
                      complejo.ciudad,
                      style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white),
                    ),
                    const SizedBox(width: 16),
                    const Icon(Icons.access_time_rounded,
                        size: 13, color: Colors.white70),
                    const SizedBox(width: 4),
                    Text(
                      '${complejo.horarioApertura} – ${complejo.horarioCierre}',
                      style: GoogleFonts.outfit(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.8)),
                    ),
                  ]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Tarjeta de cancha ─────────────────────────────────────────────────────────

class _CanchaCard extends StatelessWidget {
  final CanchaModel cancha;
  final VoidCallback onReservar;
  const _CanchaCard({required this.cancha, required this.onReservar});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.sur,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.bdr2),
        boxShadow: [
          BoxShadow(
            color: AppColors.tx.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Ícono deporte
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.accLight,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(cancha.deporteEmoji,
                      style: const TextStyle(fontSize: 26)),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cancha.nombre,
                      style: GoogleFonts.bricolageGrotesque(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.tx,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${cancha.deporteLabel} · ${cancha.superficieLabel} · ${cancha.capacidad} jug.',
                      style:
                          GoogleFonts.outfit(fontSize: 12, color: AppColors.tx2),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          'S/ ${cancha.precioBase.toStringAsFixed(0)}',
                          style: GoogleFonts.bricolageGrotesque(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.acc,
                          ),
                        ),
                        Text(
                          ' / hora',
                          style: GoogleFonts.outfit(
                              fontSize: 11, color: AppColors.tx3),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              onPressed: onReservar,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.acc,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                minimumSize: const Size(0, 0),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
              child: Text(
                'Reservar',
                style:
                    GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Empty state de canchas ────────────────────────────────────────────────────

class _EmptyStateCanchas extends StatelessWidget {
  final String mensaje;
  const _EmptyStateCanchas({
    this.mensaje = 'Este complejo aún no tiene canchas activas.\nVuelve pronto.',
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.accLight,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.stadium_outlined,
                  color: AppColors.acc, size: 34),
            ),
            const SizedBox(height: 18),
            Text('Sin canchas disponibles',
                style: GoogleFonts.bricolageGrotesque(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppColors.tx)),
            const SizedBox(height: 8),
            Text(
              mensaje,
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                  fontSize: 13, color: AppColors.tx2, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Widgets auxiliares compartidos ────────────────────────────────────────────

class _BackButton extends StatelessWidget {
  final VoidCallback onBack;
  const _BackButton({required this.onBack});

  @override
  Widget build(BuildContext context) => Align(
        alignment: Alignment.centerLeft,
        child: IconButton(
          icon:
              const Icon(Icons.arrow_back_rounded, color: AppColors.tx),
          onPressed: onBack,
        ),
      );
}

class _ErrorIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: AppColors.red.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(Icons.wifi_off_rounded,
            color: AppColors.red, size: 26),
      );
}

class _RetryButton extends StatelessWidget {
  final VoidCallback onRetry;
  const _RetryButton({required this.onRetry});

  @override
  Widget build(BuildContext context) => FilledButton.icon(
        onPressed: onRetry,
        icon: const Icon(Icons.refresh_rounded, size: 16),
        label: Text('Reintentar',
            style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.acc,
          padding: const EdgeInsets.symmetric(
              horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
        ),
      );
}

class _Placeholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        color: AppColors.sur2,
        child: const Center(
          child: Icon(Icons.sports_soccer_rounded,
              color: AppColors.acc, size: 48),
        ),
      );
}

// ── Helper: mensaje de error legible ─────────────────────────────────────────

String _errorMsg(String error) {
  if (error.contains('permission-denied') || error.contains('403')) {
    return 'Sin permisos para leer los datos.\nRevisa las reglas de Firestore.';
  }
  if (error.contains('timeout') ||
      error.contains('respondió') ||
      error.contains('timed out')) {
    return 'Sin respuesta del servidor.\nVerifica tu conexión e intenta de nuevo.';
  }
  if (error.contains('unavailable') ||
      error.contains('network') ||
      error.contains('conexión')) {
    return 'Sin conexión a internet.\nConéctate y toca "Reintentar".';
  }
  return 'Algo salió mal. Toca "Reintentar".';
}
