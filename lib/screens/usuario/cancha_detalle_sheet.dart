// screens/usuario/cancha_detalle_sheet.dart
// Bottom sheet que muestra el detalle de un complejo deportivo.
// Se abre desde el mapa al tocar un pin o una card horizontal.
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/geo_utils.dart';
import '../../core/utils/precio_utils.dart';
import '../../models/cancha_model.dart';
import '../../models/complejo_model.dart';
import '../../providers/complejos_provider.dart';
import '../../providers/location_provider.dart';
import '../../widgets/common/error_widget.dart';
import '../../widgets/common/loading_skeleton.dart';

class CanchaDetalleSheet extends ConsumerWidget {
  final ComplejoModel complejo;

  const CanchaDetalleSheet({super.key, required this.complejo});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canchasAsync = ref.watch(canchasProvider(complejo.id));
    final posAsync = ref.watch(ubicacionProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: ListView(
            controller: scrollController,
            padding: EdgeInsets.zero,
            children: [
              // Handle
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 10, bottom: 4),
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.line,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Imagen principal
              if (complejo.imagenes.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.zero,
                  child: CachedNetworkImage(
                    imageUrl: complejo.imagenPrincipal,
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => const SkeletonBox(height: 180),
                    errorWidget: (_, __, ___) => Container(
                      height: 180,
                      color: AppColors.greenLight,
                      child: const Center(
                        child: Icon(Icons.sports_soccer_outlined,
                            size: 48, color: AppColors.green),
                      ),
                    ),
                  ),
                ),

              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                complejo.nombre,
                                style: GoogleFonts.bricolageGrotesque(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.ink,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                complejo.direccion,
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
                            Row(
                              children: [
                                const Icon(Icons.star_rounded,
                                    color: Colors.amber, size: 18),
                                const SizedBox(width: 4),
                                Text(
                                  complejo.rating.toStringAsFixed(1),
                                  style: GoogleFonts.bricolageGrotesque(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.ink,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              '${complejo.totalResenias} reseñas',
                              style: GoogleFonts.outfit(
                                fontSize: 11,
                                color: AppColors.ink.withValues(alpha: 0.4),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Horario + distancia
                    Row(
                      children: [
                        _InfoBadge(
                          icono: '🕐',
                          label:
                              '${complejo.horarioApertura}–${complejo.horarioCierre}',
                        ),
                        const SizedBox(width: 8),
                        posAsync.when(
                          data: (pos) {
                            final dist = GeoUtils.distanciaKm(
                              lat1: pos.latitude,
                              lng1: pos.longitude,
                              lat2: complejo.lat,
                              lng2: complejo.lng,
                            );
                            return _InfoBadge(
                              icono: '📍',
                              label: GeoUtils.formatearDistancia(dist),
                            );
                          },
                          loading: () => const SizedBox.shrink(),
                          error: (_, __) => const SizedBox.shrink(),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),
                    const Divider(),
                    const SizedBox(height: 12),

                    // Título canchas
                    Text(
                      'Canchas disponibles',
                      style: GoogleFonts.bricolageGrotesque(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Lista de canchas
                    canchasAsync.when(
                      loading: () => const ReservaListSkeleton(),
                      error: (e, _) => AppErrorWidget(
                        mensaje: 'Error cargando canchas',
                        onReintentar: () =>
                            ref.invalidate(canchasProvider(complejo.id)),
                      ),
                      data: (canchas) {
                        if (canchas.isEmpty) {
                          return Center(
                            child: Text(
                              'Sin canchas activas',
                              style: GoogleFonts.outfit(
                                color: AppColors.ink.withValues(alpha: 0.4),
                              ),
                            ),
                          );
                        }
                        return Column(
                          children: canchas
                              .map((c) => _CanchaItem(
                                    cancha: c,
                                    onReservar: () {
                                      Navigator.pop(context);
                                      context.push(
                                          '/reservar/${complejo.id}/${c.id}');
                                    },
                                  ))
                              .toList(),
                        );
                      },
                    ),

                    const SizedBox(height: 16),

                    // Botón Google Maps
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => _abrirMaps(complejo),
                        icon: const Icon(Icons.directions_rounded,
                            size: 18),
                        label: const Text('Cómo llegar'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.green,
                          side: const BorderSide(color: AppColors.green),
                        ),
                      ),
                    ),
                    SizedBox(
                        height: MediaQuery.of(context).padding.bottom + 16),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _abrirMaps(ComplejoModel c) async {
    final url = Uri.parse(
        'https://www.google.com/maps/dir/?api=1&destination=${c.lat},${c.lng}');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }
}

class _InfoBadge extends StatelessWidget {
  final String icono;
  final String label;

  const _InfoBadge({required this.icono, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.greenLight,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Text(icono, style: const TextStyle(fontSize: 13)),
          const SizedBox(width: 5),
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.green,
            ),
          ),
        ],
      ),
    );
  }
}

class _CanchaItem extends StatelessWidget {
  final CanchaModel cancha;
  final VoidCallback onReservar;

  const _CanchaItem({required this.cancha, required this.onReservar});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        children: [
          Text(cancha.deporteEmoji,
              style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  cancha.nombre,
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink,
                  ),
                ),
                Text(
                  '${cancha.deporteLabel} · ${cancha.superficieLabel}',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    color: AppColors.ink.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                PrecioUtils.formatear(cancha.precioBase),
                style: GoogleFonts.bricolageGrotesque(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.green,
                ),
              ),
              Text(
                '/hora',
                style: GoogleFonts.outfit(
                  fontSize: 10,
                  color: AppColors.ink.withValues(alpha: 0.4),
                ),
              ),
            ],
          ),
          const SizedBox(width: 10),
          ElevatedButton(
            onPressed: onReservar,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.green,
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 8),
              minimumSize: const Size(0, 36),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              textStyle: GoogleFonts.outfit(
                  fontSize: 13, fontWeight: FontWeight.w600),
            ),
            child: const Text('Reservar'),
          ),
        ],
      ),
    );
  }
}
