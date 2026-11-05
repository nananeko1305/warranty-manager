import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_colors.dart';

/// Component styling for the palette in [AppColors]. Widgets read colors via
/// `context.colors`, never from static getters, so they repaint when the mode
/// changes.
class AppTheme {
  static ThemeData get light => build(dark: false);
  static ThemeData get dark => build(dark: true);

  static ThemeData build({required bool dark}) {
    final c = dark ? AppColors.dark : AppColors.light;
    final scheme =
        ColorScheme.fromSeed(
          seedColor: c.primary,
          brightness: dark ? Brightness.dark : Brightness.light,
        ).copyWith(
          primary: c.primary,
          onPrimary: c.onPrimary,
          secondaryContainer: c.soft,
          onSecondaryContainer: c.ink,
          surface: c.background,
          onSurface: c.ink,
          error: c.danger,
        );

    final base = ThemeData(useMaterial3: true, colorScheme: scheme);

    return base.copyWith(
      extensions: [c],
      scaffoldBackgroundColor: c.background,
      textTheme: base.textTheme.apply(bodyColor: c.ink, displayColor: c.ink),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        foregroundColor: c.ink,
        elevation: 0,
        centerTitle: false,
        // The bar is transparent, so Flutter can't infer the status-bar
        // icon color from it; set it from the mode explicitly.
        systemOverlayStyle: overlayStyle(dark),
        titleTextStyle: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w800,
          color: c.ink,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: c.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        margin: EdgeInsets.zero,
      ),
      dialogTheme: DialogThemeData(backgroundColor: c.surface),
      bottomSheetTheme: BottomSheetThemeData(backgroundColor: c.surface),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: c.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: _border(c.primary.withValues(alpha: 0.25)),
        enabledBorder: _border(c.primary.withValues(alpha: 0.25)),
        focusedBorder: _border(c.primary, width: 2),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: c.primary,
          foregroundColor: c.onPrimary,
          minimumSize: const Size.fromHeight(54),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: c.primary,
        foregroundColor: c.onPrimary,
        elevation: 2,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: c.ink,
        contentTextStyle: TextStyle(color: c.background),
        actionTextColor: c.soft,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  /// Status and navigation bar icons: dark on the light theme, light on
  /// the dark theme, over a transparent bar.
  static SystemUiOverlayStyle overlayStyle(bool dark) =>
      (dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark).copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Colors.transparent,
      );

  static OutlineInputBorder _border(Color color, {double width = 1.5}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: color, width: width),
    );
  }
}
