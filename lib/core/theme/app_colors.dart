import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ── User flow ──────────────────────────────────────────────
  static const Color ink = Color(0xFF0F0F0E);
  static const Color ink2 = Color(0xFF5C5C58);
  static const Color ink3 = Color(0xFFA4A49C);
  static const Color paper = Color(0xFFF5F3EE);
  static const Color white = Color(0xFFFFFFFF);
  static const Color line = Color(0xFFECEAE3);

  static const Color green = Color(0xFF1B5E3B);
  static const Color green2 = Color(0xFF2D7A52);
  static const Color greenLight = Color(0xFFE8F5EE);

  // Flash Slots
  static const Color flash = Color(0xFFC05E00);
  static const Color flashLight = Color(0xFFFFF3E0);
  static const Color flashBg = Color(0xFFFFF7ED);
  static const Color flashPin = Color(0xFFF59E0B);

  // Armar Partido
  static const Color party = Color(0xFF1E40AF);
  static const Color party2 = Color(0xFF3B82F6);
  static const Color partyLight = Color(0xFFEFF6FF);

  // Errors
  static const Color errorRed = Color(0xFFDC2626);
  static const Color errorRedLight = Color(0xFFFEF2F2);

  // ── Admin dark theme ───────────────────────────────────────
  static const Color adminBg = Color(0xFF080C12);
  static const Color adminS1 = Color(0xFF0D1320);
  static const Color adminS2 = Color(0xFF121A2C);
  static const Color adminS3 = Color(0xFF1A2438);
  static const Color adminBorder = Color(0xFF1E293B);

  // Admin accent colors
  static const Color adminGreen = Color(0xFF64D28C);
  static const Color adminFlash = Color(0xFFFBA832);
  static const Color adminParty = Color(0xFF93C5FD);
  static const Color adminRed = Color(0xFFFF6464);

  // Backwards compat aliases
  static const Color green2Admin = Color(0xFF64D28C);
  static const Color flash2Admin = Color(0xFFFBA832);
  static const Color party2Admin = Color(0xFF93C5FD);

  // ── Demand level colors ────────────────────────────────────
  static const Color demandLow = Color(0xFF16A34A);
  static const Color demandMed = Color(0xFFD97706);
  static const Color demandHigh = Color(0xFFDC2626);

  // ── Slot state colors ──────────────────────────────────────
  static const Color slotFree = Color(0xFF1B5E3B);
  static const Color slotBooked = Color(0xFF6B7280);
  static const Color slotFlash = Color(0xFFF59E0B);
  static const Color slotParty = Color(0xFF3B82F6);
  static const Color slotClosed = Color(0xFF1F2937);
}
