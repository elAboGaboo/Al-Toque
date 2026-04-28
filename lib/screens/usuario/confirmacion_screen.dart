// screens/usuario/confirmacion_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/app_date_utils.dart';
import '../../core/utils/precio_utils.dart';
import '../../providers/reservas_provider.dart';
import '../../widgets/common/error_widget.dart';

class ConfirmacionScreen extends ConsumerWidget {
  final String reservaId;

  const ConfirmacionScreen({super.key, required this.reservaId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reservaAsync = ref.watch(reservaProvider(reservaId));

    return Scaffold(
      backgroundColor: AppColors.paper,
      body: reservaAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.green),
        ),
        error: (e, _) => AppErrorWidget(
          mensaje: 'No se pudo cargar la confirmación',
          onReintentar: () => ref.invalidate(reservaProvider(reservaId)),
        ),
        data: (reserva) {
          if (reserva == null) {
            return const AppErrorWidget(mensaje: 'Reserva no encontrada');
          }
          return _buildContent(context, ref, reserva);
        },
      ),
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref, reserva) {
    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          children: [
            // Header verde de confirmación
            Container(
              width: double.infinity,
              color: AppColors.green,
              padding: const EdgeInsets.fromLTRB(24, 40, 24, 40),
              child: Column(
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_circle_outline_rounded,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '¡Reserva confirmada!',
                    style: GoogleFonts.bricolageGrotesque(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Muestra este código QR al llegar',
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),

            // Código QR
            Container(
              color: AppColors.white,
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.line, width: 2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: QrImageView(
                      data: reserva.codigoAcceso,
                      version: QrVersions.auto,
                      size: 200,
                      eyeStyle: const QrEyeStyle(
                        eyeShape: QrEyeShape.square,
                        color: AppColors.ink,
                      ),
                      dataModuleStyle: const QrDataModuleStyle(
                        dataModuleShape: QrDataModuleShape.square,
                        color: AppColors.ink,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    reserva.codigoAcceso.substring(0, 8).toUpperCase(),
                    style: GoogleFonts.bricolageGrotesque(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 4,
                      color: AppColors.ink.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ),

            // Detalles de la reserva
            Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.line),
                ),
                child: Column(
                  children: [
                    _DetalleRow(
                      icono: '📅',
                      label: 'Fecha',
                      valor: AppDateUtils.fechaRelativa(reserva.fecha),
                    ),
                    const SizedBox(height: 12),
                    _DetalleRow(
                      icono: '🕐',
                      label: 'Horario',
                      valor:
                          '${reserva.horaInicio} – ${reserva.horaFin}',
                    ),
                    const SizedBox(height: 12),
                    _DetalleRow(
                      icono: '⏱️',
                      label: 'Duración',
                      valor:
                          '${reserva.duracionHoras.toInt()} hora${reserva.duracionHoras > 1 ? 's' : ''}',
                    ),
                    const Divider(height: 24),
                    _DetalleRow(
                      icono: '💰',
                      label: 'Total pagado',
                      valor: PrecioUtils.formatear(reserva.precioTotal),
                      valorColor: AppColors.green,
                      negrita: true,
                    ),
                    const SizedBox(height: 12),
                    _DetalleRow(
                      icono: '💳',
                      label: 'Método',
                      valor: _nombreMetodoPago(reserva.metodoPago),
                    ),
                  ],
                ),
              ),
            ),

            // Tip
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.greenLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: AppColors.green.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Text('💡', style: TextStyle(fontSize: 18)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Llega 10 minutos antes. El QR es válido solo para esta reserva.',
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          color: AppColors.green,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Botones de acción
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Share.share(
                          '¡Reservé una cancha en CanchApp!\n'
                          'Código: ${reserva.codigoAcceso.substring(0, 8).toUpperCase()}\n'
                          'Horario: ${reserva.horaInicio} – ${reserva.horaFin}',
                        );
                      },
                      icon: const Icon(Icons.share_rounded, size: 18),
                      label: Text(
                        'Compartir reserva',
                        style: GoogleFonts.outfit(
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => context.go('/mapa'),
                      child: Text(
                        'Volver al mapa',
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  String _nombreMetodoPago(String metodo) {
    const nombres = {
      'yape': 'Yape 💜',
      'plin': 'Plin 💙',
      'tarjeta': 'Tarjeta de crédito/débito',
      'efectivo': 'Efectivo',
    };
    return nombres[metodo] ?? metodo;
  }
}

class _DetalleRow extends StatelessWidget {
  final String icono;
  final String label;
  final String valor;
  final Color? valorColor;
  final bool negrita;

  const _DetalleRow({
    required this.icono,
    required this.label,
    required this.valor,
    this.valorColor,
    this.negrita = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(icono, style: const TextStyle(fontSize: 16)),
        const SizedBox(width: 10),
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 14,
            color: AppColors.ink.withValues(alpha: 0.5),
          ),
        ),
        const Spacer(),
        Text(
          valor,
          style: GoogleFonts.outfit(
            fontSize: 14,
            fontWeight: negrita ? FontWeight.w700 : FontWeight.w500,
            color: valorColor ?? AppColors.ink,
          ),
        ),
      ],
    );
  }
}
