import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppPalette {
  static const Color primary = Color(0xFF1E6BFF);
  static const Color cyan = Color(0xFF18C8E8);
  static const Color purple = Color(0xFF8057FF);
  static const Color violet = Color(0xFFB05CFF);
  static const Color ink = Color(0xFF111827);
  static const Color muted = Color(0xFF667085);
  static const Color darkInk = Color(0xFFEAF2FF);
  static const Color darkMuted = Color(0xFFB7C6D9);
  static const Color darkSurface = Color(0xFF07111F);
  static const Color darkCard = Color(0xFF101D2E);
  static const Color softBlue = Color(0xFFEAF5FF);
  static const Color softCyan = Color(0xFFE7FBFF);
  static const Color softPurple = Color(0xFFF2E9FF);
  static const Color success = Color(0xFF16A34A);
  static const Color warning = Color(0xFFF59E0B);
  static const Color danger = Color(0xFFE11D48);
  static const Color surface = Color(0xFFF7FBFF);
  static const Color white = Colors.white;

  static const LinearGradient appGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFEAF5FF), Color(0xFFF7FCFF), Color(0xFFF3E8FF)],
  );

  static const LinearGradient darkAppGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF061221), Color(0xFF0C1B32), Color(0xFF1A0F2E)],
  );

  static const LinearGradient premiumGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, cyan, purple],
  );

  static const LinearGradient cyanGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF00B8D9), Color(0xFF2364FF)],
  );

  static const LinearGradient purpleGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF7C3AED), Color(0xFFA855F7)],
  );
}

class AppTheme {
  static ThemeData get light => _build(Brightness.light);
  static ThemeData get dark => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final bool isDark = brightness == Brightness.dark;
    final ColorScheme scheme = ColorScheme.fromSeed(
      seedColor: AppPalette.primary,
      brightness: brightness,
      primary: AppPalette.primary,
      secondary: AppPalette.cyan,
      tertiary: AppPalette.purple,
      surface: isDark ? AppPalette.darkCard : AppPalette.white,
    );

    final ThemeData base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor:
          isDark ? AppPalette.darkSurface : AppPalette.surface,
    );

    return base.copyWith(
      textTheme: GoogleFonts.interTextTheme(base.textTheme).apply(
        bodyColor: isDark ? AppPalette.darkInk : AppPalette.ink,
        displayColor: isDark ? AppPalette.darkInk : AppPalette.ink,
      ),
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: isDark ? AppPalette.darkInk : AppPalette.ink,
      ),
      navigationBarTheme: NavigationBarThemeData(
        elevation: 0,
        backgroundColor: isDark
            ? AppPalette.darkCard.withValues(alpha: 0.94)
            : Colors.white.withValues(alpha: 0.94),
        indicatorColor: isDark
            ? AppPalette.primary.withValues(alpha: 0.18)
            : AppPalette.softBlue,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => GoogleFonts.inter(
            fontSize: 11,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w800
                : FontWeight.w600,
            color: states.contains(WidgetState.selected)
                ? AppPalette.primary
                : (isDark ? AppPalette.darkMuted : AppPalette.muted),
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? AppPalette.primary
                : (isDark ? AppPalette.darkMuted : AppPalette.muted),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? AppPalette.darkCard : Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: isDark ? Colors.white12 : Colors.blueGrey.shade100,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: isDark ? Colors.white12 : Colors.blueGrey.shade100,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppPalette.primary, width: 1.6),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w800),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w800),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        labelStyle: GoogleFonts.inter(fontWeight: FontWeight.w700),
        side: BorderSide.none,
      ),
    );
  }
}
