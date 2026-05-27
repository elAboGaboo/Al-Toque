// screens/dev/seed_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/services/database_seeder.dart';
import '../../core/theme/app_colors.dart';

class SeedScreen extends ConsumerStatefulWidget {
  const SeedScreen({super.key});

  @override
  ConsumerState<SeedScreen> createState() => _SeedScreenState();
}

class _SeedScreenState extends ConsumerState<SeedScreen> {
  bool _loading = false;
  bool _yaExiste = false;
  String _log = '';
  List<DemoCredencial> _credenciales = [];

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
    setState(() { _loading = true; _log = 'Creando cuentas y datos…'; _credenciales = []; });
    try {
      final creds = await DatabaseSeeder.ejecutar();
      if (mounted) {
        setState(() {
          _loading = false;
          _yaExiste = true;
          _credenciales = creds;
          _log = '✅ Base de datos poblada correctamente.';
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
        title: Text('¿Limpiar base de datos?',
            style: GoogleFonts.bricolageGrotesque(fontWeight: FontWeight.w700, color: AppColors.tx)),
        content: Text('Borrará todos los datos demo de Firestore.\n'
            'Las cuentas Firebase Auth se mantienen.',
            style: GoogleFonts.outfit(color: AppColors.tx2, height: 1.5)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false),
              child: Text('Cancelar', style: GoogleFonts.outfit(color: AppColors.tx3))),
          TextButton(onPressed: () => Navigator.pop(context, true),
              child: Text('Limpiar', style: GoogleFonts.outfit(color: AppColors.red, fontWeight: FontWeight.w700))),
        ],
      ),
    );
    if (ok != true) return;

    setState(() { _loading = true; _log = 'Limpiando…'; });
    try {
      await DatabaseSeeder.limpiar();
      if (mounted) setState(() { _loading = false; _yaExiste = false; _credenciales = []; _log = '✅ Base de datos limpiada.'; });
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
            style: GoogleFonts.bricolageGrotesque(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.tx)),
        leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: AppColors.tx),
            onPressed: () => Navigator.pop(context)),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // ── Estado ───────────────────────────────────────
            _StatusBanner(yaExiste: _yaExiste),
            const SizedBox(height: 16),

            // ── Credenciales (visible tras poblar) ───────────
            if (_credenciales.isNotEmpty) ...[
              _CredencialesCard(credenciales: _credenciales),
              const SizedBox(height: 16),
            ],

            // ── Qué se crea ──────────────────────────────────
            Text('¿Qué se va a crear?',
                style: GoogleFonts.bricolageGrotesque(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.tx)),
            const SizedBox(height: 10),
            _item(Icons.manage_accounts_rounded,  '5 Dueños demo',        'Uno por complejo, con cuenta de acceso real'),
            _item(Icons.person_rounded,            '9 Jugadores demo',     'Con cuentas reales y reservas vinculadas'),
            _item(Icons.stadium_rounded,           '5 Complejos',          'El Tambo Sport, Chilca, Los Andes, Shullcas, Indoor'),
            _item(Icons.sports_soccer_rounded,     '16 Canchas',           'Fútbol 5, Fútbol 7, Básquet y Vóley'),
            _item(Icons.receipt_long_rounded,      '7 Reservas',           'Normal, flash, partido — confirmadas/pendientes/canceladas'),
            _item(Icons.groups_rounded,            '3 Partidos abiertos',  'Con jugadores conectados a sus cuentas'),
            _item(Icons.bolt_rounded,              '3 Flash Slots',        'Descuentos 36-40% activos hoy'),
            _item(Icons.auto_graph_rounded,        '5 Predicciones IA',    'Heatmap y precios dinámicos por complejo'),
            _item(Icons.star_rounded,              '5 Reseñas',            'De jugadores reales con respuestas de dueños'),
            const SizedBox(height: 20),

            // ── Log ──────────────────────────────────────────
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
                child: Text(_log,
                    style: GoogleFonts.outfit(
                        fontSize: 13,
                        color: _log.startsWith('❌') ? AppColors.red : AppColors.tx2,
                        height: 1.5)),
              ),

            // ── Botones ──────────────────────────────────────
            Row(children: [
              if (_yaExiste) ...[
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _loading ? null : _limpiarSeed,
                    icon: const Icon(Icons.delete_outline_rounded, size: 16),
                    label: Text('Limpiar', style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.red,
                      side: const BorderSide(color: AppColors.red),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                      ? const SizedBox(width: 16, height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.rocket_launch_rounded, size: 16),
                  label: Text(
                    _loading ? 'Creando…' : _yaExiste ? 'Reiniciar seed' : 'Poblar base de datos',
                    style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.acc,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ]),
            const SizedBox(height: 8),
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
        decoration: BoxDecoration(color: AppColors.accLight, borderRadius: BorderRadius.circular(9)),
        child: Icon(icon, color: AppColors.acc, size: 17),
      ),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.tx)),
        Text(subtitle, style: GoogleFonts.outfit(fontSize: 11, color: AppColors.tx3)),
      ])),
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
      Icon(yaExiste ? Icons.check_circle_rounded : Icons.info_outline_rounded,
          color: yaExiste ? AppColors.acc : AppColors.tx3, size: 20),
      const SizedBox(width: 10),
      Text(yaExiste ? 'Firestore ya tiene datos' : 'Firestore vacío — sin datos aún',
          style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600,
              color: yaExiste ? AppColors.acc : AppColors.tx2)),
    ]),
  );
}

