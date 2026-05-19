import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ── User flow (Light Premium) ────────────────────────────────
  static const Color bg = Color(0xFFF7F5F0);
  static const Color sur = Color(0xFFFFFFFF);
  static const Color sur2 = Color(0xFFF0EDE6);
  static const Color sur3 = Color(0xFFE8E4DC);
  
  static const Color acc = Color(0xFF1A6B3C);
  static const Color acc2 = Color(0xFF25A05A);
  static const Color accLight = Color(0xFFE6F4EC);
  
  static const Color tx = Color(0xFF0D1B0F);
  static const Color tx2 = Color(0xFF4A5568);
  static const Color tx3 = Color(0xFF8A9BAD);
  
  static const Color bdr = Color(0x140D1B0F); // rgba(13,27,15,0.08)
  static const Color bdr2 = Color(0x240D1B0F); // rgba(13,27,15,0.14)
  
  static const Color amber = Color(0xFFC97D1E);
  static const Color red = Color(0xFFC94040);
  static const Color blue = Color(0xFF2563EB);

  // ── Admin flow (Dark Premium) ────────────────────────────────
  static const Color abg = Color(0xFF080C12);
  static const Color asur = Color(0xFF0F1520);
  static const Color asur2 = Color(0xFF161D2E);
  static const Color asur3 = Color(0xFF1E2840);
  
  static const Color aacc = Color(0xFF00E87A);
  static const Color aacc2 = Color(0xFF00C466);
  static const Color aaccD = Color(0x1F00E87A); // rgba(0,232,122,0.12)
  static const Color aaccB = Color(0x4000E87A); // rgba(0,232,122,0.25)
  
  static const Color atx = Color(0xFFF0F4FF);
  static const Color atx2 = Color(0xFF8896B4);
  static const Color atx3 = Color(0xFF4A5672);
  
  static const Color abdr = Color(0x0FF0F4FF); // rgba(240,244,255,0.06)
  static const Color abdr2 = Color(0x1FF0F4FF); // rgba(240,244,255,0.12)
  
  static const Color aamber = Color(0xFFFFB547);
  static const Color ared = Color(0xFFFF6B6B);
  static const Color ablu = Color(0xFF5B8EFF);

  // ── Map Colors ──────────────────────────────────────────────
  static const Color mc1 = Color(0xFFEDE8DF);
  static const Color mc2 = Color(0xFFD8D2C4);
  static const Color mc3 = Color(0xFFC5DDB8);
  static const Color mc4 = Color(0xFFB5CCE0);
  static const Color mc5 = Color(0xFFE8E3D8);

  // Aliases para compatibilidad con código existente
  static const Color ink = tx;
  static const Color ink2 = tx2;
  static const Color ink3 = tx3;
  static const Color paper = bg;
  static const Color white = sur;
  static const Color line = bdr;
  static const Color green = acc;
  static const Color green2 = acc2;
  static const Color greenLight = accLight;
  static const Color flash = amber;
  static const Color flashLight = Color(0xFFFFF3E0);
  static const Color flashPin = amber;
  static const Color party = blue;
  static const Color party2 = Color(0xFF1D4ED8);
  static const Color partyLight = Color(0xFFEFF6FF);
  static const Color errorRed = red;
  static const Color errorRedLight = Color(0xFFFEE2E2);

  // Admin aliases
  static const Color adminBg = abg;
  static const Color adminS1 = asur;
  static const Color adminS2 = asur2;
  static const Color adminS3 = asur3;
  static const Color adminGreen = aacc;
  static const Color adminFlash = aamber;
  static const Color adminParty = ablu;
  static const Color adminBorder = abdr2;

  // Slot calendar colors
  static const Color slotFree = accLight;
  static const Color slotBooked = red;
  static const Color slotFlash = amber;
  static const Color slotParty = blue;

  // Demand indicator colors
  static const Color demandLow = acc;
  static const Color demandMed = amber;
  static const Color demandHigh = red;
}
