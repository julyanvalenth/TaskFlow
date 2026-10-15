import 'package:flutter/material.dart';

/// Design tokens: warna, spacing, radius, durasi, gradient. Widget ambil
/// nilainya dari sini, jangan tulis angka atau warna langsung.
///
/// Palette Lumo: #021024, #052659, #5483B3, #7DA0CA, #C1E8FF.

abstract final class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
}

abstract final class AppRadius {
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double pill = 100;
}

abstract final class AppSurfaces {
  /// Latar belakang utama, navy paling gelap.
  static const Color background = Color(0xFF021024);

  static const Color card = Color(0xFF052042);

  /// Card surface yang sedikit lebih terang (hover / elevated).
  static const Color cardHover = Color(0xFF0A2D5A);

  /// Surface paling terang untuk elemen "raised".
  static const Color elevated = Color(0xFF052659);

  /// Surface kaca semi-transparan.
  static const Color glass = Color(0x0DC1E8FF); // 5% ice blue
  static const Color glassStrong = Color(0x24C1E8FF); // 14% ice blue

  /// Border card, sekitar 9% ice blue.
  static const Color cardBorder = Color(0x17C1E8FF);

  /// Border card saat hover, 15% ice blue.
  static const Color cardBorderHover = Color(0x26C1E8FF);

  /// Overlay gelap untuk modal / bottom sheet.
  static const Color scrim = Color(0xA6021024);

  static const Color sheet = Color(0xFF052042);

  /// Shimmer / skeleton loading base.
  static const Color shimmerBase = Color(0xFF04152E);
  static const Color shimmerHighlight = Color(0xFF0A2D5A);
}

abstract final class AppColors {
  /// Warna brand (seed Material 3).
  static const Color seed = Color(0xFF5483B3);

  /// Ice blue, warna utama Lumo.
  static const Color primary = Color(0xFFC1E8FF);
  static const Color primaryLight = Color(0xFFECF6FF);

  /// Steel blue.
  static const Color secondary = Color(0xFF7DA0CA);

  /// Ocean blue.
  static const Color tertiary = Color(0xFF5483B3);

  /// Peach/amber untuk api streak dan notifikasi.
  static const Color warm = Color(0xFFFFB27D);

  static const Color success = Color(0xFF34D399);

  static const Color warning = Color(0xFFFBBF24);

  static const Color error = Color(0xFFF87171);

  static const Color textPrimary = Color(0xFFECF6FF);

  static const Color textSecondary = Color(0xFFB9D4EC);

  static const Color textMuted = Color(0xFF7DA0CA);

  static const Color textSubtle = Color(0xFF5483B3);

  // Warna prioritas task.

  static const Color priorityLowLight = Color(0xFF15803D);
  static const Color priorityMediumLight = Color(0xFFA16207);
  static const Color priorityHighLight = Color(0xFFF97316);
  static const Color priorityUrgentLight = Color(0xFFB91C1C);

  static const Color priorityLowDark = Color(0xFF7DA0CA);
  static const Color priorityMediumDark = Color(0xFFC1E8FF);
  static const Color priorityHighDark = Color(0xFFC1E8FF);
  static const Color priorityUrgentDark = Color(0xFFF87171);

  // Ramp sekuensial untuk chart ordinal.

  static const List<Color> chartRampLight = [
    Color(0xFFC7D2FE),
    Color(0xFF818CF8),
    Color(0xFF4F46E5),
    Color(0xFF312E81),
  ];
  static const List<Color> chartRampDark = [
    Color(0xFFC1E8FF),
    Color(0xFF7DA0CA),
    Color(0xFF5483B3),
    Color(0xFFA0C4E4),
  ];

  /// Warna "selesai" pada donut dashboard.
  static const Color chartDoneLight = Color(0xFF4F46E5);
  static const Color chartDoneDark = Color(0xFF5483B3);
}

abstract final class AppGradients {
  /// Gradient tombol utama (ice blue).
  static const LinearGradient primary = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFC1E8FF), Color(0xFF8FB7DF)],
  );

  /// Versi lembut untuk chip terpilih.
  static const LinearGradient primarySubtle = LinearGradient(
    begin: Alignment(-0.3, -0.7),
    end: Alignment(0.5, 0.9),
    colors: [Color(0xFFC1E8FF), Color(0xFF7DA0CA)],
  );

  /// Ocean blue ke steel blue.
  static const LinearGradient accent = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF5483B3), Color(0xFF7DA0CA)],
  );

  static const LinearGradient success = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF34D399), Color(0xFF06B6D4)],
  );

  static const LinearGradient danger = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFF87171), Color(0xFFEC4899)],
  );

  /// Card background: navy to deep navy.
  static const LinearGradient cardNavy = LinearGradient(
    begin: Alignment(0.2, -0.3),
    end: Alignment(1.0, 1.0),
    colors: [Color(0xE6052659), Color(0xEB041832)],
  );

  /// Glow dekoratif di background.
  static const RadialGradient backgroundGlow = RadialGradient(
    center: Alignment(-0.5, -0.7),
    radius: 1.2,
    colors: [
      Color(0x385483B3),
      Color(0x00000000),
    ],
  );

  /// Card shimmer border.
  static const LinearGradient cardBorder = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0x335483B3),
      Color(0x14FFFFFF),
      Color(0x337DA0CA),
    ],
  );
}

