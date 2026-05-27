// screens/usuario/inicio_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_colors.dart';
import '../../models/complejo_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/complejos_provider.dart';

/// Home / feed del jugador. Muestra saludo personalizado + accesos rápidos
/// a Flash Slots, Partidos abiertos y Mapa.
class InicioScreen extends ConsumerWidget {
  const InicioScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final perfil = ref.watch(perfilUsuarioProvider).asData?.value;
    final nombre = perfil?.nombre.split(' ').first ?? 'Jugador';

    final hora = DateTime.now().hour;
    final saludo = hora < 12
        ? 'Buenos días 🌤️'
        : hora < 19
            ? 'Buenas tardes 👋'
            : 'Buenas noches 🌙';

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header (Saludo + Avatar) ────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          saludo,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            color: AppColors.tx3,
                            fontWeight: FontWeight.w300,
                          ),
                        ),
                        Text(
                          nombre,
                          style: GoogleFonts.bricolageGrotesque(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: AppColors.tx,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: AppColors.sur,
                            border: Border.all(color: AppColors.bdr2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              const Icon(Icons.notifications_none_rounded,
                                  size: 17, color: AppColors.tx2),
                              Positioned(
                                top: 7,
                                right: 7,
                                child: Container(
                                  width: 7,
                                  height: 7,
                                  decoration: BoxDecoration(
                                    color: AppColors.red,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: AppColors.bg, width: 2),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [AppColors.acc, AppColors.acc2],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            nombre.substring(0, 1).toUpperCase(),
                            style: GoogleFonts.bricolageGrotesque(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // ── Buscador ──────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.all(11),
                  decoration: BoxDecoration(
                    color: AppColors.sur,
                    border: Border.all(color: AppColors.bdr2),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.tx.withValues(alpha: 0.07),
                        blurRadius: 12,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.search_rounded, size: 16, color: AppColors.tx3),
                      const SizedBox(width: 8),
                      Text(
                        'Buscar complejos o canchas...',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          color: AppColors.tx3,
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: AppColors.acc,
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: const Icon(Icons.tune_rounded, size: 14, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 14),

              // ── Categorías (Chips) ─────────────────────
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    _buildChip('Todos', true),
                    _buildChip('Fútbol 5', false),
                    _buildChip('Fútbol 7', false),
                    _buildChip('Básquet', false),
                    _buildChip('Vóley', false),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // ── Banner IA ─────────────────────────────
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: _AIBanner(),
              ),

              // ── Sección: Cerca de ti ───────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Cerca de ti',
                      style: GoogleFonts.bricolageGrotesque(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.tx,
                        letterSpacing: -0.3,
                      ),
                    ),
                    Text(
                      'Ver mapa',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: AppColors.acc,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              // ── Lista de Complejos (Firestore) ────────
              _ComplejosSection(),

              const SizedBox(height: 80), // Espacio para el nav
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChip(String label, bool active) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: active ? AppColors.tx : AppColors.sur,
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: active ? AppColors.tx : AppColors.bdr2),
      ),
      child: Text(
        label,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 12,
          fontWeight: active ? FontWeight.w600 : FontWeight.w500,
          color: active ? Colors.white : AppColors.tx2,
        ),
      ),
    );
  }
}

class _AIBanner extends StatelessWidget {
  const _AIBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
      decoration: BoxDecoration(
        color: AppColors.tx,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.aacc.withValues(alpha: 0.15),
              border: Border.all(color: AppColors.aacc.withValues(alpha: 0.3)),
              borderRadius: BorderRadius.circular(100),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const _PulseDot(),
                const SizedBox(width: 5),
                Text(
                  'IA EN VIVO',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppColors.aacc,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Alta demanda hoy\nde 6pm a 9pm',
            style: GoogleFonts.bricolageGrotesque(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: Colors.white,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'Basado en historial y clima de Huancayo',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              color: Colors.white.withValues(alpha: 0.42),
              fontWeight: FontWeight.w300,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '87%',
                    style: GoogleFonts.bricolageGrotesque(
                      fontSize: 30,
                      fontWeight: FontWeight.w700,
                      color: AppColors.aacc,
                    ),
                  ),
                  Text(
                    'ocupación pico',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      color: Colors.white.withValues(alpha: 0.3),
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Libres ahora',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      color: Colors.white.withValues(alpha: 0.3),
                    ),
                  ),
                  Text(
                    '3',
                    style: GoogleFonts.bricolageGrotesque(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Bares de estadísticas IA
          SizedBox(
            height: 40,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(10, (i) {
                final h = [25, 32, 50, 58, 82, 100, 96, 68, 38, 22][i];
                final isHi = h > 70;
                final isMd = h > 40;
                return Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 1.5),
                    height: h.toDouble() * 0.4,
                    decoration: BoxDecoration(
                      color: isHi
                          ? AppColors.aacc
                          : (isMd ? AppColors.aacc.withValues(alpha: 0.5) : Colors.white.withValues(alpha: 0.15)),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                    ),
                  ),
                );
              }),
            ),
          ),
          // Footer del banner
          Container(
            margin: const EdgeInsets.only(top: 0),
            padding: const EdgeInsets.symmetric(vertical: 11),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.07))),
            ),
            child: Row(
              children: [
                _buildStatItem('+12', 'Reservas IA'),
                _buildStatItem('S/40', 'Desde'),
                _buildStatItem('2.1km', 'Más cercana'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String val, String lbl) {
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          border: Border(right: BorderSide(color: Colors.white.withValues(alpha: 0.07))),
        ),
        child: Column(
          children: [
            Text(val,
                style: GoogleFonts.bricolageGrotesque(
                    fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white)),
            Text(lbl,
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 10, color: Colors.white.withValues(alpha: 0.32))),
          ],
        ),
      ),
    );
  }
}