// ── Tarjeta de credenciales ───────────────────────────────────────────────────
class _CredencialesCard extends StatefulWidget {
  final List<DemoCredencial> credenciales;
  const _CredencialesCard({required this.credenciales});

  @override
  State<_CredencialesCard> createState() => _CredencialesCardState();
}

class _CredencialesCardState extends State<_CredencialesCard> {
  bool _mostrarJugadores = false;

  void _copiar(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Copiado', style: GoogleFonts.outfit()), duration: const Duration(seconds: 1)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final duenos   = widget.credenciales.where((c) => c.rol == 'dueno').toList();
    final jugadores = widget.credenciales.where((c) => c.rol == 'jugador').toList();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.sur,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.acc.withValues(alpha: 0.4)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Cabecera
        Row(children: [
          const Icon(Icons.vpn_key_rounded, color: AppColors.acc, size: 16),
          const SizedBox(width: 8),
          Text('Credenciales demo',
              style: GoogleFonts.bricolageGrotesque(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.acc)),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.accLight,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text('contraseña: AlToque2024!',
                style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.acc)),
          ),
        ]),
        const SizedBox(height: 12),

        // Dueños
        Text('DUEÑOS', style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w700,
            color: AppColors.tx3, letterSpacing: 0.8)),
        const SizedBox(height: 6),
        ...duenos.map((c) => _CredRow(cred: c, onCopy: _copiar)),

        const SizedBox(height: 10),

        // Jugadores (colapsables)
        GestureDetector(
          onTap: () => setState(() => _mostrarJugadores = !_mostrarJugadores),
          child: Row(children: [
            Text('JUGADORES', style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w700,
                color: AppColors.tx3, letterSpacing: 0.8)),
            const SizedBox(width: 6),
            Icon(_mostrarJugadores ? Icons.expand_less : Icons.expand_more,
                size: 16, color: AppColors.tx3),
          ]),
        ),
        if (_mostrarJugadores) ...[
          const SizedBox(height: 6),
          ...jugadores.map((c) => _CredRow(cred: c, onCopy: _copiar)),
        ],
      ]),
    );
  }
}

class _CredRow extends StatelessWidget {
  final DemoCredencial cred;
  final void Function(String) onCopy;
  const _CredRow({required this.cred, required this.onCopy});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () => onCopy(cred.email),
    child: Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.bdr),
      ),
      child: Row(children: [
        Container(
          width: 28, height: 28,
          decoration: BoxDecoration(
            color: cred.rol == 'dueno'
                ? AppColors.acc.withValues(alpha: 0.15)
                : AppColors.tx3.withValues(alpha: 0.10),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(cred.nombre.split(' ').map((w) => w[0]).take(2).join(),
                style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w700,
                    color: cred.rol == 'dueno' ? AppColors.acc : AppColors.tx2)),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(cred.nombre,
              style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.tx)),
          Text(cred.email,
              style: GoogleFonts.outfit(fontSize: 11, color: AppColors.tx3)),
          if (cred.complejo != null)
            Text('→ ${cred.complejo}',
                style: GoogleFonts.outfit(fontSize: 10, color: AppColors.acc)),
        ])),
        const Icon(Icons.copy_rounded, size: 14, color: AppColors.tx3),
      ]),
    ),
  );
}
