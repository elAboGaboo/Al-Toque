// DEAD CODE — Widget no importado en ninguna pantalla activa.
// Puede eliminarse sin afectar el proyecto.
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../models/complejo_model.dart';
import '../../../models/prediccion_ia_model.dart';

class CanchaCardHorizontal extends StatelessWidget {
  final ComplejoModel complejo;
  final double distanciaKm;
  final PrediccionIAModel? prediccion;
  final VoidCallback onTap;

  const CanchaCardHorizontal({
    super.key,
    required this.complejo,
    required this.distanciaKm,
    this.prediccion,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hora = '${DateTime.now().hour.toString().padLeft(2, '0')}:00';
    final multiplicador = prediccion?.multiplicadorParaHora(hora) ?? 1.0;
    final nivelDemanda = prediccion?.nivelDemandaActual();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 200,
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.line),
          boxShadow: [
            BoxShadow(
              color: AppColors.ink.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Imagen
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
              child: complejo.imagenPrincipal.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: complejo.imagenPrincipal,
                      height: 110,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorWidget: (context, url, error) => _imagenPlaceholder(),
                    )
                  : _imagenPlaceholder(),
            ),

            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    complejo.nombre,
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.ink,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.location_on_rounded,
                          size: 11, color: AppColors.ink.withValues(alpha: 0.45)),
                      const SizedBox(width: 2),
                      Text(
                        '${distanciaKm.toStringAsFixed(1)} km',
                        style: GoogleFonts.outfit(
                            fontSize: 11,
                            color: AppColors.ink.withValues(alpha: 0.55)),
                      ),
                      const SizedBox(width: 6),
                      const Icon(Icons.star_rounded,
                          size: 11, color: AppColors.flashPin),
                      const SizedBox(width: 2),
                      Text(
                        complejo.ciudad,
                        style: GoogleFonts.outfit(
                            fontSize: 11,
                            color: AppColors.ink.withValues(alpha: 0.55)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Desde S/${(40 * multiplicador).toStringAsFixed(0)}',
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.green,
                            ),
                          ),
                          if (nivelDemanda != null)
                            Text(
                              '${nivelDemanda.emoji} ${nivelDemanda.label}',
                              style: GoogleFonts.outfit(
                                fontSize: 10,
                                color: _colorDemanda(nivelDemanda),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppColors.green,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Reservar',
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
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

  Widget _imagenPlaceholder() => Container(
        height: 110,
        color: AppColors.line,
        child: const Center(
          child: Icon(Icons.sports_soccer_rounded,
              color: AppColors.green, size: 32),
        ),
      );

  Color _colorDemanda(DemandaNivel nivel) => switch (nivel) {
        DemandaNivel.baja => AppColors.demandLow,
        DemandaNivel.media => AppColors.demandMed,
        DemandaNivel.alta => AppColors.demandHigh,
      };
}
