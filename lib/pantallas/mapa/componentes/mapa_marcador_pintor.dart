import 'package:flutter/material.dart';

import '../../../nucleo/tema/app_colores.dart';

/// Marcadores Widget para flutter_map — sin async, sin BitmapDescriptor.
class MapMarkerPainter {
  MapMarkerPainter._();

  static Widget pinNormal({
    required String precio,
    required String nombre,
  }) =>
      _PinWidget(
        label: 'S/$precio',
        subLabel: nombre,
        bgColor: Colors.white,
        borderColor: AppColors.acc,
        textColor: AppColors.tx,
      );

  static Widget pinFlash({
    required String precio,
    required String countdown,
  }) =>
      _PinWidget(
        label: '⚡ S/$precio',
        subLabel: countdown,
        bgColor: AppColors.flashPin,
        borderColor: AppColors.flash,
        textColor: Colors.white,
      );

  static Widget pinPartido({
    required String deporte,
    required String hora,
    required String progreso,
  }) =>
      _PinWidget(
        label: '$deporte $hora',
        subLabel: progreso,
        bgColor: AppColors.party,
        borderColor: AppColors.party2,
        textColor: Colors.white,
      );

  static Widget pinLleno() => const _PinWidget(
        label: 'Lleno',
        subLabel: '',
        bgColor: AppColors.errorRed,
        borderColor: Color(0xFF991B1B),
        textColor: Colors.white,
      );

  static Widget pinUsuario() => Container(
        width: 18,
        height: 18,
        decoration: BoxDecoration(
          color: AppColors.acc,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2.5),
          boxShadow: [
            BoxShadow(
              color: AppColors.acc.withValues(alpha: 0.4),
              blurRadius: 8,
            ),
          ],
        ),
      );
}

class _PinWidget extends StatelessWidget {
  final String label;
  final String subLabel;
  final Color bgColor;
  final Color borderColor;
  final Color textColor;

  const _PinWidget({
    required this.label,
    required this.subLabel,
    required this.bgColor,
    required this.borderColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: borderColor, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: textColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  height: 1.1,
                ),
              ),
              if (subLabel.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  subLabel,
                  style: TextStyle(
                    color: textColor.withValues(alpha: 0.8),
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    height: 1.1,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
        CustomPaint(
          size: const Size(12, 6),
          painter: _TrianglePainter(color: bgColor, borderColor: borderColor),
        ),
      ],
    );
  }
}

class _TrianglePainter extends CustomPainter {
  final Color color;
  final Color borderColor;

  const _TrianglePainter({required this.color, required this.borderColor});

  @override
  void paint(Canvas canvas, Size size) {
    final fill = Paint()..color = color;
    final border = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(size.width, 0)
      ..close();

    canvas.drawPath(path, fill);
    canvas.drawPath(path, border);
  }

  @override
  bool shouldRepaint(_TrianglePainter old) =>
      old.color != color || old.borderColor != borderColor;
}
