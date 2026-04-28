// screens/admin/admin_ia_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_colors.dart';
import '../../models/complejo_model.dart';
import '../../models/prediccion_ia_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/complejos_provider.dart';
import '../../repositories/complejos_repository.dart';
import '../../services/predicciones_service.dart';

final _prediccionAdminProvider =
    FutureProvider.family<PrediccionIAModel?, String>(
        (ref, complejoId) async =>
            PrediccionesService().getUltimaPrediccion(complejoId));

class AdminIAScreen extends ConsumerWidget {
  const AdminIAScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final complejoId = ref.watch(complejoIdAdminProvider) ?? 'demo';
    final complejoAsync = ref.watch(complejoProvider(complejoId));
    final prediccionAsync = ref.watch(_prediccionAdminProvider(complejoId));

    return Scaffold(
      backgroundColor: AppColors.adminBg,
      appBar: AppBar(
        backgroundColor: AppColors.adminS1,
        elevation: 0,
        title: Text('IA',
            style: GoogleFonts.bricolageGrotesque(
                fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          complejoAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
            data: (c) => c != null ? _ConfigIACard(complejo: c) : const SizedBox.shrink(),
          ),
          const SizedBox(height: 16),
          prediccionAsync.when(
            loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFFA78BFA))),
            error: (_, __) => _SinPrediccionCard(),
            data: (p) => p != null ? _PrediccionCard(prediccion: p) : _SinPrediccionCard(),
          ),
        ],
      ),
    );
  }
}

class _ConfigIACard extends StatefulWidget {
  final ComplejoModel complejo;
  const _ConfigIACard({required this.complejo});
  @override
  State<_ConfigIACard> createState() => _ConfigIACardState();
}

class _ConfigIACardState extends State<_ConfigIACard> {
  late bool _preciosDinamicos;
  late bool _flashAuto;
  late bool _notificar;

  @override
  void initState() {
    super.initState();
    _preciosDinamicos = widget.complejo.configIA.preciosDinamicosActivo;
    _flashAuto = widget.complejo.configIA.flashAutomaticoActivo;
    _notificar = widget.complejo.configIA.notificarJugadores;
  }

  Future<void> _guardar() async {
    await ComplejosRepository().actualizarConfigIA(
      widget.complejo.id,
      ConfigIA(
        preciosDinamicosActivo: _preciosDinamicos,
        flashAutomaticoActivo: _flashAuto,
        notificarJugadores: _notificar,
        precioTechoMax: widget.complejo.configIA.precioTechoMax,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.adminS1,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFA78BFA).withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('🤖  Configuración IA',
              style: GoogleFonts.bricolageGrotesque(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
          const SizedBox(height: 16),
          _Switch(label: 'Precios dinámicos', sub: 'Ajusta precios según demanda', valor: _preciosDinamicos, color: AppColors.adminFlash,
              onChanged: (v) { setState(() => _preciosDinamicos = v); _guardar(); }),
          const Divider(color: Color(0xFF1E293B), height: 20),
          _Switch(label: 'Flash automático', sub: 'Crea flash slots cuando cancha lleva >1h vacía', valor: _flashAuto, color: AppColors.adminFlash,
              onChanged: (v) { setState(() => _flashAuto = v); _guardar(); }),
          const Divider(color: Color(0xFF1E293B), height: 20),
          _Switch(label: 'Notificar jugadores cercanos', sub: 'Push FCM a usuarios en radio 5km', valor: _notificar, color: AppColors.adminGreen,
              onChanged: (v) { setState(() => _notificar = v); _guardar(); }),
        ],
      ),
    );
  }
}

class _Switch extends StatelessWidget {
  final String label, sub;
  final bool valor;
  final Color color;
  final void Function(bool) onChanged;
  const _Switch({required this.label, required this.sub, required this.valor, required this.color, required this.onChanged});
  @override
  Widget build(BuildContext context) => Row(children: [
    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
      Text(sub, style: GoogleFonts.outfit(fontSize: 11, color: Colors.white38, height: 1.3)),
    ])),
    Switch(value: valor, onChanged: onChanged, activeThumbColor: color, inactiveTrackColor: AppColors.adminS3),
  ]);
}

class _PrediccionCard extends StatelessWidget {
  final PrediccionIAModel prediccion;
  const _PrediccionCard({required this.prediccion});
  @override
  Widget build(BuildContext context) {
    final entries = prediccion.heatmap.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: AppColors.adminS1, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.adminS3)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('📊  Heatmap de demanda', style: GoogleFonts.bricolageGrotesque(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
        const SizedBox(height: 4),
        Text('Semana ${prediccion.semana} · Precisión ${(prediccion.precision*100).toStringAsFixed(0)}%',
            style: GoogleFonts.outfit(fontSize: 12, color: Colors.white38)),
        const SizedBox(height: 16),
        ...entries.take(8).map((e) {
          final d = e.value.clamp(0.0, 1.0);
          final c = d > 0.7 ? AppColors.adminRed : d > 0.4 ? AppColors.adminFlash : AppColors.adminGreen;
          return Padding(padding: const EdgeInsets.only(bottom: 8), child: Row(children: [
            SizedBox(width: 60, child: Text(e.key, style: GoogleFonts.outfit(fontSize: 11, color: Colors.white54))),
            Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(4), child: LinearProgressIndicator(value: d, minHeight: 10, backgroundColor: AppColors.adminS3, color: c))),
            const SizedBox(width: 8),
            Text('${(d*100).toStringAsFixed(0)}%', style: GoogleFonts.outfit(fontSize: 11, color: c, fontWeight: FontWeight.w600)),
          ]));
        }),
      ]),
    );
  }
}

class _SinPrediccionCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(color: AppColors.adminS1, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.adminS3)),
    child: Column(children: [
      const Text('🤖', style: TextStyle(fontSize: 40)),
      const SizedBox(height: 12),
      Text('Sin predicciones aún', style: GoogleFonts.bricolageGrotesque(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
      const SizedBox(height: 8),
      Text('Las predicciones se generan semanalmente con Cloud Functions.', textAlign: TextAlign.center, style: GoogleFonts.outfit(fontSize: 13, color: Colors.white38, height: 1.4)),
    ]),
  );
}
