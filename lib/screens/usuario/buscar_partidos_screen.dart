// screens/usuario/buscar_partidos_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/app_date_utils.dart';
import '../../models/partido_model.dart';
import '../../providers/partidos_provider.dart';
import '../../widgets/common/empty_state_widget.dart';
import '../../widgets/common/error_widget.dart';
import '../../widgets/common/loading_skeleton.dart';

class BuscarPartidosScreen extends ConsumerWidget {
  const BuscarPartidosScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filtros = ref.watch(filtrosPartidosProvider);
    final partidosAsync = ref.watch(partidosFiltradosProvider);

    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: AppBar(
        backgroundColor: AppColors.paper,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Partidos abiertos',
          style: GoogleFonts.bricolageGrotesque(
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: () => context.push('/crear-partido'),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filtros
          _BarraFiltros(filtros: filtros),

          // Lista
          Expanded(
            child: partidosAsync.when(
              loading: () => ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: 4,
                itemBuilder: (_, __) => const PartidoCardSkeleton(),
              ),
              error: (e, _) => AppErrorWidget(
                mensaje: 'Error cargando partidos',
                onReintentar: () =>
                    ref.invalidate(partidosAbiertosProvider),
              ),
              data: (partidos) {
                if (partidos.isEmpty) {
                  return EmptyStateWidget(
                    titulo: 'No hay partidos abiertos',
                    subtitulo:
                        'Sé el primero en armar uno en Huancayo',
                    emoji: '⚽',
                    accion: ElevatedButton.icon(
                      onPressed: () => context.push('/crear-partido'),
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: const Text('Crear partido'),
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: partidos.length,
                  itemBuilder: (_, i) => _PartidoCard(
                    partido: partidos[i],
                    onTap: () =>
                        context.push('/partido/${partidos[i].id}'),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _BarraFiltros extends ConsumerWidget {
  final FiltrosPartidos filtros;

  const _BarraFiltros({required this.filtros});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deportes = [
      (null, '🏟️', 'Todos'),
      ('futbol5', '⚽', 'F5'),
      ('futbol7', '⚽', 'F7'),
      ('basquet', '🏀', 'Básquet'),
      ('voley', '🏐', 'Voley'),
    ];

    return Container(
      height: 52,
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(bottom: BorderSide(color: AppColors.line)),
      ),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        children: deportes.map((d) {
          final (id, emoji, label) = d;
          final sel = filtros.deporte == id;
          return GestureDetector(
            onTap: () => ref
                .read(filtrosPartidosProvider.notifier)
                .update((f) => f.copyWith(deporte: id)),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8),
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: sel ? AppColors.partyLight : AppColors.paper,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: sel ? AppColors.party : AppColors.line,
                ),
              ),
              child: Row(
                children: [
                  Text(emoji, style: const TextStyle(fontSize: 13)),
                  const SizedBox(width: 4),
                  Text(
                    label,
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: sel ? FontWeight.w600 : FontWeight.w400,
                      color: sel ? AppColors.party : AppColors.ink,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _PartidoCard extends StatelessWidget {
  final PartidoModel partido;
  final VoidCallback onTap;

  const _PartidoCard({required this.partido, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final puestos =
        partido.jugadoresNecesarios - partido.jugadoresActuales;
    final progreso =
        partido.jugadoresActuales / partido.jugadoresNecesarios;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.line),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Emoji deporte
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.partyLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      partido.deporteEmoji,
                      style: const TextStyle(fontSize: 22),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        partido.deporteLabel,
                        style: GoogleFonts.bricolageGrotesque(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink,
                        ),
                      ),
                      Text(
                        '${AppDateUtils.fechaRelativa(partido.fecha)} · ${partido.horaInicio}',
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          color: AppColors.ink.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.partyLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Faltan $puestos',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.party,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'máx S/${partido.precioMaxPorJugador.toStringAsFixed(0)}',
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        color: AppColors.green,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Avatares de jugadores
            Row(
              children: [
                // Avatares apilados
                SizedBox(
                  height: 28,
                  width: (partido.jugadoresActuales * 20 + 8).toDouble().clamp(
                      0, 88),
                  child: Stack(
                    children: partido.jugadores
                        .take(4)
                        .toList()
                        .asMap()
                        .entries
                        .map((e) => Positioned(
                              left: e.key * 20.0,
                              child: Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: AppColors.partyLight,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color: AppColors.white, width: 2),
                                ),
                                child: Center(
                                  child: Text(
                                    e.value.iniciales,
                                    style: GoogleFonts.outfit(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.party,
                                    ),
                                  ),
                                ),
                              ),
                            ))
                        .toList(),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${partido.jugadoresActuales} de ${partido.jugadoresNecesarios}',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    color: AppColors.ink.withValues(alpha: 0.5),
                  ),
                ),
                const Spacer(),
                const Icon(Icons.chevron_right_rounded,
                    color: AppColors.ink, size: 18),
              ],
            ),
            const SizedBox(height: 8),
            // Barra de progreso
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progreso,
                minHeight: 6,
                backgroundColor: AppColors.partyLight,
                color: AppColors.party,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
