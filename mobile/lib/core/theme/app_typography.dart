import 'package:flutter/material.dart';
import 'app_colors.dart';

/// MailGuard Typography System with dynamic theme contrast support.
class AppTypography {
  AppTypography._();

  // ─── Headline Styles ──────────────────────────────────
  static const TextStyle headlineLg = TextStyle(
    inherit: true,
    fontFamily: 'Inter',
    fontSize: 32,
    fontWeight: FontWeight.w700,
    height: 1.25,
    letterSpacing: -0.64,
  );

  static const TextStyle headlineMd = TextStyle(
    inherit: true,
    fontFamily: 'Inter',
    fontSize: 24,
    fontWeight: FontWeight.w600,
    height: 1.333,
  );

  // ─── Title Styles ─────────────────────────────────────
  static const TextStyle titleLg = TextStyle(
    inherit: true,
    fontFamily: 'Inter',
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 1.4,
  );

  static const TextStyle titleMd = TextStyle(
    inherit: true,
    fontFamily: 'Inter',
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.5,
  );

  // ─── Body Styles ──────────────────────────────────────
  static const TextStyle bodyLg = TextStyle(
    inherit: true,
    fontFamily: 'Inter',
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  static const TextStyle bodyMd = TextStyle(
    inherit: true,
    fontFamily: 'Inter',
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.428,
  );

  // ─── Label Styles ─────────────────────────────────────
  static const TextStyle labelLg = TextStyle(
    inherit: true,
    fontFamily: 'Inter',
    fontSize: 12,
    fontWeight: FontWeight.w700,
    height: 1.333,
    letterSpacing: 0.5,
  );

  static const TextStyle labelMd = TextStyle(
    inherit: true,
    fontFamily: 'Inter',
    fontSize: 11,
    fontWeight: FontWeight.w600,
    height: 1.454,
  );

  // ─── Material 3 Light TextTheme ─────────────────────────────
  static const TextTheme lightTextTheme = TextTheme(
    displayLarge: TextStyle(fontFamily: 'Inter', fontSize: 32, fontWeight: FontWeight.w700, color: AppColors.onSurface),
    displayMedium: TextStyle(fontFamily: 'Inter', fontSize: 24, fontWeight: FontWeight.w600, color: AppColors.onSurface),
    headlineLarge: TextStyle(fontFamily: 'Inter', fontSize: 32, fontWeight: FontWeight.w700, color: AppColors.onSurface),
    headlineMedium: TextStyle(fontFamily: 'Inter', fontSize: 24, fontWeight: FontWeight.w600, color: AppColors.onSurface),
    titleLarge: TextStyle(fontFamily: 'Inter', fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.onSurface),
    titleMedium: TextStyle(fontFamily: 'Inter', fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.onSurface),
    bodyLarge: TextStyle(fontFamily: 'Inter', fontSize: 16, fontWeight: FontWeight.w400, color: AppColors.onSurface),
    bodyMedium: TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w400, color: AppColors.onSurface),
    labelLarge: TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.onSurface),
    labelMedium: TextStyle(fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.onSurface),
    labelSmall: TextStyle(fontFamily: 'Inter', fontSize: 10, fontWeight: FontWeight.w500, color: AppColors.onSurfaceVariant),
  );

  // ─── Material 3 Dark TextTheme (Crisp High Contrast Light Text) ───
  static const TextTheme darkTextTheme = TextTheme(
    displayLarge: TextStyle(fontFamily: 'Inter', fontSize: 32, fontWeight: FontWeight.w700, color: Color(0xFFF8FAFC)),
    displayMedium: TextStyle(fontFamily: 'Inter', fontSize: 24, fontWeight: FontWeight.w600, color: Color(0xFFF8FAFC)),
    headlineLarge: TextStyle(fontFamily: 'Inter', fontSize: 32, fontWeight: FontWeight.w700, color: Color(0xFFF8FAFC)),
    headlineMedium: TextStyle(fontFamily: 'Inter', fontSize: 24, fontWeight: FontWeight.w600, color: Color(0xFFF8FAFC)),
    titleLarge: TextStyle(fontFamily: 'Inter', fontSize: 20, fontWeight: FontWeight.w600, color: Color(0xFFF8FAFC)),
    titleMedium: TextStyle(fontFamily: 'Inter', fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFFF8FAFC)),
    bodyLarge: TextStyle(fontFamily: 'Inter', fontSize: 16, fontWeight: FontWeight.w400, color: Color(0xFFE2E8F0)),
    bodyMedium: TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w400, color: Color(0xFFE2E8F0)),
    labelLarge: TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFFCBD5E1)),
    labelMedium: TextStyle(fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF94A3B8)),
    labelSmall: TextStyle(fontFamily: 'Inter', fontSize: 10, fontWeight: FontWeight.w500, color: Color(0xFF94A3B8)),
  );

  static const TextTheme textTheme = lightTextTheme;
}
