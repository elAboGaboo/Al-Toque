// screens/usuario/partido_completado_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/app_date_utils.dart';
import '../../core/utils/precio_utils.dart';
import '../../models/partido_model.dart';
import '../../providers/partidos_provider.dart';
import '../../widgets/common/error_widget.dart';

class PartidoCompletadoScreen extends ConsumerWidget {
  final String partidoId;

  const PartidoCompletadoScreen({super.key, required this.partidoId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final partidoAsync = ref.watch(partidoProvider(partidoId));

    return Scaffold(
      backgroundColor: AppColors.paper,
      body: partidoAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.party),
        ),
        error: (e, _) =>
            const AppErrorWidget(mensaje: 'No se pudo cargar el partido'),
        data: (partido) {
          if (partido == null) {
            return const AppErrorWidget(mensaje: 'Partido no encontrado');
          }
          return _buildContent(context, partido);
        },
      ),
    );
  }

  Widget _buildContent(BuildContext context, PartidoModel partido) {
    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          children: [
            // Header azul victoria
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.party, AppColors.party2],
                ),
              ),
              padding: const EdgeInsets.fromLTRB(24, 48, 24, 40),
              child: Column(
                children: [
                  const Text('🎉', style: TextStyle(fontSize: 52)),
                  const SizedBox(height: 16),
                  Text(
                    '¡Partido completado!',
                    style: GoogleFonts.bricolageGrotesque(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'La cancha fue reservada automáticamente',
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            // Detalles del partido
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Info cancha (si ya está asignada)
                  if (partido.complejoId != null)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.greenLight,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: AppColors.green.withValues(alpha: 0.4)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.sports_soccer_rounded,
                                  color: AppColors.green, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'Cancha reservada ✅',
                                style: GoogleFonts.outfit(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.green,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _InfoRow(
                              label: 'Fecha',
                              valor: AppDateUtils.fechaRelativa(
                                  partido.fecha)),
                          _InfoRow(
                              label: 'Horario',
                              valor:
                                  '${partido.horaInicio} – ${partido.horaFin}'),
                          if (partido.precioFinalPorJugador != null)
                            _InfoRow(
                              label: 'Tu parte',
                              valor: PrecioUtils.formatear(
                                  partido.precioFinalPorJugador!),
                              valorColor: AppColors.green,
                            ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 20),

                  // Lista de jugadores
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.line),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${partido.deporteEmoji} Tu equipo',
                          style: GoogleFonts.bricolageGrotesque(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.ink,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: partido.jugadores
                              .map((j) => _AvatarJugador(jugador: j))
                              .toList(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Tip IA
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.partyLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Text('🤖', style: TextStyle(fontSize: 20)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'La IA seleccionó la mejor cancha disponible para el precio acordado. ¡Disfruta el partido!',
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
                  const SizedBox(height: 24),

                  // Botón volver al mapa
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.party,
                      ),
                      onPressed: () => context.go('/mapa'),
                      child: Text(
                        'Volver al mapa',
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String valor;
  final Color? valorColor;

  const _InfoRow(
      {required this.label, required this.valor, this.valorColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 13,
              color: AppColors.ink.withValues(alpha: 0.5),
            ),
          ),
          const Spacer(),
          Text(
            valor,
            style: GoogleFonts.outfit(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: valorColor ?? AppColors.ink,
            ),
          ),
        ],
      ),
    );
  }
}

class _AvatarJugador extends StatelessWidget {
  final JugadorPartido jugador;

  const _AvatarJugador({required this.jugador});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.partyLight,
            shape: BoxShape.circle,
            border: Border.all(
                color: AppColors.party.withValues(alpha: 0.3), width: 2),
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
        const SizedBox(height: 4),
        Text(
          jugador.nombre.split(' ').first,
          style: GoogleFonts.outfit(
            fontSize: 10,
            color: AppColors.ink.withValues(alpha: 0.5),
          ),
        ),
      ],
    );
  }
}
