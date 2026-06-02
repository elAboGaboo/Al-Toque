import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colores.dart';

class AppTheme {
  AppTheme._();

  static TextTheme get _textTheme => TextTheme(
        displayLarge: GoogleFonts.bricolageGrotesque(
          fontSize: 54, fontWeight: FontWeight.w700, color: AppColors.tx, letterSpacing: -2.5,
        ),
        displayMedium: GoogleFonts.bricolageGrotesque(
          fontSize: 34, fontWeight: FontWeight.w700, color: AppColors.tx, letterSpacing: -1,
        ),
        displaySmall: GoogleFonts.bricolageGrotesque(
          fontSize: 24, fontWeight: FontWeight.w600, color: AppColors.tx,
        ),
        headlineLarge: GoogleFonts.bricolageGrotesque(
          fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.tx,
        ),
        headlineMedium: GoogleFonts.bricolageGrotesque(
          fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.tx,
        ),
        headlineSmall: GoogleFonts.bricolageGrotesque(
          fontSize: 17, fontWeight: FontWeight.w600, color: AppColors.tx,
        ),
        bodyLarge: GoogleFonts.plusJakartaSans(
          fontSize: 16, fontWeight: FontWeight.w400, color: AppColors.tx,
        ),
        bodyMedium: GoogleFonts.plusJakartaSans(
          fontSize: 14, fontWeight: FontWeight.w400, color: AppColors.tx2,
        ),
        bodySmall: GoogleFonts.plusJakartaSans(
          fontSize: 12, fontWeight: FontWeight.w300, color: AppColors.tx3,
        ),
        labelLarge: GoogleFonts.plusJakartaSans(
          fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.tx,
        ),
        labelMedium: GoogleFonts.plusJakartaSans(
          fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.tx2,
        ),
        labelSmall: GoogleFonts.plusJakartaSans(
          fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.tx3, letterSpacing: 1.5,
        ),
      );

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.acc,
          brightness: Brightness.light,
          surface: AppColors.sur,
          onSurface: AppColors.tx,
        ),
        scaffoldBackgroundColor: AppColors.bg,
        textTheme: _textTheme,
        appBarTheme: AppBarTheme(
          backgroundColor: AppColors.bg,
          foregroundColor: AppColors.tx,
          elevation: 0,
          scrolledUnderElevation: 0,
          systemOverlayStyle: SystemUiOverlayStyle.dark,
          titleTextStyle: GoogleFonts.bricolageGrotesque(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.tx,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.acc,
            foregroundColor: AppColors.sur,
            minimumSize: const Size.fromHeight(56),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            textStyle: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.acc,
            side: const BorderSide(color: AppColors.bdr2, width: 1.5),
            minimumSize: const Size.fromHeight(56),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            textStyle: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        chipTheme: ChipThemeData(
          backgroundColor: AppColors.sur,
          selectedColor: AppColors.tx,
          secondaryLabelStyle: const TextStyle(color: AppColors.sur),
          labelStyle: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w500),
          side: const BorderSide(color: AppColors.bdr2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.sur,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.bdr2),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.bdr2),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.acc, width: 1.5),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        cardTheme: CardThemeData(
          color: AppColors.sur,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: AppColors.bdr),
          ),
        ),
        dividerTheme: const DividerThemeData(
          color: AppColors.bdr,
          thickness: 1,
        ),
        bottomSheetTheme: const BottomSheetThemeData(
          backgroundColor: AppColors.sur,
          modalBackgroundColor: AppColors.sur,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
        ),
      );

  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.abg,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.aacc,
          brightness: Brightness.dark,
          surface: AppColors.asur,
        ),
        textTheme: _textTheme.apply(
          bodyColor: AppColors.atx,
          displayColor: AppColors.atx,
          decorationColor: AppColors.atx,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.aacc,
            foregroundColor: AppColors.abg,
            minimumSize: const Size.fromHeight(56),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            textStyle: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: AppColors.abg,
          systemOverlayStyle: SystemUiOverlayStyle.light,
          elevation: 0,
          titleTextStyle: GoogleFonts.bricolageGrotesque(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.atx,
          ),
        ),
      );
}