/// Warna per kategori: dot, background badge, tint dan glow card.
class CategoryColorDef {
  const CategoryColorDef({
    required this.color,
    required this.soft,
    required this.tint,
    required this.glow,
  });

  final Color color;
  final Color soft;  // untuk badge bg
  final Color tint;  // card tint gradient start
  final Color glow;  // card shadow
}

abstract final class AppCategoryColors {
  static const List<CategoryColorDef> palette = [
    CategoryColorDef(
      color: Color(0xFFC1E8FF),
      soft: Color(0x24C1E8FF),
      tint: Color(0x29C1E8FF),
      glow: Color(0x1FC1E8FF),
    ),
    CategoryColorDef(
      color: Color(0xFF7DA0CA),
      soft: Color(0x2E7DA0CA),
      tint: Color(0x387DA0CA),
      glow: Color(0x247DA0CA),
    ),
    CategoryColorDef(
      color: Color(0xFF5483B3),
      soft: Color(0x385483B3),
      tint: Color(0x425483B3),
      glow: Color(0x295483B3),
    ),
    CategoryColorDef(
      color: Color(0xFFA0C4E4),
      soft: Color(0x26A0C4E4),
      tint: Color(0x2EA0C4E4),
      glow: Color(0x1FA0C4E4),
    ),
  ];

  /// Kembali ke awal palette kalau index melebihi panjangnya.
  static CategoryColorDef forIndex(int index) =>
      palette[index % palette.length];

  /// Index warna dari nama kategori. Sengaja tidak pakai hashCode karena
  /// hasilnya bisa beda antar sesi dan platform.
  static int indexForName(String? name) {
    if (name == null || name.isEmpty) return 0;
    var sum = 0;
    for (final unit in name.codeUnits) {
      sum = (sum + unit) % palette.length;
    }
    return sum;
  }

  static CategoryColorDef forName(String? name) =>
      palette[indexForName(name)];
}

/// Varian kartu "Today Task" lama, dipertahankan untuk kompatibilitas.
class TodayCardVariant {
  const TodayCardVariant({required this.gradient, required this.glow});

  final LinearGradient gradient;
  final Color glow;
}

abstract final class AppCardVariants {
  static const List<TodayCardVariant> today = [
    TodayCardVariant(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF0B2A52), Color(0xFF041832)],
      ),
      glow: Color(0xFFC1E8FF),
    ),
    TodayCardVariant(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF123A6E), Color(0xFF052042)],
      ),
      glow: Color(0xFF7DA0CA),
    ),
    TodayCardVariant(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF0D3058), Color(0xFF041832)],
      ),
      glow: Color(0xFF5483B3),
    ),
  ];
}

abstract final class AppShadows {
  /// Subtle glow di bawah card.
  static final List<BoxShadow> cardGlow = [
    BoxShadow(
      color: const Color(0xFF5483B3).withValues(alpha: 0.08),
      blurRadius: 24,
      offset: const Offset(0, 8),
    ),
  ];

  /// Glow untuk elemen yang di-highlight (FAB, active nav item).
  static final List<BoxShadow> accentGlow = [
    BoxShadow(
      color: const Color(0xFF7DA0CA).withValues(alpha: 0.55),
      blurRadius: 30,
      offset: const Offset(0, 10),
    ),
  ];

  /// Glow untuk FAB.
  static final List<BoxShadow> fabGlow = [
    BoxShadow(
      color: const Color(0xFF7DA0CA).withValues(alpha: 0.55),
      blurRadius: 30,
      offset: const Offset(0, 10),
    ),
    BoxShadow(
      color: const Color(0xFFC1E8FF).withValues(alpha: 0.08),
      blurRadius: 8,
      spreadRadius: 6,
    ),
  ];

  /// Glow untuk button pressed state.
  static final List<BoxShadow> buttonGlow = [
    BoxShadow(
      color: const Color(0xFF7DA0CA).withValues(alpha: 0.5),
      blurRadius: 34,
      offset: const Offset(0, 12),
    ),
  ];
}

/// Priority visual style for Lumo UI.
class PriorityStyle {
  const PriorityStyle({required this.fg, required this.bg});
  final Color fg;
  final Color bg;
}

abstract final class AppPriorityStyles {
  static const PriorityStyle high = PriorityStyle(
    fg: Color(0xFF021024),
    bg: Color(0xFFC1E8FF),
  );
  static const PriorityStyle medium = PriorityStyle(
    fg: Color(0xFFC1E8FF),
    bg: Color(0x595483B3),
  );
  static const PriorityStyle low = PriorityStyle(
    fg: Color(0xFF7DA0CA),
    bg: Color(0x247DA0CA),
  );
  static const PriorityStyle urgent = PriorityStyle(
    fg: Color(0xFF021024),
    bg: Color(0xFFF87171),
  );
}

abstract final class AppDurations {
  static const Duration searchDebounce = Duration(milliseconds: 400);
  static const Duration microAnimation = Duration(milliseconds: 200);
  static const Duration pageTransition = Duration(milliseconds: 350);
  static const Duration progressAnimation = Duration(milliseconds: 800);
  static const Duration sheetAnimation = Duration(milliseconds: 280);
}
