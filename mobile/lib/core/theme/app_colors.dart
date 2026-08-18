import 'package:flutter/material.dart';

/// MailGuard Design System Color Tokens
/// Source: wireframe/mailguard/DESIGN.md
class AppColors {
  AppColors._();

  // ─── Primary (Vibrant Deep Blue / Indigo) ─────────────
  static const Color primary = Color(0xFF0F52BA);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color primaryContainer = Color(0xFF1E64D4);
  static const Color onPrimaryContainer = Color(0xFFFFFFFF);
  static const Color inversePrimary = Color(0xFF93C5FD);
  static const Color primaryFixed = Color(0xFFDBEAFE);
  static const Color primaryFixedDim = Color(0xFFBFDBFE);
  static const Color onPrimaryFixed = Color(0xFF1E3A8A);
  static const Color onPrimaryFixedVariant = Color(0xFF1E40AF);

  // ─── Secondary (Alert Amber / Orange) ──────────────────
  static const Color secondary = Color(0xFFD97706);
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color secondaryContainer = Color(0xFFFEF3C7);
  static const Color onSecondaryContainer = Color(0xFF92400E);
  static const Color secondaryFixed = Color(0xFFFDE68A);
  static const Color secondaryFixedDim = Color(0xFFFCD34D);
  static const Color onSecondaryFixed = Color(0xFF78350F);
  static const Color onSecondaryFixedVariant = Color(0xFF92400E);

  // ─── Tertiary (Slate Cyan / Steel) ─────────────────────
  static const Color tertiary = Color(0xFF0EA5E9);
  static const Color onTertiary = Color(0xFFFFFFFF);
  static const Color tertiaryContainer = Color(0xFFE0F2FE);
  static const Color onTertiaryContainer = Color(0xFF0369A1);
  static const Color tertiaryFixed = Color(0xFFBAE6FD);
  static const Color tertiaryFixedDim = Color(0xFF7DD3FC);
  static const Color onTertiaryFixed = Color(0xFF0C4A6E);
  static const Color onTertiaryFixedVariant = Color(0xFF0369A1);

  // ─── Error ─────────────────────────────────────────────
  static const Color error = Color(0xFFDC2626);
  static const Color onError = Color(0xFFFFFFFF);
  static const Color errorContainer = Color(0xFFFEE2E2);
  static const Color onErrorContainer = Color(0xFF991B1B);

  // ─── Surface & High-Contrast Text ─────────────────────
  static const Color surface = Color(0xFFF8FAFC);
  static const Color surfaceDim = Color(0xFFE2E8F0);
  static const Color surfaceBright = Color(0xFFFFFFFF);
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color surfaceContainerLow = Color(0xFFF1F5F9);
  static const Color surfaceContainer = Color(0xFFE2E8F0);
  static const Color surfaceContainerHigh = Color(0xFFCBD5E1);
  static const Color surfaceContainerHighest = Color(0xFF94A3B8);

  /// High Contrast Primary Text (Deep Slate / Dark Charcoal)
  static const Color onSurface = Color(0xFF0F172A);

  /// High Contrast Muted Text (Slate Grey)
  static const Color onSurfaceVariant = Color(0xFF475569);

  static const Color inverseSurface = Color(0xFF1E293B);
  static const Color inverseOnSurface = Color(0xFFF8FAFC);

  // ─── Outline ──────────────────────────────────────────
  static const Color outline = Color(0xFF94A3B8);
  static const Color outlineVariant = Color(0xFFCBD5E1);
  static const Color surfaceTint = Color(0xFF0F52BA);

  // ─── Background ───────────────────────────────────────
  static const Color background = Color(0xFFF8FAFC);
  static const Color onBackground = Color(0xFF0F172A);
  static const Color surfaceVariant = Color(0xFFE2E8F0);

  // ─── Semantic / Status Colors ─────────────────────────
  static const Color priorityHigh = Color(0xFFEF4444);
  static const Color onPriorityHigh = Color(0xFFFFFFFF);

  static const Color priorityMedium = Color(0xFFF59E0B);
  static const Color onPriorityMedium = Color(0xFFFFFFFF);

  static const Color priorityLow = Color(0xFF64748B);
  static const Color onPriorityLow = Color(0xFFFFFFFF);

  /// Application Status Colors
  static const Color statusApplied = Color(0xFF2563EB);
  static const Color statusInterview = Color(0xFF7C3AED);
  static const Color statusOffer = Color(0xFF059669);
  static const Color statusRejected = Color(0xFFDC2626);

  /// Category Colors
  static const Color categoryPlacement = Color(0xFF2563EB);
  static const Color categoryAcademic = Color(0xFF0284C7);
  static const Color categoryPersonal = Color(0xFF475569);
  static const Color categoryPromotions = Color(0xFFD97706);
  static const Color categoryOthers = Color(0xFF64748B);
}
