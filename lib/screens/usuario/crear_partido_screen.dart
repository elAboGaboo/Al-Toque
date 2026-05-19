// screens/usuario/crear_partido_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/app_date_utils.dart';
import '../../models/partido_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/partidos_provider.dart';

class CrearPartidoScreen extends ConsumerStatefulWidget {
  const CrearPartidoScreen({super.key});

  @override
  ConsumerState<CrearPartidoScreen> createState() =>
      _CrearPartidoScreenState();
}

class _CrearPartidoScreenState extends ConsumerState<CrearPartidoScreen> {
  final _formKey = GlobalKey<FormState>();

  String _deporte = 'futbol5';
  DateTime _fecha = DateTime.now().add(const Duration(days: 1));
  String _horaInicio = '18:00';
  String _horaFin = '19:00';
  int _jugadoresNecesarios = 10;
  double _precioMax = 80;
  bool _loading = false;

  final List<String> _horas = List.generate(
    16,
    (i) => '${(i + 7).toString().padLeft(2, '0')}:00',
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: AppBar(
        backgroundColor: AppColors.paper,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Crear partido',
          style: GoogleFonts.bricolageGrotesque(
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.partyLight,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: AppColors.party.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Text('⚡', style: TextStyle(fontSize: 24)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Arma tu partido',
                          style: GoogleFonts.bricolageGrotesque(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.party,
                          ),
                        ),
                        Text(
                          'Cuando se llene, la cancha se reserva automáticamente',
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            color: AppColors.party.withValues(alpha: 0.7),
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Selector de deporte
            const _SectionLabel(label: 'Deporte', icono: '⚽'),
            const SizedBox(height: 10),
            _SelectorDeporte(
              seleccionado: _deporte,
              onChanged: (d) => setState(() {
                _deporte = d;
                _jugadoresNecesarios =
                    d == 'futbol5' ? 10 : d == 'futbol7' ? 14 : 12;
                _precioMax = d == 'futbol5' ? 80 : d == 'futbol7' ? 100 : 60;
              }),
            ),
            const SizedBox(height: 20),

            // Fecha
            const _SectionLabel(label: 'Fecha', icono: '📅'),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: _seleccionarFecha,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.line),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_rounded,
                        color: AppColors.party, size: 20),
                    const SizedBox(width: 12),
                    Text(
                      AppDateUtils.fechaRelativa(_fecha),
                      style: GoogleFonts.outfit(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: AppColors.ink,
                      ),
                    ),
                    const Spacer(),
                    const Icon(Icons.chevron_right_rounded,
                        color: AppColors.ink, size: 20),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Hora inicio / fin
            const _SectionLabel(label: 'Horario', icono: '🕐'),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _DropdownHora(
                    label: 'Inicio',
                    valor: _horaInicio,
                    horas: _horas,
                    onChanged: (h) => setState(() {
                      _horaInicio = h!;
                      // Auto-ajusta hora fin
                      final idx = _horas.indexOf(h);
                      if (idx < _horas.length - 1) {
                        _horaFin = _horas[idx + 1];
                      }
                    }),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    '→',
                    style: GoogleFonts.outfit(
                        fontSize: 18, color: AppColors.ink),
                  ),
                ),
                Expanded(
                  child: _DropdownHora(
                    label: 'Fin',
                    valor: _horaFin,
                    horas: _horas
                        .where((h) => h.compareTo(_horaInicio) > 0)
                        .toList(),
                    onChanged: (h) =>
                        setState(() => _horaFin = h!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Jugadores necesarios
            const _SectionLabel(label: 'Jugadores necesarios', icono: '👥'),
            const SizedBox(height: 10),
            _SliderJugadores(
              deporte: _deporte,
              valor: _jugadoresNecesarios,
              onChanged: (v) =>
                  setState(() => _jugadoresNecesarios = v),
            ),
            const SizedBox(height: 20),

            // Precio máximo por jugador
            const _SectionLabel(label: 'Precio máximo por jugador', icono: '💰'),
            const SizedBox(height: 4),
            Text(
              'La cancha se seleccionará automáticamente dentro de este presupuesto',
              style: GoogleFonts.outfit(
                fontSize: 12,
                color: AppColors.ink.withValues(alpha: 0.45),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 10),
            _SliderPrecio(
              valor: _precioMax,
              onChanged: (v) => setState(() => _precioMax = v),
            ),
            const SizedBox(height: 32),

            // Botón crear
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.party,
                ),
                onPressed: _loading ? null : _crearPartido,
                child: _loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        'Crear partido · S/${_precioMax.toStringAsFixed(0)}/jugador',
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Future<void> _seleccionarFecha() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _fecha,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      locale: const Locale('es', 'PE'),
    );
    if (picked != null) setState(() => _fecha = picked);
  }

  Future<void> _crearPartido() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    final perfil = ref.read(perfilUsuarioProvider).asData?.value;
    if (perfil == null) return;

    final partido = PartidoModel(
      id: '',
      organizadorId: perfil.id,
      complejoId: null,
      canchaId: null,
      deporte: _deporte,
      fecha: _fecha,
      horaInicio: _horaInicio,
      horaFin: _horaFin,
      jugadoresNecesarios: _jugadoresNecesarios,
      precioMaxPorJugador: _precioMax,
      precioFinalPorJugador: null,
      estado: 'abierto',
      jugadores: [
        JugadorPartido(
          userId: perfil.id,
          nombre: perfil.nombre,
          avatarUrl: perfil.avatarUrl,
          iniciales: perfil.iniciales,
          pagado: false,
          unidoEn: DateTime.now(),
        ),
      ],
      reservaId: null,
      completadoEn: null,
      creadoEn: DateTime.now(),
    );

    final id = await ref
        .read(partidoNotifierProvider.notifier)
        .crearPartido(partido);

    if (mounted) {
      setState(() => _loading = false);
      if (id != null) {
        context.pushReplacement('/partido/$id');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error al crear el partido. Intenta de nuevo.',
              style: GoogleFonts.outfit(),
            ),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    }
  }
}

// ── Sub-widgets ──────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  final String icono;

