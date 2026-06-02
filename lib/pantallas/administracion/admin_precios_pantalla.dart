// screens/admin/admin_precios_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../nucleo/tema/app_colores.dart';

class AdminPreciosScreen extends ConsumerStatefulWidget {
  const AdminPreciosScreen({super.key});

  @override
  ConsumerState<AdminPreciosScreen> createState() =>
      _AdminPreciosScreenState();
}

class _AdminPreciosScreenState extends ConsumerState<AdminPreciosScreen> {
  bool _precioDinamico = true;
  bool _descuentosValles = true;
  bool _limiteMaximo = false;
  bool _notificarUsuario = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.abg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ───────────────────────────────
              Text(
                'Precios Dinámicos',
                style: GoogleFonts.bricolageGrotesque(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppColors.atx,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'La IA ajusta tarifas en horas pico y aplica descuentos en valles',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: AppColors.atx2,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),

              // ── Banner activo ────────────────────────
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.aaccD,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.aaccB),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.aacc.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.auto_awesome_rounded,
                        color: AppColors.aacc,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Precios inteligentes activos',
                            style: GoogleFonts.bricolageGrotesque(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.atx,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'IA ajusta en tiempo real',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              color: AppColors.atx2,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.aacc,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ── Section label ───────────────────────
              Text(
                'HOY · CANCHA 2',
                style: GoogleFonts.bricolageGrotesque(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.atx3,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 10),

              // ── Slot grid (2x2) ─────────────────────
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 1.55,
                children: const [
                  _PrecioSlot(
                    horario: '7:00 - 8:00',
                    precio: 32,
                    precioOriginal: 40,
                    deltaPct: -20,
                  ),
                  _PrecioSlot(
                    horario: '10:00 - 11:00',
                    precio: 36,
                    precioOriginal: 40,
                    deltaPct: -10,
                  ),
                  _PrecioSlot(
                    horario: '17:00 - 18:00',
                    precio: 52,
                    precioOriginal: 40,
                    deltaPct: 30,
                  ),
                  _PrecioSlot(
                    horario: '19:00 - 20:00',
                    precio: 56,
                    precioOriginal: 40,
                    deltaPct: 40,
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // ── Sección Configuración ───────────────
              Text(
                'CONFIGURACIÓN',
                style: GoogleFonts.bricolageGrotesque(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.atx3,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 10),

              Container(
                decoration: BoxDecoration(
                  color: AppColors.asur,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.abdr),
                ),
                child: Column(
                  children: [
                    _ConfigToggle(
                      title: 'Precio dinámico automático',
                      subtitle: 'IA ajusta precios en tiempo real',
                      value: _precioDinamico,
                      onChanged: (v) => setState(() => _precioDinamico = v),
                    ),
                    const _ConfigDivider(),
                    _ConfigToggle(
                      title: 'Descuentos en valles',
                      subtitle: 'Aplicar -20% en demanda baja',
                      value: _descuentosValles,
                      onChanged: (v) => setState(() => _descuentosValles = v),
                    ),
                    const _ConfigDivider(),
                    _ConfigToggle(
                      title: 'Límite máximo S/60',
                      subtitle: 'No superar precio techo',
                      value: _limiteMaximo,
                      onChanged: (v) => setState(() => _limiteMaximo = v),
                    ),
                    const _ConfigDivider(),
                    _ConfigToggle(
                      title: 'Notificar al usuario',
                      subtitle: 'Avisar cuando el precio cambia',
                      value: _notificarUsuario,
                      onChanged: (v) =>
                          setState(() => _notificarUsuario = v),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PrecioSlot extends StatelessWidget {
  final String horario;
  final int precio;
  final int precioOriginal;
  final int deltaPct; // positivo = sube, negativo = baja

  const _PrecioSlot({
    required this.horario,
    required this.precio,
    required this.precioOriginal,
    required this.deltaPct,
  });

  @override
  Widget build(BuildContext context) {
    final esBajada = deltaPct < 0;
    final color = esBajada ? AppColors.aacc : AppColors.ared;
    // Barra: visual relativa al rango [-40, +40]
    final barFill = (deltaPct.abs().clamp(0, 50)) / 50;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.asur,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.abdr),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            horario,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.atx2,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'S/$precio',
                style: GoogleFonts.bricolageGrotesque(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.atx,
                  height: 1,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(width: 6),
              Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Text(
                  'S/$precioOriginal',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    color: AppColors.atx3,
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.abdr2,
              borderRadius: BorderRadius.circular(2),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: barFill.toDouble(),
              child: Container(
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(
                esBajada
                    ? Icons.arrow_downward_rounded
                    : Icons.arrow_upward_rounded,
                color: color,
                size: 12,
              ),
              const SizedBox(width: 2),
              Text(
                '${deltaPct > 0 ? '+' : ''}$deltaPct%',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                'IA',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: AppColors.atx3,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ConfigToggle extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ConfigToggle({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.atx,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    color: AppColors.atx2,
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppColors.aacc,
            inactiveTrackColor: AppColors.abdr2,
          ),
        ],
      ),
    );
  }
}

class _ConfigDivider extends StatelessWidget {
  const _ConfigDivider();

  @override
  Widget build(BuildContext context) {
    return Container(height: 1, color: AppColors.abdr2);
  }
}
