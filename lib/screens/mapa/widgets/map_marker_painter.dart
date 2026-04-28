import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Genera BitmapDescriptors personalizados para los pins del mapa.
class MapMarkerPainter {
  MapMarkerPainter._();

  static Future<BitmapDescriptor> pinNormal({
    required String precio,
    required String nombre,
  }) async {
    return _drawPin(
      bgColor: Colors.white,
      borderColor: const Color(0xFF1B5E3B),
      textColor: const Color(0xFF0F0F0E),
      label: 'S/$precio',
      subLabel: nombre,
    );
  }

  static Future<BitmapDescriptor> pinFlash({
    required String precio,
    required String countdown,
  }) async {
    return _drawPin(
      bgColor: const Color(0xFFF59E0B),
      borderColor: const Color(0xFFC05E00),
      textColor: Colors.white,
      label: '⚡ S/$precio',
      subLabel: countdown,
      isFlash: true,
    );
  }

  static Future<BitmapDescriptor> pinPartido({
    required String deporte,
    required String hora,
    required String progreso, // "4/10"
  }) async {
    return _drawPin(
      bgColor: const Color(0xFF1E40AF),
      borderColor: const Color(0xFF3B82F6),
      textColor: Colors.white,
      label: '$deporte $hora',
      subLabel: progreso,
    );
  }

  static Future<BitmapDescriptor> pinLleno() async {
    return _drawPin(
      bgColor: const Color(0xFFDC2626),
      borderColor: const Color(0xFF991B1B),
      textColor: Colors.white,
      label: 'Lleno',
      subLabel: '',
    );
  }

  static Future<BitmapDescriptor> _drawPin({
    required Color bgColor,
    required Color borderColor,
    required Color textColor,
    required String label,
    required String subLabel,
    bool isFlash = false,
  }) async {
    const w = 160.0;
    const h = 72.0;
    const tail = 12.0; // punta del pin

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    // Sombra
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.25)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(3, 3, w - 6, h - tail - 4),
        const Radius.circular(14),
      ),
      shadowPaint,
    );

    // Fondo del pin
    final bgPaint = Paint()..color = bgColor;
    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final body = RRect.fromRectAndRadius(
      const Rect.fromLTWH(0, 0, w, h - tail),
      const Radius.circular(14),
    );
    canvas.drawRRect(body, bgPaint);
    canvas.drawRRect(body, borderPaint);

    // Punta del pin
    final path = Path()
      ..moveTo(w / 2 - 8, h - tail)
      ..lineTo(w / 2, h)
      ..lineTo(w / 2 + 8, h - tail)
      ..close();
    canvas.drawPath(path, bgPaint);
    canvas.drawPath(path, borderPaint);

    // Texto principal
    final tp1 = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          color: textColor,
          fontSize: 15,
          fontWeight: FontWeight.w700,
          height: 1,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: w - 12);
    tp1.paint(canvas, Offset((w - tp1.width) / 2, 10));

    // Texto secundario
    if (subLabel.isNotEmpty) {
      final tp2 = TextPainter(
        text: TextSpan(
          text: subLabel,
          style: TextStyle(
            color: textColor.withValues(alpha: 0.85),
            fontSize: 11,
            fontWeight: FontWeight.w500,
            height: 1,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: w - 16);
      tp2.paint(canvas, Offset((w - tp2.width) / 2, 32));
    }

    final picture = recorder.endRecording();
    final img = await picture.toImage(w.toInt(), h.toInt());
    final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.bytes(bytes!.buffer.asUint8List());
  }
}