class _PulseDot extends StatefulWidget {
  const _PulseDot();

  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _ctrl.drive(CurveTween(curve: Curves.easeInOut)),
      child: Container(
        width: 5,
        height: 5,
        decoration: const BoxDecoration(color: AppColors.aacc, shape: BoxShape.circle),
      ),
    );
  }
}

// ── Sección de complejos desde Firestore ────────────────────────────────────

class _ComplejosSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final complejosAsync = ref.watch(complejosProvider);

    return complejosAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(
          child: CircularProgressIndicator(color: AppColors.acc),
        ),
      ),
      error: (err, _) {
        debugPrint('[InicioScreen] Error cargando complejos: $err');
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
          child: Center(
            child: Text(
              'No se pudieron cargar los complejos.\nVerifica tu conexión.',
              style: GoogleFonts.outfit(fontSize: 13, color: AppColors.tx3),
              textAlign: TextAlign.center,
            ),
          ),
        );
      },
      data: (complejos) {
        if (complejos.isEmpty) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.sur,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.bdr2),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: AppColors.accLight,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.stadium_outlined,
                        color: AppColors.acc, size: 28),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Aún no hay complejos',
                    style: GoogleFonts.bricolageGrotesque(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.tx,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Los complejos deportivos de Huancayo\naparecerán aquí muy pronto.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                        fontSize: 12, color: AppColors.tx3, height: 1.5),
                  ),
                ],
              ),
            ),
          );
        }
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              for (int i = 0; i < complejos.length; i++) ...[
                if (i > 0) const SizedBox(height: 12),
                _ComplexCard(
                  complejo: complejos[i],
                  // Seteamos el modelo en el provider ANTES de navegar
                  // → la pantalla de detalle muestra el header sin llamada Firestore extra
                  onVerCanchas: () {
                    ref.read(complejoSeleccionadoProvider.notifier)
                        .select(complejos[i]);
                    context.push('/complejo/${complejos[i].id}');
                  },
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

// ── Tarjeta de complejo real ─────────────────────────────────────────────────

class _ComplexCard extends ConsumerWidget {
  final ComplejoModel complejo;
  /// Callback que setea el provider y navega — recibido desde _ComplejosSection.
  final VoidCallback onVerCanchas;
  const _ComplexCard({required this.complejo, required this.onVerCanchas});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canchasAsync = ref.watch(canchasProvider(complejo.id));

    final canchaCount = canchasAsync.when(
      loading: () => '…',
      error: (_, _) => '?',
      data: (list) => '${list.length}',
    );

    final precioDesde = canchasAsync.asData?.value
        .map((c) => c.precioBase)
        .fold<double?>(null, (min, p) => min == null || p < min ? p : min);

    final precioLabel = precioDesde != null
        ? 'S/${precioDesde.toStringAsFixed(0)}'
        : '—';

    return Container(
      decoration: BoxDecoration(
        color: AppColors.sur,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.bdr),
        boxShadow: [
          BoxShadow(
            color: AppColors.tx.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Imagen con overlay
          ClipRRect(
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(20)),
            child: SizedBox(
              height: 130,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  complejo.imagenPrincipal.isNotEmpty
                      ? Image.network(
                          complejo.imagenPrincipal,
                          fit: BoxFit.cover,
                          errorBuilder: (ctx, err, st) => _placeholder(),
                        )
                      : _placeholder(),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          AppColors.tx.withValues(alpha: 0.72),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 10,
                    left: 12,
                    child: Text(
                      complejo.nombre,
                      style: GoogleFonts.bricolageGrotesque(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 9, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xE600C864),
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Text(
                        '● Disponible',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Metadata
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
            child: Row(
              children: [
                _meta(Icons.location_on_rounded, complejo.ciudad),
                const SizedBox(width: 10),
                _meta(Icons.access_time_rounded,
                    '${complejo.horarioApertura}–${complejo.horarioCierre}'),
                const Spacer(),
                const Icon(Icons.sports_soccer_rounded,
                    size: 11, color: AppColors.acc),
                const SizedBox(width: 3),
                Text(
                  '$canchaCount canchas',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.tx,
                  ),
                ),
              ],
            ),
          ),

          // Footer — botón "Ver canchas"
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                RichText(
                  text: TextSpan(
                    style: GoogleFonts.bricolageGrotesque(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: AppColors.tx,
                    ),
                    children: [
                      TextSpan(text: precioLabel),
                      TextSpan(
                        text: precioDesde != null ? ' / hr' : '',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w400,
                          color: AppColors.tx3,
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: onVerCanchas,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.acc,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 9),
                    minimumSize: Size.zero,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(11)),
                  ),
                  child: Text(
                    'Ver canchas',
                    style: GoogleFonts.outfit(
                        fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _placeholder() => Container(
        color: AppColors.sur2,
        child: const Center(
          child: Icon(Icons.sports_soccer_rounded,
              color: AppColors.acc, size: 48),
        ),
      );

  Widget _meta(IconData icon, String val) => Row(
        children: [
          Icon(icon, size: 11, color: AppColors.tx3),
          const SizedBox(width: 3),
          Text(val,
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 11, color: AppColors.tx2)),
        ],
      );
}
