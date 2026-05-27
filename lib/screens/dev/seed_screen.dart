// screens/dev/seed_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/services/database_seeder.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';

/// Pantalla de configuración inicial de la base de datos.
/// Solo para uso en desarrollo / setup inicial.
class SeedScreen extends ConsumerStatefulWidget {
  const SeedScreen({super.key});

  @override
  ConsumerState<SeedScreen> createState() => _SeedScreenState();
}

class _SeedScreenState extends ConsumerState<SeedScreen> {
  bool _loading = false;
  bool _yaExiste = false;
  String _log = '';

  @override
  void initState() {
    super.initState();
    _verificar();
  }

  Future<void> _verificar() async {
    final existe = await DatabaseSeeder.yaEjecutado();
    if (mounted) setState(() => _yaExiste = existe);
  }

  Future<void> _ejecutarSeed() async {
    setState(() {
      _loading = true;
      _log = 'Iniciando…';
    });

    try {
      // Si el usuario actual es dueño, asócialo al primer complejo del seed
      final uid = ref.read(uidProvider);
      final perfil = ref.read(perfilUsuarioProvider).asData?.value;
      final esDueno = perfil?.esDueno ?? false;
      final duenoUid = (esDueno && uid != null) ? uid : null;

      await DatabaseSeeder.ejecutar(duenoUid: duenoUid);

      if (mounted) {
        setState(() {
          _loading = false;
          _yaExiste = true;
          _log =
              '✅ Base de datos poblada correctamente.\n\n'
              '• 5 complejos en Huancayo\n'
              '• 16 canchas distribuidas\n'
              '• 5 reservas de ejemplo\n'
              '• 3 partidos abiertos\n'
              '• 3 flash slots activos\n'
              '• 5 predicciones IA (heatmap + precios dinámicos)\n'
              '• 5 reseñas'
              '${duenoUid != null ? '\n\n🔗 Tu cuenta fue asociada a "El Tambo Sport".' : ''}';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _log = '❌ Error: $e';
        });
      }
    }
  }

  Future<void> _limpiarSeed() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.sur,
        title: Text('¿Limpiar base de datos?',
            style: GoogleFonts.bricolageGrotesque(
                fontWeight: FontWeight.w700, color: AppColors.tx)),
        content: Text(
          'Esto borrará todos los complejos, canchas, partidos y flash slots del seed.',
          style: GoogleFonts.outfit(color: AppColors.tx2),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancelar',
                style: GoogleFonts.outfit(color: AppColors.tx3)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Limpiar',
                style: GoogleFonts.outfit(
                    color: AppColors.red, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() {
      _loading = true;
      _log = 'Limpiando…';
    });

    try {
      await DatabaseSeeder.limpiar();
      if (mounted) {
        setState(() {
          _loading = false;
          _yaExiste = false;
          _log = '✅ Base de datos limpiada.';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _log = '❌ Error al limpiar: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final perfil = ref.watch(perfilUsuarioProvider).asData?.value;
    final esDueno = perfil?.esDueno ?? false;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.sur,
        elevation: 0,
        title: Text(
          'Setup Base de Datos',
          style: GoogleFonts.bricolageGrotesque(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.tx,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.tx),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Estado actual
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _yaExiste
                      ? AppColors.accLight
                      : AppColors.sur3,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: _yaExiste ? AppColors.acc : AppColors.bdr,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _yaExiste
                          ? Icons.check_circle_rounded
                          : Icons.info_outline_rounded,
                      color: _yaExiste ? AppColors.acc : AppColors.tx3,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      _yaExiste
                          ? 'Firestore ya tiene datos'
                          : 'Firestore vacío — sin datos aún',
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _yaExiste ? AppColors.acc : AppColors.tx2,
                      ),
                    ),
                  ],
                ),
              ),

              // Banner de asociación de dueño
              if (esDueno) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.sur2,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.bdr),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.link_rounded,
                          color: AppColors.acc, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Tu cuenta (dueño) será asociada a "El Tambo Sport" al poblar.',
                          style: GoogleFonts.outfit(
                              fontSize: 12, color: AppColors.tx2, height: 1.4),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 24),

              Text(
                '¿Qué se va a crear?',
                style: GoogleFonts.bricolageGrotesque(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.tx,
                ),
              ),
              const SizedBox(height: 12),

              _ItemSeed(
                icon: Icons.stadium_rounded,
                title: '5 Complejos deportivos',
                subtitle:
                    'El Tambo Sport, Sport Center Chilca, Los Andes FC, Shullcas FC, Indoor Sport',
              ),
              _ItemSeed(
                icon: Icons.sports_soccer_rounded,
                title: '16 Canchas',
                subtitle:
                    'Fútbol 5, Fútbol 7, Básquet y Vóley con precios reales',
              ),
              _ItemSeed(
                icon: Icons.receipt_long_rounded,
                title: '5 Reservas de ejemplo',
                subtitle:
                    'Normal, flash y partido — confirmadas, pendientes y canceladas',
              ),
              _ItemSeed(
                icon: Icons.groups_rounded,
                title: '3 Partidos abiertos',
                subtitle:
                    'Fútbol 5, Fútbol 7 y Básquet con jugadores de ejemplo',
              ),
              _ItemSeed(
                icon: Icons.bolt_rounded,
                title: '3 Flash Slots activos',
                subtitle:
                    'Descuentos del 36-40% con expiración en pocas horas',
              ),
              _ItemSeed(
                icon: Icons.auto_graph_rounded,
                title: '5 Predicciones IA',
                subtitle:
                    'Heatmap de demanda y precios dinámicos por hora para cada complejo',
              ),
              _ItemSeed(
                icon: Icons.star_rounded,
                title: '5 Reseñas',
                subtitle: 'Calificaciones de jugadores con respuestas de dueños',
              ),

              const Spacer(),

              // Log de resultado
              if (_log.isNotEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppColors.sur,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.bdr),
                  ),
                  child: Text(
                    _log,
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      color: _log.startsWith('❌')
                          ? AppColors.red
                          : AppColors.tx2,
                      height: 1.5,
                    ),
                  ),
                ),

              // Botones
              Row(
                children: [
                  if (_yaExiste)
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _loading ? null : _limpiarSeed,
                        icon: const Icon(Icons.delete_outline_rounded,
                            size: 16),
                        label: Text('Limpiar',
                            style: GoogleFonts.outfit(
                                fontWeight: FontWeight.w600)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.red,
                          side: const BorderSide(color: AppColors.red),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  if (_yaExiste) const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: FilledButton.icon(
                      onPressed: _loading ? null : _ejecutarSeed,
                      icon: _loading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.rocket_launch_rounded, size: 16),
                      label: Text(
                        _loading
                            ? 'Creando datos…'
                            : _yaExiste
                                ? 'Reiniciar seed'
                                : 'Poblar base de datos',
                        style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.acc,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ItemSeed extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _ItemSeed({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.accLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.acc, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.tx,
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.outfit(
                      fontSize: 12, color: AppColors.tx3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
