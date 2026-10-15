import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_tokens.dart';

/// Tema Lumo. Dark theme pakai Sora untuk heading, Manrope untuk body, dan
/// palette navy. Light theme hanya fallback.
abstract final class AppTheme {
  static ThemeData get light => _buildLight();
  static ThemeData get dark => _buildDark();

  static ThemeData _buildDark() {
    // Manrope as base text theme, Sora applied to specific headline styles.
    final baseText = GoogleFonts.manropeTextTheme(
      ThemeData.dark().textTheme,
    );

    final textTheme = baseText.copyWith(
      headlineLarge: GoogleFonts.sora(
        textStyle: baseText.headlineLarge,
        fontWeight: FontWeight.w800,
      ),
      headlineMedium: GoogleFonts.sora(
        textStyle: baseText.headlineMedium,
        fontWeight: FontWeight.w800,
      ),
      headlineSmall: GoogleFonts.sora(
        textStyle: baseText.headlineSmall,
        fontWeight: FontWeight.w700,
      ),
      titleLarge: GoogleFonts.sora(
        textStyle: baseText.titleLarge,
        fontWeight: FontWeight.w700,
      ),
      titleMedium: GoogleFonts.sora(
        textStyle: baseText.titleMedium,
        fontWeight: FontWeight.w700,
      ),
      titleSmall: GoogleFonts.sora(
        textStyle: baseText.titleSmall,
        fontWeight: FontWeight.w700,
      ),
    );

    final scheme = ColorScheme.dark(
      primary: AppColors.primary,
      onPrimary: const Color(0xFF021024),
      primaryContainer: AppColors.primary.withValues(alpha: 0.2),
      onPrimaryContainer: AppColors.primaryLight,
      secondary: AppColors.secondary,
      onSecondary: const Color(0xFF021024),
      secondaryContainer: AppColors.secondary.withValues(alpha: 0.2),
      onSecondaryContainer: AppColors.primaryLight,
      tertiary: AppColors.tertiary,
      onTertiary: Colors.white,
      surface: AppSurfaces.background,
      onSurface: AppColors.textPrimary,
      onSurfaceVariant: AppColors.textMuted,
      error: AppColors.error,
      onError: Colors.white,
      errorContainer: AppColors.error.withValues(alpha: 0.15),
      onErrorContainer: AppColors.error,
      outline: const Color(0x33FFFFFF),
      outlineVariant: AppSurfaces.cardBorder,
      surfaceContainerHighest: AppSurfaces.elevated,
    );

    final base = ThemeData(
      colorScheme: scheme,
      useMaterial3: true,
      brightness: Brightness.dark,
      textTheme: textTheme,
      scaffoldBackgroundColor: AppSurfaces.background,
    );

    return base.copyWith(
      appBarTheme: AppBarTheme(
        centerTitle: false,
        backgroundColor: AppSurfaces.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
      ),

      cardTheme: base.cardTheme.copyWith(
        elevation: 0,
        color: AppSurfaces.card,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: const BorderSide(color: AppSurfaces.cardBorder),
        ),
        margin: EdgeInsets.zero,
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppSurfaces.glass,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AppSurfaces.cardBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AppSurfaces.cardBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AppColors.tertiary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: AppColors.error.withValues(alpha: 0.6)),
        ),
        hintStyle: textTheme.bodyLarge?.copyWith(color: AppColors.textSubtle),
        labelStyle: textTheme.bodyLarge?.copyWith(color: AppColors.textMuted),
        prefixIconColor: AppColors.textSubtle,
        suffixIconColor: AppColors.textSubtle,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md + 2,
          vertical: AppSpacing.sm + AppSpacing.xs,
        ),
      ),

      chipTheme: base.chipTheme.copyWith(
        backgroundColor: AppSurfaces.glass,
        selectedColor: AppColors.primary.withValues(alpha: 0.2),
        side: const BorderSide(color: AppSurfaces.cardBorder),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        labelStyle:
            textTheme.labelMedium?.copyWith(color: AppColors.textPrimary),
        secondaryLabelStyle:
            textTheme.labelMedium?.copyWith(color: AppColors.textPrimary),
        checkmarkColor: AppColors.primary,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          backgroundColor: AppColors.primary,
          foregroundColor: const Color(0xFF021024),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(26),
          ),
          textStyle: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
          elevation: 0,
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.secondary,
          side: BorderSide(color: AppColors.secondary.withValues(alpha: 0.3)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(26),
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.secondary,
        ),
      ),

      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppSurfaces.card,
        surfaceTintColor: Colors.transparent,
        indicatorColor: AppColors.primary.withValues(alpha: 0.2),
        elevation: 0,
        height: 72,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: AppColors.primary, size: 24);
          }
          return const IconThemeData(color: AppColors.textMuted, size: 24);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return textTheme.labelSmall?.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            );
          }
          return textTheme.labelSmall?.copyWith(color: AppColors.textMuted);
        }),
      ),

      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return AppColors.primary.withValues(alpha: 0.2);
            }
            return AppSurfaces.card;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return AppColors.primary;
            }
            return AppColors.textMuted;
          }),
          side: WidgetStateProperty.all(
            const BorderSide(color: AppSurfaces.cardBorder),
          ),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
          ),
        ),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: AppSurfaces.elevated,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          side: const BorderSide(color: AppSurfaces.cardBorder),
        ),
      ),

      snackBarTheme: base.snackBarTheme.copyWith(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppSurfaces.elevated,
        contentTextStyle:
            textTheme.bodyMedium?.copyWith(color: AppColors.textPrimary),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          side: const BorderSide(color: AppSurfaces.cardBorder),
        ),
      ),

      checkboxTheme: base.checkboxTheme.copyWith(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primary;
          }
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(const Color(0xFF021024)),
        side: const BorderSide(color: AppColors.textSubtle, width: 1.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
        ),
      ),

      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppSurfaces.sheet,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
      ),

      dividerTheme: const DividerThemeData(
        color: AppSurfaces.cardBorder,
        thickness: 1,
      ),

      popupMenuTheme: PopupMenuThemeData(
        color: AppSurfaces.elevated,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: const BorderSide(color: AppSurfaces.cardBorder),
        ),
      ),

      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: const Color(0xFF021024),
        elevation: 0,
        highlightElevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
      ),

      datePickerTheme: DatePickerThemeData(
        backgroundColor: AppSurfaces.elevated,
        surfaceTintColor: Colors.transparent,
        headerBackgroundColor: AppSurfaces.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
        ),
      ),
      timePickerTheme: TimePickerThemeData(
        backgroundColor: AppSurfaces.elevated,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
        ),
      ),
    );
  }

  static ThemeData _buildLight() {
    final textTheme = GoogleFonts.manropeTextTheme(
      ThemeData.light().textTheme,
    ).copyWith(
      headlineLarge: GoogleFonts.sora(fontWeight: FontWeight.w800),
      headlineMedium: GoogleFonts.sora(fontWeight: FontWeight.w800),
      headlineSmall: GoogleFonts.sora(fontWeight: FontWeight.w700),
      titleLarge: GoogleFonts.sora(fontWeight: FontWeight.w700),
      titleMedium: GoogleFonts.sora(fontWeight: FontWeight.w700),
      titleSmall: GoogleFonts.sora(fontWeight: FontWeight.w700),
    );
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.seed,
      brightness: Brightness.light,
    );
    final base = ThemeData(
      colorScheme: scheme,
      useMaterial3: true,
      textTheme: textTheme,
    );
    return base.copyWith(
      appBarTheme: AppBarTheme(
        centerTitle: false,
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm + AppSpacing.xs,
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
      ),
      cardTheme: base.cardTheme.copyWith(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          side: BorderSide(color: scheme.outlineVariant),
        ),
        margin: EdgeInsets.zero,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
        ),
      ),
      snackBarTheme: base.snackBarTheme.copyWith(
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
