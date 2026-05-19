// screens/admin/admin_flash_slots_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/app_date_utils.dart';
import '../../core/utils/precio_utils.dart';
import '../../models/flash_slot_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/flash_slots_provider.dart';
import '../../widgets/common/empty_state_widget.dart';
import '../../widgets/common/error_widget.dart';

class AdminFlashSlotsScreen extends ConsumerWidget {
  const AdminFlashSlotsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final complejoId =
        ref.watch(complejoIdProvider) ?? 'demo_complejo';
    final slotsAsync =
        ref.watch(flashSlotsComplejoProvider(complejoId));
    return Scaffold(
      backgroundColor: AppColors.adminBg,
      appBar: AppBar(
        backgroundColor: AppColors.adminS1,
        elevation: 0,
        title: Text(
          'Flash Slots',
          style: GoogleFonts.bricolageGrotesque(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.adminFlash,
        onPressed: () => _mostrarCrearSlot(context, ref, complejoId),
        icon: const Icon(Icons.flash_on_rounded, color: Colors.white),
        label: Text(
          'Nuevo Flash',
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: slotsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.adminFlash),
        ),
        error: (e, _) => AppErrorWidget(
          mensaje: 'Error cargando flash slots',
          onReintentar: () =>
              ref.invalidate(flashSlotsComplejoProvider(complejoId)),
        ),
        data: (slots) {
          if (slots.isEmpty) {
            return const EmptyStateWidget(
              titulo: 'Sin flash slots',
              subtitulo:
                  'Crea un flash slot para llenar canchas vacías con descuento automático',
              emoji: '⚡',
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            itemCount: slots.length,
            itemBuilder: (_, i) => _FlashSlotAdminCard(slot: slots[i]),
          );
        },
      ),
    );
  }

  void _mostrarCrearSlot(
      BuildContext context, WidgetRef ref, String complejoId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CrearFlashSlotSheet(
        complejoId: complejoId,
        ref: ref,
      ),
    );
  }
}

class _FlashSlotAdminCard extends StatelessWidget {
  final FlashSlotModel slot;

  const _FlashSlotAdminCard({required this.slot});

  @override
  Widget build(BuildContext context) {
    final estado = slot.estado;
    final isActivo = estado == 'activo' && !slot.expiraEn.isBefore(DateTime.now());

    Color statusColor;
    String statusLabel;
    if (isActivo) {
      statusColor = AppColors.adminFlash;
      statusLabel = 'Activo';
    } else if (estado == 'reservado') {
      statusColor = AppColors.adminGreen;
      statusLabel = 'Reservado ✓';
    } else {
      statusColor = Colors.white38;
      statusLabel = 'Expirado';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.adminS1,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActivo
              ? AppColors.adminFlash.withValues(alpha: 0.4)
              : AppColors.adminS3,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    if (isActivo)
                      const Text('⚡', style: TextStyle(fontSize: 12)),
                    const SizedBox(width: 4),
                    Text(
                      statusLabel,
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              if (isActivo)
                Text(
                  'Expira: ${AppDateUtils.formatearHora(slot.expiraEn)}',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.4),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${slot.horaInicio} – ${slot.horaFin}',
                      style: GoogleFonts.bricolageGrotesque(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      AppDateUtils.fechaRelativa(slot.fecha),
                      style: GoogleFonts.outfit(
                        fontSize: 13,
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
                    PrecioUtils.formatear(slot.precioFlash),
                    style: GoogleFonts.bricolageGrotesque(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppColors.adminFlash,
                    ),
                  ),
                  Text(
                    '${slot.descuentoPct}% descuento',
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      color: AppColors.adminFlash.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Vistas
          Row(
            children: [
              const Icon(Icons.visibility_outlined,
                  size: 14, color: Colors.white38),
              const SizedBox(width: 4),
              Text(
                '${slot.vistasCount} vistas',
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  color: Colors.white38,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Creado: ${slot.creadoPor == 'ia_automatico' ? '🤖 IA' : '👤 Admin'}',
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  color: Colors.white38,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CrearFlashSlotSheet extends StatefulWidget {
  final String complejoId;
  final WidgetRef ref;

  const _CrearFlashSlotSheet(
      {required this.complejoId, required this.ref});

  @override
  State<_CrearFlashSlotSheet> createState() =>
      _CrearFlashSlotSheetState();
}

class _CrearFlashSlotSheetState extends State<_CrearFlashSlotSheet> {
  final String _horaInicio = '19:00';
  final String _horaFin = '20:00';
  double _descuento = 25;
  double _precioOriginal = 80;
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: BoxDecoration(
        color: AppColors.adminS1,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('⚡', style: TextStyle(fontSize: 22)),
              const SizedBox(width: 8),
              Text(
                'Crear Flash Slot',
                style: GoogleFonts.bricolageGrotesque(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            'Precio original: ${PrecioUtils.formatear(_precioOriginal)}',
            style: GoogleFonts.outfit(color: Colors.white70),
          ),
          Slider(
            value: _precioOriginal,
            min: 40,
            max: 200,
            activeColor: AppColors.adminFlash,
            inactiveColor: AppColors.adminS3,
            onChanged: (v) => setState(() => _precioOriginal = v),
          ),
          const SizedBox(height: 8),
          Text(
            'Descuento: ${_descuento.toInt()}%',
            style: GoogleFonts.outfit(color: Colors.white70),
          ),
          Slider(
            value: _descuento,
            min: 10,
            max: 50,
            divisions: 8,
            activeColor: AppColors.adminFlash,
            inactiveColor: AppColors.adminS3,
            onChanged: (v) => setState(() => _descuento = v),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                'Precio flash: ',
                style: GoogleFonts.outfit(color: Colors.white70),
              ),
              Text(
                PrecioUtils.formatear(
                    _precioOriginal * (1 - _descuento / 100)),
                style: GoogleFonts.bricolageGrotesque(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.adminFlash,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.adminFlash,
              ),
              onPressed: _loading ? null : _crear,
              child: _loading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text(
                      'Publicar Flash Slot',
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _crear() async {
    setState(() => _loading = true);
    final slot = FlashSlotModel(
      id: '',
      complejoId: widget.complejoId,
      canchaId: 'cancha_1', // simplificado
      fecha: DateTime.now(),
      horaInicio: _horaInicio,
      horaFin: _horaFin,
      precioOriginal: _precioOriginal,
      precioFlash: _precioOriginal * (1 - _descuento / 100),
      descuentoPct: _descuento.toInt(),
      expiraEn: DateTime.now().add(const Duration(hours: 2)),
      estado: 'activo',
      vistasCount: 0,
      creadoPor: 'admin',
      creadoEn: DateTime.now(),
    );
    await widget.ref
        .read(flashSlotNotifierProvider.notifier)
        .crearSlot(slot);
    if (mounted) Navigator.pop(context);
  }
}

