// pantallas/desarrollo/sembrar_pantalla.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../nucleo/servicios/datos_sembrador.dart';
import '../../nucleo/tema/app_colores.dart';
import '../../proveedores/auth_proveedor.dart';

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
    setState(() { _loading = true; _log = 'Poblando base de datos…'; });
    try {
      // El seeder necesita que el dueño esté autenticado para que
      // Firestore permita las escrituras (regla: isDueno() && esDemo == true)
      final uid = ref.read(uidProvider);
      final perfil = ref.read(perfilUsuarioProvider).asData?.value;

      if (uid == null || perfil?.esDueno != true) {
        setState(() {
          _loading = false;
          _log = '❌ Debes iniciar sesión como dueño para poblar la BD.';
        });
        return;
      }

      await DatabaseSeeder.ejecutar(duenoUid: uid);

      if (mounted) {
        setState(() {
          _loading = false;
          _yaExiste = true;
          _log = '✅ Base de datos poblada.\n\n'
              '• 5 complejos en Huancayo\n'
              '• 16 canchas (F5, F7, Básquet, Vóley)\n'
              '• 18 reservas distribuidas en la semana\n'
              '• 3 partidos abiertos\n'
              '• 3 flash slots activos hoy\n'
              '• 5 predicciones IA con heatmap\n'
              '• 5 reseñas de jugadores'
              '\n\n🔗 Tu cuenta fue vinculada a "El Tambo Sport".';
        });
      }
    } catch (e) {
      if (mounted) setState(() { _loading = false; _log = '❌ Error: $e'; });
    }
  }

  Future<void> _limpiarSeed() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.sur,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('¿Limpiar base de datos?',
            style: GoogleFonts.bricolageGrotesque(
                fontWeight: FontWeight.w700, color: AppColors.tx)),
        content: Text(
          'Borrará todos los datos demo de Firestore.\n'
          'Los usuarios registrados NO se eliminan.',
          style: GoogleFonts.outfit(color: AppColors.tx2, height: 1.5)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancelar',
                style: GoogleFonts.outfit(color: AppColors.tx3))),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Limpiar',
                style: GoogleFonts.outfit(
                    color: AppColors.red, fontWeight: FontWeight.w700))),
        ],
      ),
    );
    if (ok != true) return;

    setState(() { _loading = true; _log = 'Limpiando…'; });
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
      if (mounted) setState(() { _loading = false; _log = '❌ $e'; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.sur,
        elevation: 0,
        title: Text('Setup Base de Datos',
            style: GoogleFonts.bricolageGrotesque(
                fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.tx)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.tx),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // ── Estado ───────────────────────────────────────
            _StatusBanner(yaExiste: _yaExiste),
            const SizedBox(height: 20),

            // ── Qué se crea ──────────────────────────────────
            Text('¿Qué se va a crear?',
                style: GoogleFonts.bricolageGrotesque(
                    fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.tx)),
            const SizedBox(height: 12),
            _item(Icons.stadium_rounded,
                '5 Complejos deportivos',
                'El Tambo Sport, Sport Chilca, Los Andes, Shullcas FC, Indoor HYO'),
            _item(Icons.sports_soccer_rounded,
                '16 Canchas',
                'Fútbol 5, Fútbol 7, Básquet y Vóley con precios reales'),
            _item(Icons.receipt_long_rounded,
                '18 Reservas — semana actual',
                'Distribuidas Lu-Do en el complejo del dueño para el dashboard'),
            _item(Icons.groups_rounded,
                '3 Partidos abiertos',
                'Fútbol 5, Fútbol 7 y Básquet con cupos disponibles'),
            _item(Icons.bolt_rounded,
                '3 Flash Slots activos',
                'Descuentos del 40% con expiración en pocas horas'),
            _item(Icons.auto_graph_rounded,
                '5 Predicciones IA',
                'Heatmap de demanda + precios dinámicos por hora'),
            _item(Icons.star_rounded,
                '5 Reseñas',
                'Calificaciones 4-5★ con respuestas de dueños'),
            const SizedBox(height: 24),

            // ── Log ──────────────────────────────────────────
            if (_log.isNotEmpty) ...[
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
                      height: 1.5),
                ),
              ),
            ],

            // ── Limpiar usuarios demo ─────────────────────────
            OutlinedButton.icon(
              onPressed: _loading ? null : () async {
                setState(() => _loading = true);
                await DatabaseSeeder.limpiarUsuariosDemo();
                if (mounted) setState(() => _loading = false);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('✅ Usuarios demo eliminados',
                        style: GoogleFonts.outfit()),
                    backgroundColor: AppColors.acc,
                    duration: const Duration(seconds: 2),
                  ));
                }
              },
              icon: const Icon(Icons.person_remove_outlined, size: 15),
              label: Text('Limpiar usuarios demo',
                  style: GoogleFonts.outfit(
                      fontSize: 12, fontWeight: FontWeight.w600)),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.tx2,
                side: const BorderSide(color: AppColors.bdr2),
                minimumSize: const Size(double.infinity, 40),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 12),

            // ── Botones ──────────────────────────────────────
            Row(children: [
              if (_yaExiste) ...[
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _loading ? null : _limpiarSeed,
                    icon: const Icon(Icons.delete_outline_rounded, size: 16),
                    label: Text('Limpiar',
                        style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.red,
                      side: const BorderSide(color: AppColors.red),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                flex: 2,
                child: FilledButton.icon(
                  onPressed: _loading ? null : _ejecutarSeed,
                  icon: _loading
                      ? const SizedBox(
                          width: 16, height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.rocket_launch_rounded, size: 16),
                  label: Text(
                    _loading
                        ? 'Poblando…'
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
            ]),
          ],
        ),
      ),
    );
  }

  Widget _item(IconData icon, String title, String subtitle) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        width: 34, height: 34,
        decoration: BoxDecoration(
            color: AppColors.accLight,
            borderRadius: BorderRadius.circular(9)),
        child: Icon(icon, color: AppColors.acc, size: 17),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title,
              style: GoogleFonts.outfit(
                  fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.tx)),
          Text(subtitle,
              style: GoogleFonts.outfit(fontSize: 11, color: AppColors.tx3)),
        ]),
      ),
    ]),
  );
}

// ── Banner de estado ─────────────────────────────────────────────────────────

class _StatusBanner extends StatelessWidget {
  final bool yaExiste;
  const _StatusBanner({required this.yaExiste});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: yaExiste ? AppColors.accLight : AppColors.sur3,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: yaExiste ? AppColors.acc : AppColors.bdr),
    ),
    child: Row(children: [
      Icon(
        yaExiste ? Icons.check_circle_rounded : Icons.info_outline_rounded,
        color: yaExiste ? AppColors.acc : AppColors.tx3,
        size: 20,
      ),
      const SizedBox(width: 10),
      Text(
        yaExiste
            ? 'Firestore tiene datos — listo para usar'
            : 'Firestore vacío — sin datos aún',
        style: GoogleFonts.outfit(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: yaExiste ? AppColors.acc : AppColors.tx2),
      ),
    ]),
  );
}
