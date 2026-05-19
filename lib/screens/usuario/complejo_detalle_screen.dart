// screens/usuario/complejo_detalle_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_colors.dart';
import '../../models/cancha_model.dart';
import '../../models/complejo_model.dart';
import '../../providers/complejos_provider.dart';

class ComplejoDetalleScreen extends ConsumerWidget {
  final String complejoId;
  const ComplejoDetalleScreen({super.key, required this.complejoId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final complejoAsync = ref.watch(complejoProvider(complejoId));

    return complejoAsync.when(
      loading: () => _buildScaffold(
        context,
        body: const Center(
          child: CircularProgressIndicator(color: AppColors.acc),
        ),
      ),
      error: (e, _) {
        debugPrint('[ComplejoDetalle] error: $e');
        return _buildScaffold(
          context,
          body: _ErrorBody(mensaje: 'No se pudo cargar el complejo.'),
        );
      },
      data: (complejo) {
        if (complejo == null) {
          return _buildScaffold(
            context,
            body: _ErrorBody(
                mensaje: 'Este complejo ya no está disponible.'),
          );
        }
        return _ComplejoBody(complejo: complejo);
      },
    );
  }

  /// Scaffold base compartido por loading y error (con back button en AppBar).
  Widget _buildScaffold(BuildContext context, {required Widget body}) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.tx),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: body,
    );
  }
}

// ── Cuerpo principal — un solo Scaffold con CustomScrollView ─────────────────

class _ComplejoBody extends ConsumerWidget {
  final ComplejoModel complejo;
  const _ComplejoBody({required this.complejo});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canchasAsync = ref.watch(canchasProvider(complejo.id));

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: CustomScrollView(
        slivers: [
          // ── Header con imagen ────────────────────────────
          _SliverHeader(complejo: complejo),

          // ── Título sección canchas ───────────────────────
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

          // ── Canchas: loading ─────────────────────────────
          if (canchasAsync.isLoading)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 48),
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.acc),
                ),
              ),
            ),

          // ── Canchas: error ───────────────────────────────
          if (canchasAsync.hasError)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Center(
                  child: Text(
                    'Error cargando canchas',
                    style: GoogleFonts.outfit(color: AppColors.red),
                  ),
                ),
              ),
            ),

          // ── Canchas: vacías ──────────────────────────────
          if (!canchasAsync.isLoading &&
              !canchasAsync.hasError &&
              (canchasAsync.value?.isEmpty ?? true))
            const SliverToBoxAdapter(child: _EmptyStateCanchas()),

          // ── Canchas: lista ───────────────────────────────
          if (!canchasAsync.isLoading &&
              !canchasAsync.hasError &&
              (canchasAsync.value?.isNotEmpty ?? false))
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, i) {
                    final canchas = canchasAsync.value!;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _CanchaCard(
                        cancha: canchas[i],
                        onReservar: () => context.push(
                          '/reservar/${canchas[i].complejoId}/${canchas[i].id}',
                        ),
                      ),
                    );
                  },
                  childCount: canchasAsync.value!.length,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Error body (sin Scaffold propio) ─────────────────────────────────────────

class _ErrorBody extends StatelessWidget {
  final String mensaje;
  const _ErrorBody({required this.mensaje});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded,
                color: AppColors.tx3, size: 48),
            const SizedBox(height: 16),
            Text(
              mensaje,
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(fontSize: 15, color: AppColors.tx2),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.of(context).maybePop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.acc,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: Text('Volver',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Sliver header con imagen y datos del complejo ────────────────────────────

class _SliverHeader extends StatelessWidget {
  final ComplejoModel complejo;
  const _SliverHeader({required this.complejo});

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 240,
      pinned: true,
      backgroundColor: AppColors.bg,
      leading: GestureDetector(
        onTap: () => Navigator.of(context).maybePop(),
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
                    errorBuilder: (context, error, stack) => _placeholderImg(),
                  )
                : _placeholderImg(),
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
                  Row(
                    children: [
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
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.star_rounded,
                          size: 13, color: AppColors.amber),
                      const SizedBox(width: 4),
                      Text(
                        complejo.rating.toStringAsFixed(1),
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
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholderImg() => Container(
        color: AppColors.sur2,
        child: const Center(
          child: Icon(Icons.sports_soccer_rounded,
              color: AppColors.acc, size: 48),
        ),
      );
}

// ── Tarjeta de cancha ────────────────────────────────────────────────────────

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
      child: Row(
        children: [
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
                  '${cancha.deporteLabel} · ${cancha.superficieLabel} · ${cancha.capacidad} jugadores',
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
          ElevatedButton(
            onPressed: onReservar,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.acc,
              foregroundColor: Colors.white,
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
        ],
      ),
    );
  }
}

// ── Empty state ──────────────────────────────────────────────────────────────

class _EmptyStateCanchas extends StatelessWidget {
  const _EmptyStateCanchas();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 60),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              color: AppColors.sur2,
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(Icons.stadium_outlined,
                color: AppColors.tx3, size: 32),
          ),
          const SizedBox(height: 16),
          Text(
            'Sin canchas disponibles',
            style: GoogleFonts.bricolageGrotesque(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.tx,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Este complejo aún no tiene canchas activas.\nVuelve pronto.',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
                fontSize: 13, color: AppColors.tx2, height: 1.5),
          ),
        ],
      ),
    );
  }
}
