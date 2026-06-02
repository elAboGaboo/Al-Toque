// screens/admin/admin_partidos_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../nucleo/tema/app_colores.dart';
import '../../nucleo/utilidades/app_fecha_utilidades.dart';
import '../../modelos/partido_modelo.dart';
import '../../proveedores/auth_proveedor.dart';
import '../../proveedores/partidos_proveedor.dart';
import '../../componentes/comunes/estado_vacio.dart';
import '../../componentes/comunes/widget_error.dart';

class AdminPartidosScreen extends ConsumerWidget {
  const AdminPartidosScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final complejoId =
        ref.watch(complejoIdProvider) ?? 'demo_complejo';
    final partidosAsync =
        ref.watch(partidosComplejoProvider(complejoId));

    return Scaffold(
      backgroundColor: AppColors.adminBg,
      appBar: AppBar(
        backgroundColor: AppColors.adminS1,
        elevation: 0,
        title: Text(
          'Partidos',
          style: GoogleFonts.bricolageGrotesque(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
      body: partidosAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.adminParty),
        ),
        error: (e, _) => AppErrorWidget(
          mensaje: 'Error cargando partidos',
          onReintentar: () =>
              ref.invalidate(partidosComplejoProvider(complejoId)),
        ),
        data: (partidos) {
          if (partidos.isEmpty) {
            return const EmptyStateWidget(
              titulo: 'Sin partidos',
              subtitulo: 'Los partidos organizados en tu complejo aparecerÃ¡n aquÃ­',
              emoji: 'âš½',
            );
          }

          final abiertos = partidos.where((p) => p.estaAbierto).toList();
          final completos =
              partidos.where((p) => p.estaCompleto).toList();
          final otros = partidos
              .where((p) => !p.estaAbierto && !p.estaCompleto)
              .toList();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (abiertos.isNotEmpty) ...[
                _SeccionLabel(
                    label: 'Abiertos (${abiertos.length})',
                    color: AppColors.adminParty),
                ...abiertos.map((p) => _PartidoAdminCard(
                    partido: p,
                    onTap: () => context.go('/partido/${p.id}'))),
              ],
              if (completos.isNotEmpty) ...[
                _SeccionLabel(
                    label: 'Completados (${completos.length})',
                    color: AppColors.adminGreen),
                ...completos.map((p) => _PartidoAdminCard(
                    partido: p,
                    onTap: () => context.go('/partido/${p.id}'))),
              ],
              if (otros.isNotEmpty) ...[
                const _SeccionLabel(
                    label: 'Cancelados/otros', color: Colors.white38),
                ...otros.map((p) => _PartidoAdminCard(
                    partido: p, onTap: () {})),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _SeccionLabel extends StatelessWidget {
  final String label;
  final Color color;

  const _SeccionLabel({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, top: 4),
      child: Text(
        label,
        style: GoogleFonts.outfit(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

class _PartidoAdminCard extends StatelessWidget {
  final PartidoModel partido;
  final VoidCallback onTap;

  const _PartidoAdminCard(
      {required this.partido, required this.onTap});

  @override
  Widget build(BuildContext context) {
    Color borderColor;
    Color estadoColor;
    if (partido.estaAbierto) {
      borderColor = AppColors.adminParty.withValues(alpha: 0.4);
      estadoColor = AppColors.adminParty;
    } else if (partido.estaCompleto) {
      borderColor = AppColors.adminGreen.withValues(alpha: 0.4);
      estadoColor = AppColors.adminGreen;
    } else {
      borderColor = AppColors.adminS3;
      estadoColor = Colors.white38;
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.adminS1,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: estadoColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(partido.deporteEmoji,
                    style: const TextStyle(fontSize: 22)),
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
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    '${AppDateUtils.fechaRelativa(partido.fecha)} Â· ${partido.horaInicio}',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${partido.jugadoresActuales}/${partido.jugadoresNecesarios}',
                  style: GoogleFonts.bricolageGrotesque(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: estadoColor,
                  ),
                ),
                Text(
                  partido.estaAbierto ? 'Abierto' : 'Completo',
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    color: estadoColor.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