  const _SectionLabel({required this.label, required this.icono});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(icono, style: const TextStyle(fontSize: 16)),
        const SizedBox(width: 8),
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppColors.ink,
          ),
        ),
      ],
    );
  }
}

class _SelectorDeporte extends StatelessWidget {
  final String seleccionado;
  final void Function(String) onChanged;

  const _SelectorDeporte(
      {required this.seleccionado, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final deportes = [
      ('futbol5', '⚽', 'Fútbol 5', '10 jug.'),
      ('futbol7', '⚽', 'Fútbol 7', '14 jug.'),
      ('basquet', '🏀', 'Básquet', '10 jug.'),
      ('voley', '🏐', 'Voley', '12 jug.'),
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 2.5,
      children: deportes.map((d) {
        final (id, emoji, nombre, jugadores) = d;
        final sel = seleccionado == id;
        return GestureDetector(
          onTap: () => onChanged(id),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: sel ? AppColors.partyLight : AppColors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: sel ? AppColors.party : AppColors.line,
                width: sel ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                Text(emoji, style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      nombre,
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
                        color: sel ? AppColors.party : AppColors.ink,
                      ),
                    ),
                    Text(
                      jugadores,
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        color: AppColors.ink.withValues(alpha: 0.4),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _DropdownHora extends StatelessWidget {
  final String label;
  final String valor;
  final List<String> horas;
  final void Function(String?) onChanged;

  const _DropdownHora({
    required this.label,
    required this.valor,
    required this.horas,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.line),
      ),
      child: DropdownButton<String>(
        value: horas.contains(valor) ? valor : horas.first,
        isExpanded: true,
        underline: const SizedBox.shrink(),
        hint: Text(label, style: GoogleFonts.outfit()),
        items: horas
            .map((h) => DropdownMenuItem(
                  value: h,
                  child: Text(h, style: GoogleFonts.outfit()),
                ))
            .toList(),
        onChanged: onChanged,
      ),
    );
  }
}

class _SliderJugadores extends StatelessWidget {
  final String deporte;
  final int valor;
  final void Function(int) onChanged;

  const _SliderJugadores({
    required this.deporte,
    required this.valor,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final max = deporte == 'futbol7' ? 14 : 12;
    const min = 4;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              '$valor jugadores',
              style: GoogleFonts.bricolageGrotesque(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.party,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '(incluyéndote)',
              style: GoogleFonts.outfit(
                fontSize: 12,
                color: AppColors.ink.withValues(alpha: 0.4),
              ),
            ),
          ],
        ),
        Slider(
          value: valor.toDouble(),
          min: min.toDouble(),
          max: max.toDouble(),
          divisions: max - min,
          activeColor: AppColors.party,
          inactiveColor: AppColors.partyLight,
          onChanged: (v) => onChanged(v.round()),
        ),
      ],
    );
  }
}

class _SliderPrecio extends StatelessWidget {
  final double valor;
  final void Function(double) onChanged;

  const _SliderPrecio({required this.valor, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'S/ ${valor.toStringAsFixed(0)} / jugador',
          style: GoogleFonts.bricolageGrotesque(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AppColors.green,
          ),
        ),
        Slider(
          value: valor,
          min: 20,
          max: 200,
          divisions: 18,
          activeColor: AppColors.green,
          inactiveColor: AppColors.greenLight,
          onChanged: onChanged,
        ),
      ],
    );
  }
}
