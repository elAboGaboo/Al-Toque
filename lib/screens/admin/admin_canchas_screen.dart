// screens/admin/admin_canchas_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_colors.dart';
import '../../models/cancha_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/complejos_provider.dart';
import '../../repositories/complejos_repository.dart';
import 'admin_agregar_cancha_screen.dart';

class AdminCanchasScreen extends ConsumerWidget {
  const AdminCanchasScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final complejoId = ref.watch(complejoIdProvider);

    if (complejoId == null) {
      return Scaffold(
        backgroundColor: AppColors.abg,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.warning_amber_rounded,
                    color: AppColors.aamber, size: 48),
                const SizedBox(height: 16),
                Text(
                  'Primero configura tu complejo',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.bricolageGrotesque(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.atx,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Ve al Dashboard y completa el setup de tu complejo antes de agregar canchas.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                      fontSize: 13, color: AppColors.atx2),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.aacc,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('Volver',
                      style: GoogleFonts.outfit(
                          fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final canchasAsync = ref.watch(canchasAdminProvider(complejoId));

    return Scaffold(
      backgroundColor: AppColors.abg,
      body: SafeArea(
        child: Column(
          children: [
            // ── Top bar ──────────────────────────────────
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: AppColors.asur,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.abdr),
                      ),
                      child: const Icon(Icons.arrow_back_rounded,
                          color: AppColors.atx, size: 18),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Mis Canchas',
                          style: GoogleFonts.bricolageGrotesque(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.atx,
                            letterSpacing: -0.4,
                          ),
                        ),
                        canchasAsync.when(
                          data: (list) => Text(
                            '${list.length} cancha${list.length != 1 ? "s" : ""}',
                            style: GoogleFonts.outfit(
                                fontSize: 12, color: AppColors.atx2),
                          ),
                          loading: () => const SizedBox.shrink(),
                          error: (_, _) => const SizedBox.shrink(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── Lista ─────────────────────────────────────
            Expanded(
              child: canchasAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(color: AppColors.aacc),
                ),
                error: (e, _) => Center(
                  child: Text('Error: $e',
                      style: GoogleFonts.outfit(color: AppColors.ared)),
                ),
                data: (canchas) {
                  if (canchas.isEmpty) {
                    return _EmptyState(
                      onAgregar: () =>
                          _mostrarFormCancha(context, complejoId),
                    );
                  }
                  return ListView.separated(
                    padding:
                        const EdgeInsets.fromLTRB(20, 8, 20, 100),
                    itemCount: canchas.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: 10),
                    itemBuilder: (_, i) => _CanchaCard(
                      cancha: canchas[i],
                      complejoId: complejoId,
                      onEditar: () => _mostrarFormCancha(
                          context, complejoId,
                          cancha: canchas[i]),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),

      // ── FAB ───────────────────────────────────────────
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.aacc,
        foregroundColor: Colors.black,
        elevation: 4,
        icon: const Icon(Icons.add_rounded),
        label: Text(
          'Agregar cancha',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
        ),
        onPressed: () => _mostrarFormCancha(context, complejoId),
      ),
    );
  }

  void _mostrarFormCancha(BuildContext context, String complejoId,
      {CanchaModel? cancha}) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => AdminAgregarCanchaScreen(
        complejoId: complejoId,
        canchaExistente: cancha,
      ),
    ));
  }
}

// ── Empty state ─────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final VoidCallback onAgregar;
  const _EmptyState({required this.onAgregar});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.asur,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.abdr2),
              ),
              child: const Icon(Icons.stadium_outlined,
                  color: AppColors.atx3, size: 36),
            ),
            const SizedBox(height: 16),
            Text(
              'Sin canchas todavía',
              style: GoogleFonts.bricolageGrotesque(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.atx,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Agrega tu primera cancha para que los jugadores puedan reservar.',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                  fontSize: 13, color: AppColors.atx2, height: 1.5),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.aacc,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              icon: const Icon(Icons.add_rounded),
              label: Text('Agregar cancha',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
              onPressed: onAgregar,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Tarjeta cancha ───────────────────────────────────────────────

class _CanchaCard extends ConsumerWidget {
  final CanchaModel cancha;
  final String complejoId;
  final VoidCallback onEditar;

  const _CanchaCard({
    required this.cancha,
    required this.complejoId,
    required this.onEditar,
  });

  Future<void> _confirmarEliminar(
      BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.asur,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: Text('Eliminar cancha',
            style: GoogleFonts.bricolageGrotesque(
                fontWeight: FontWeight.w700, color: AppColors.atx)),
        content: Text(
            '¿Eliminar "${cancha.nombre}"? Esta acción no se puede deshacer.',
            style: GoogleFonts.outfit(
                fontSize: 13, color: AppColors.atx2)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('Cancelar',
                style: GoogleFonts.outfit(color: AppColors.atx2)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text('Eliminar',
                style: GoogleFonts.outfit(
                    color: AppColors.ared,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
    if (ok == true) {
      await ComplejosRepository()
          .eliminarCancha(complejoId, cancha.id);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.asur,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: cancha.activa ? AppColors.abdr2 : AppColors.abdr,
        ),
      ),
      child: Row(
        children: [
          // Icono deporte
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: cancha.activa
                  ? AppColors.aaccD
                  : AppColors.asur2,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(cancha.deporteEmoji,
                  style: const TextStyle(fontSize: 22)),
            ),
          ),
          const SizedBox(width: 12),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        cancha.nombre,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: cancha.activa
                              ? AppColors.atx
                              : AppColors.atx3,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    if (!cancha.activa)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.ared.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'INACTIVA',
                          style: GoogleFonts.outfit(
                            fontSize: 8,
                            fontWeight: FontWeight.w700,
                            color: AppColors.ared,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  '${cancha.deporteLabel} · ${cancha.superficieLabel} · S/ ${cancha.precioBase.toStringAsFixed(0)}/hr',
                  style: GoogleFonts.outfit(
                      fontSize: 11, color: AppColors.atx2),
                ),
              ],
            ),
          ),

          // Acciones
          Column(
            children: [
              // Toggle activa
              GestureDetector(
                onTap: () => ComplejosRepository().toggleCanchaActiva(
                    complejoId, cancha.id, !cancha.activa),
                child: Container(
                  width: 36,
                  height: 20,
                  decoration: BoxDecoration(
                    color: cancha.activa
                        ? AppColors.aacc
                        : AppColors.asur3,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: AnimatedAlign(
                    duration: const Duration(milliseconds: 200),
                    alignment: cancha.activa
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: Container(
                      width: 16,
                      height: 16,
                      margin:
                          const EdgeInsets.symmetric(horizontal: 2),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  GestureDetector(
                    onTap: onEditar,
                    child: const Icon(Icons.edit_outlined,
                        color: AppColors.atx3, size: 18),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: () => _confirmarEliminar(context, ref),
                    child: const Icon(Icons.delete_outline_rounded,
                        color: AppColors.ared, size: 18),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}


