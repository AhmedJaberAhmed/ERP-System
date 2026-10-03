import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Semantic colours used across the app (status chips, KPIs, stock movement).
/// Tuned to read well on both the light and the dark theme.
class AppColors {
  AppColors._();

  static const brand = Color(0xFF635BFF); // Stripe-style indigo

  static const success = Color(0xFF12A150);
  static const warning = Color(0xFFE8890C);
  static const danger = Color(0xFFE5484D);
  static const info = Color(0xFF2F7CF6);
  static const neutral = Color(0xFF6B7280);
}

/// One place for the whole look of the app.
///
/// Inspired by modern business apps (Stripe / Revolut / Notion):
/// soft grey canvas, white surfaces with hairline borders instead of shadows,
/// generous rounding, pill chips, and a proper dark mode.
class AppTheme {
  AppTheme._();

  static const _radius = 14.0;
  static const _fieldRadius = 12.0;

  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness b) {
    final isDark = b == Brightness.dark;

    final base = ColorScheme.fromSeed(
      seedColor: AppColors.brand,
      brightness: b,
    );

    final scheme = base.copyWith(
      primary: isDark ? const Color(0xFF8B85FF) : AppColors.brand,
      onPrimary: isDark ? const Color(0xFF14123A) : Colors.white,
      surface: isDark ? const Color(0xFF14161B) : Colors.white,
      onSurface: isDark ? const Color(0xFFE8EAEE) : const Color(0xFF0F1222),
      onSurfaceVariant:
          isDark ? const Color(0xFF9AA1AF) : const Color(0xFF5B6275),
      outline: isDark ? const Color(0xFF3A3F4B) : const Color(0xFFC9CDD6),
      outlineVariant: isDark ? const Color(0xFF272B34) : const Color(0xFFE6E8EE),
      error: AppColors.danger,
      surfaceContainerLowest: isDark ? const Color(0xFF0E1013) : Colors.white,
      surfaceContainerLow:
          isDark ? const Color(0xFF181B21) : const Color(0xFFFFFFFF),
      surfaceContainer:
          isDark ? const Color(0xFF1D2027) : const Color(0xFFF1F2F6),
      surfaceContainerHigh:
          isDark ? const Color(0xFF232731) : const Color(0xFFEBEDF3),
    );

    final canvas = isDark ? const Color(0xFF0E1013) : const Color(0xFFF6F7FB);
    final border = BorderSide(color: scheme.outlineVariant);

    // Sensible, slightly tighter typography (system font on every platform).
    final textTheme = (isDark ? Typography.material2021().white : Typography.material2021().black)
        .apply(bodyColor: scheme.onSurface, displayColor: scheme.onSurface)
        .copyWith(
          headlineMedium: const TextStyle(fontWeight: FontWeight.w700, letterSpacing: -0.6),
          headlineSmall: const TextStyle(fontWeight: FontWeight.w700, letterSpacing: -0.4),
          titleLarge: const TextStyle(fontWeight: FontWeight.w700, letterSpacing: -0.2),
          titleMedium: const TextStyle(fontWeight: FontWeight.w600),
          titleSmall: const TextStyle(fontWeight: FontWeight.w600),
          labelLarge: const TextStyle(fontWeight: FontWeight.w600),
        );

    OutlineInputBorder fieldBorder(Color c, [double w = 1]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(_fieldRadius),
          borderSide: BorderSide(color: c, width: w),
        );

    return ThemeData(
      useMaterial3: true,
      brightness: b,
      colorScheme: scheme,
      scaffoldBackgroundColor: canvas,
      canvasColor: canvas,
      textTheme: textTheme,
      // Compact on desktop/web, comfortable on touch devices.
      visualDensity: VisualDensity.adaptivePlatformDensity,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      splashFactory: InkSparkle.splashFactory,
      dividerTheme: DividerThemeData(color: scheme.outlineVariant, space: 1, thickness: 1),

      // iOS/macOS get the native swipe-back slide, others a smooth zoom.
      pageTransitionsTheme: const PageTransitionsTheme(builders: {
        TargetPlatform.android: ZoomPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
        TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
        TargetPlatform.linux: FadeUpwardsPageTransitionsBuilder(),
        TargetPlatform.fuchsia: ZoomPageTransitionsBuilder(),
      }),

      appBarTheme: AppBarTheme(
        backgroundColor: canvas,
        foregroundColor: scheme.onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: defaultTargetPlatform == TargetPlatform.iOS ||
            defaultTargetPlatform == TargetPlatform.macOS,
        titleTextStyle: textTheme.titleLarge,
      ),

      cardTheme: CardThemeData(
        color: scheme.surface,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        elevation: 0,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_radius),
          side: border,
        ),
      ),

      listTileTheme: ListTileThemeData(
        iconColor: scheme.onSurfaceVariant,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_radius)),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? scheme.surfaceContainer : Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: fieldBorder(scheme.outline),
        enabledBorder: fieldBorder(scheme.outlineVariant),
        focusedBorder: fieldBorder(scheme.primary, 1.6),
        errorBorder: fieldBorder(scheme.error),
        focusedErrorBorder: fieldBorder(scheme.error, 1.6),
        disabledBorder: fieldBorder(scheme.outlineVariant),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(64, 50),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_fieldRadius)),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(64, 50),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_fieldRadius)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(64, 50),
          side: BorderSide(color: scheme.outline),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_fieldRadius)),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_fieldRadius)),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),

      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        elevation: 2,
        highlightElevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),

      chipTheme: ChipThemeData(
        shape: const StadiumBorder(),
        side: BorderSide(color: scheme.outlineVariant),
        backgroundColor: scheme.surface,
        selectedColor: scheme.primary.withAlpha(36),
        labelStyle: textTheme.labelLarge,
      ),

      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isDark ? const Color(0xFF2A2E38) : const Color(0xFF1B1F2E),
        contentTextStyle: const TextStyle(color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        insetPadding: const EdgeInsets.all(16),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),

      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),

      popupMenuTheme: PopupMenuThemeData(
        color: scheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),

      progressIndicatorTheme: ProgressIndicatorThemeData(color: scheme.primary),
    );
  }
}
