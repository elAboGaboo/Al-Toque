// screens/usuario/partido_live_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/services/deep_link_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/app_date_utils.dart';
import '../../models/partido_model.dart';
import '../../providers/partidos_provider.dart';
import '../../widgets/common/error_widget.dart';
class PartidoLiveScreen extends ConsumerWidget {
  final String partidoId;

  const PartidoLiveScreen({super.key, required this.partidoId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final partidoAsync = ref.watch(partidoProvider(partidoId));

    return Scaffold(
      backgroundColor: AppColors.paper,
      body: partidoAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.party),
        ),
        error: (e, _) => AppErrorWidget(
          mensaje: 'No se pudo cargar el partido',
          onReintentar: () =>
              ref.invalidate(partidoProvider(partidoId)),
        ),
        data: (partido) {
          if (partido == null) {
            return const AppErrorWidget(
                mensaje: 'Partido no encontrado');
          }

          // Si el partido se completó, navegar a completado
          if (partido.estaCompleto) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              context.pushReplacement('/partido/$partidoId/completado');
            });
          }

          return _buildContenido(context, ref, partido);
        },
      ),
    );
  }

  Widget _buildContenido(
      BuildContext context, WidgetRef ref, PartidoModel partido) {
    final puestos = partido.jugadoresNecesarios - partido.jugadoresActuales;

    return CustomScrollView(
      slivers: [
        // App bar con gradiente azul
        SliverAppBar(
          expandedHeight: 200,
          backgroundColor: AppColors.party,
          pinned: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
            onPressed: () => context.pop(),
          ),
          actions: [
            IconButton(
              icon:
                  const Icon(Icons.share_rounded, color: Colors.white),
              onPressed: () {
                final link = DeepLinkService.generarLinkPartido(partidoId);
                Share.share(
                  '¡Únete a mi partido de ${partido.deporteLabel} en Huancayo!\n'
                  '${AppDateUtils.fechaRelativa(partido.fecha)} · ${partido.horaInicio}\n'
                  'Quedan $puestos puestos\n$link',
                );
              },
            ),
          ],
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.party, AppColors.party2],
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 60, 24, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        partido.deporteEmoji,
                        style: const TextStyle(fontSize: 36),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Partido de ${partido.deporteLabel}',
                        style: GoogleFonts.bricolageGrotesque(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        '${AppDateUtils.fechaRelativa(partido.fecha)} · ${partido.horaInicio}',
                        style: GoogleFonts.outfit(
                          fontSize: 15,
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),

        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Progreso de jugadores
                _ProgresoJugadores(partido: partido),
                const SizedBox(height: 20),

                // Aviso de cancha automática
                if (partido.complejoId == null)
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.partyLight,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: AppColors.party.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Text('🤖', style: TextStyle(fontSize: 20)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Cuando el partido se llene, la IA reservará automáticamente la mejor cancha disponible.',
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              color: AppColors.party,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 20),

                // Lista de jugadores
                Text(
                  'Jugadores (${partido.jugadoresActuales}/${partido.jugadoresNecesarios})',
                  style: GoogleFonts.bricolageGrotesque(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 12),
                ...partido.jugadores
                    .map((j) => _JugadorTile(
                          jugador: j,
                          esOrganizador:
                              j.userId == partido.organizadorId,
                        )),

                // Slots vacíos
                ...List.generate(
                  puestos,
                  (i) => _SlotVacio(numero: partido.jugadoresActuales + i + 1),
                ),
                const SizedBox(height: 24),

                // Info precio
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.line),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Text(
                            '💰',
                            style: TextStyle(fontSize: 18),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Precio estimado por jugador',
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              color: AppColors.ink.withValues(alpha: 0.6),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            'máx S/${partido.precioMaxPorJugador.toStringAsFixed(0)}',
                            style: GoogleFonts.bricolageGrotesque(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.green,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ── Sub-widgets ──────────────────────────────────────────────

class _ProgresoJugadores extends StatelessWidget {
  final PartidoModel partido;

  const _ProgresoJugadores({required this.partido});

  @override
  Widget build(BuildContext context) {
    final progreso =
        partido.jugadoresActuales / partido.jugadoresNecesarios;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              '${partido.jugadoresActuales}',
              style: GoogleFonts.bricolageGrotesque(
                fontSize: 40,
                fontWeight: FontWeight.w800,
                color: AppColors.party,
              ),
            ),
            Text(
              '/${partido.jugadoresNecesarios}',
              style: GoogleFonts.bricolageGrotesque(
                fontSize: 24,
                fontWeight: FontWeight.w400,
                color: AppColors.ink.withValues(alpha: 0.3),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'jugadores',
              style: GoogleFonts.outfit(
                fontSize: 14,
                color: AppColors.ink.withValues(alpha: 0.5),
              ),
            ),
            const Spacer(),
            if (partido.jugadoresNecesarios - partido.jugadoresActuales > 0)
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.partyLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Faltan ${partido.jugadoresNecesarios - partido.jugadoresActuales}',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.party,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: progreso,
            minHeight: 12,
            backgroundColor: AppColors.partyLight,
            color: AppColors.party,
          ),
        ),
      ],
    );
  }
}

class _JugadorTile extends StatelessWidget {
  final JugadorPartido jugador;
  final bool esOrganizador;

  const _JugadorTile(
      {required this.jugador, required this.esOrganizador});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.partyLight,
              shape: BoxShape.circle,
              border: esOrganizador
                  ? Border.all(color: AppColors.party, width: 2)
                  : null,
            ),
            child: Center(
              child: Text(
                jugador.iniciales,
                style: GoogleFonts.bricolageGrotesque(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.party,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      jugador.nombre,
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.ink,
                      ),
                    ),
                    if (esOrganizador) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.partyLight,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Organizador',
                          style: GoogleFonts.outfit(
                            fontSize: 10,
                            color: AppColors.party,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                Text(
                  'Se unió ${AppDateUtils.fechaRelativa(jugador.unidoEn)}',
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    color: AppColors.ink.withValues(alpha: 0.4),
                  ),
                ),
              ],
            ),
          ),
          Icon(
            jugador.pagado
                ? Icons.check_circle_rounded
                : Icons.radio_button_unchecked_rounded,
            color: jugador.pagado ? AppColors.green : AppColors.line,
            size: 20,
          ),
        ],
      ),
    );
  }
}

class _SlotVacio extends StatelessWidget {
  final int numero;

  const _SlotVacio({required this.numero});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.line.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.line,
          style: BorderStyle.solid,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.line.withValues(alpha: 0.5),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$numero',
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  color: AppColors.ink.withValues(alpha: 0.3),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'Lugar disponible',
            style: GoogleFonts.outfit(
              fontSize: 14,
              color: AppColors.ink.withValues(alpha: 0.3),
            ),
          ),
          const Spacer(),
          Icon(
            Icons.add_circle_outline_rounded,
            color: AppColors.party.withValues(alpha: 0.4),
            size: 20,
          ),
        ],
      ),
    );
  }
}
