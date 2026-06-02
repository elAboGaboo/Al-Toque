// screens/admin/admin_usuarios_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../nucleo/tema/app_colores.dart';
import '../../modelos/usuario_modelo.dart';
import '../../proveedores/auth_proveedor.dart';

/// Stream de todos los usuarios (admin only).
final _usuariosStreamProvider =
    StreamProvider.autoDispose<List<UsuarioModel>>((ref) {
  return FirebaseFirestore.instance
      .collection('usuarios')
      .snapshots()
      .map((s) => s.docs.map(UsuarioModel.fromFirestore).toList());
});

class AdminUsuariosScreen extends ConsumerWidget {
  const AdminUsuariosScreen({super.key});

  Future<void> _confirmarLogout(BuildContext context, WidgetRef ref) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.asur,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: Text(
          '¿Cerrar sesión?',
          style: GoogleFonts.bricolageGrotesque(
            fontWeight: FontWeight.w700,
            color: AppColors.atx,
          ),
        ),
        content: Text(
          'Saldrás del panel de administración.',
          style: GoogleFonts.plusJakartaSans(
              fontSize: 13, color: AppColors.atx2),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('Cancelar',
                style: GoogleFonts.outfit(color: AppColors.atx2)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text('Cerrar sesión',
                style: GoogleFonts.outfit(
                    color: AppColors.ared,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
    if (confirmar == true) {
      await ref.read(authNotifierProvider.notifier).logout();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usuariosAsync = ref.watch(_usuariosStreamProvider);

    return Scaffold(
      backgroundColor: AppColors.abg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Usuarios',
                          style: GoogleFonts.bricolageGrotesque(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: AppColors.atx,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        usuariosAsync.when(
                          loading: () => Text(
                            'Cargando...',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              color: AppColors.atx2,
                            ),
                          ),
                          error: (_, _) => Text(
                            'No se pudieron cargar',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              color: AppColors.ared,
                            ),
                          ),
                          data: (list) => Text(
                            '${list.length} usuarios registrados',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              color: AppColors.atx2,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Botón cerrar sesión
                  GestureDetector(
                    onTap: () => _confirmarLogout(context, ref),
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: AppColors.ared.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: AppColors.ared.withValues(alpha: 0.25)),
                      ),
                      child: const Icon(
                        Icons.logout_rounded,
                        color: AppColors.ared,
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: usuariosAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(color: AppColors.aacc),
                ),
                error: (e, _) => Center(
                  child: Text(
                    'Error: $e',
                    style: GoogleFonts.plusJakartaSans(
                      color: AppColors.ared,
                    ),
                  ),
                ),
                data: (list) {
                  if (list.isEmpty) {
                    return Center(
                      child: Text(
                        'Sin usuarios todavía',
                        style: GoogleFonts.plusJakartaSans(
                          color: AppColors.atx3,
                        ),
                      ),
                    );
                  }
                  // Admins primero, luego jugadores por nombre
                  final ordenados = [...list]..sort((a, b) {
                      if (a.esDueno != b.esDueno) {
                        return a.esDueno ? -1 : 1;
                      }
                      return a.nombre.compareTo(b.nombre);
                    });
                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                    itemCount: ordenados.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (_, i) => _UsuarioCard(usuario: ordenados[i]),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UsuarioCard extends StatelessWidget {
  final UsuarioModel usuario;
  const _UsuarioCard({required this.usuario});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.asur,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.abdr),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: usuario.esDueno
                    ? [AppColors.ablu, const Color(0xFF1D4ED8)]
                    : [AppColors.aacc, AppColors.aacc2],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                usuario.iniciales,
                style: GoogleFonts.bricolageGrotesque(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: Colors.black,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        usuario.nombre,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.atx,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    if (usuario.esDueno)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.ablu.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'ADMIN',
                          style: GoogleFonts.bricolageGrotesque(
                            fontSize: 8,
                            fontWeight: FontWeight.w800,
                            color: AppColors.ablu,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  usuario.email,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    color: AppColors.atx2,
                  ),
                ),
                if (usuario.esJugador && usuario.dni.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(Icons.badge_outlined,
                          size: 11,
                          color: AppColors.atx3),
                      const SizedBox(width: 3),
                      Text(
                        'DNI ${usuario.dni}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.aacc,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: usuario.esDueno
                  ? AppColors.ablu.withValues(alpha: 0.12)
                  : AppColors.aacc.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              usuario.esDueno ? 'Dueño' : 'Jugador',
              style: GoogleFonts.outfit(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: usuario.esDueno ? AppColors.ablu : AppColors.aacc,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

