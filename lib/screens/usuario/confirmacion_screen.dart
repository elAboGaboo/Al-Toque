// screens/usuario/confirmacion_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/app_date_utils.dart';
import '../../models/reserva_model.dart';
import '../../providers/complejos_provider.dart';
import '../../providers/reservas_provider.dart';

class ConfirmacionScreen extends ConsumerWidget {
  final String reservaId;

  const ConfirmacionScreen({super.key, required this.reservaId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reservaAsync = ref.watch(reservaProvider(reservaId));

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: reservaAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text('Error cargando reserva: $e',
              style: GoogleFonts.plusJakartaSans(color: AppColors.tx3)),
        ),
        data: (reserva) {
          if (reserva == null) {
            return Center(
              child: Text('Reserva no encontrada',
                  style:
                      GoogleFonts.plusJakartaSans(color: AppColors.tx3)),
            );
          }
          return _ConfirmacionContenido(reserva: reserva);
        },
      ),
    );
  }
}

class _ConfirmacionContenido extends ConsumerWidget {
  final ReservaModel reserva;

  const _ConfirmacionContenido({required this.reserva});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canchaAsync = ref.watch(
      canchaFutureProvider((
        complejoId: reserva.complejoId,
        canchaId: reserva.canchaId,
      )),
    );
    final complejoAsync =
        ref.watch(complejoFutureProvider(reserva.complejoId));

    final canchaName = canchaAsync.asData?.value?.nombre ?? '…';
    final complejoName = complejoAsync.asData?.value?.nombre ?? '…';

    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 40),

            // ── Check animado ─────────────────────────────
            const _SuccessCheck(),
            const SizedBox(height: 24),

            Text(
              '¡Reserva Confirmada!',
              style: GoogleFonts.bricolageGrotesque(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: AppColors.tx,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tu cancha te espera en $complejoName',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                color: AppColors.tx3,
                fontWeight: FontWeight.w300,
              ),
            ),

            const SizedBox(height: 40),

            // ── Ticket card ───────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: _TicketCard(
                reserva: reserva,
                canchaName: canchaName,
                complejoName: complejoName,
              ),
            ),

            const SizedBox(height: 32),

            // ── Acciones ──────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => context.go('/inicio'),
                      child: const Text('Volver al Inicio'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => context.go('/mapa'),
                      child: const Text('Ver en Mapa'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class _TicketCard extends StatelessWidget {
  final ReservaModel reserva;
  final String canchaName;
  final String complejoName;

  const _TicketCard({
    required this.reserva,
    required this.canchaName,
    required this.complejoName,
  });

  String get _metodoPagoLabel {
    const m = {
      'yape': 'Yape 💜',
      'plin': 'Plin 💙',
      'efectivo': 'Efectivo 💵',
      'tarjeta': 'Tarjeta 💳',
    };
    return m[reserva.metodoPago] ?? reserva.metodoPago;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.sur,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
              color: AppColors.tx.withValues(alpha: 0.08),
              blurRadius: 24,
              offset: const Offset(0, 8)),
        ],
      ),
      child: Stack(
        children: [
          Column(
            children: [
              // ── QR con código de acceso real ────────────
              Padding(
                padding: const EdgeInsets.all(32),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.bdr),
                  ),
                  child: QrImageView(
                    data: reserva.codigoAcceso,
                    version: QrVersions.auto,
                    size: 160,
                  ),
                ),
              ),

              // ── Divider punteado ─────────────────────────
              const _DottedLine(),

              // ── Info ticket real ─────────────────────────
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    _buildRow('Complejo', complejoName),
                    const SizedBox(height: 12),
                    _buildRow('Cancha', canchaName),
                    const SizedBox(height: 12),
                    _buildRow(
                      'Fecha',
                      AppDateUtils.formatearFechaLarga(reserva.fecha),
                    ),
                    const SizedBox(height: 12),
                    _buildRow(
                      'Horario',
                      '${reserva.horaInicio} – ${reserva.horaFin}',
                    ),
                    const SizedBox(height: 12),
                    _buildRow('Pago', _metodoPagoLabel),
                    const SizedBox(height: 12),
                    _buildRow(
                      'Total',
                      'S/ ${reserva.precioTotal.toStringAsFixed(2)}',
                      highlight: true,
                    ),
                    const SizedBox(height: 20),

                    // ── Código de acceso ─────────────────
                    Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 12, horizontal: 16),
                      decoration: BoxDecoration(
                        color: AppColors.bg,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Código de Acceso',
                            style: GoogleFonts.plusJakartaSans(
                                fontSize: 11, color: AppColors.tx3),
                          ),
                          Text(
                            // Muestra los primeros 8 caracteres del UUID
                            reserva.codigoAcceso
                                .substring(0, 8)
                                .toUpperCase(),
                            style: GoogleFonts.bricolageGrotesque(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.tx,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // ── Muescas laterales decorativas ───────────────
          Positioned(
            left: -12,
            top: 232,
            child: Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(
                    color: AppColors.bg, shape: BoxShape.circle)),
          ),
          Positioned(
            right: -12,
            top: 232,
            child: Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(
                    color: AppColors.bg, shape: BoxShape.circle)),
          ),
        ],
      ),
    );
  }

  Widget _buildRow(String label, String value,
      {bool highlight = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
              fontSize: 12, color: AppColors.tx3),
        ),
        Text(
          value,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight:
                highlight ? FontWeight.w700 : FontWeight.w600,
            color: highlight ? AppColors.acc : AppColors.tx,
          ),
        ),
      ],
    );
  }
}

class _SuccessCheck extends StatefulWidget {
  const _SuccessCheck();

  @override
  State<_SuccessCheck> createState() => _SuccessCheckState();
}

class _SuccessCheckState extends State<_SuccessCheck>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 2))
      ..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        FadeTransition(
          opacity: _ctrl.drive(Tween(begin: 0.6, end: 0.0)),
          child: ScaleTransition(
            scale: _ctrl.drive(Tween(begin: 1.0, end: 1.8)),
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.acc.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
        Container(
          width: 72,
          height: 72,
          decoration: const BoxDecoration(
              color: AppColors.acc, shape: BoxShape.circle),
          child: const Icon(Icons.check_rounded,
              color: Colors.white, size: 38),
        ),
      ],
    );
  }
}

class _DottedLine extends StatelessWidget {
  const _DottedLine();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: List.generate(
          20,
          (i) => Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 3),
              height: 1,
              color: AppColors.bdr2,
            ),
          ),
        ),
      ),
    );
  }
}
