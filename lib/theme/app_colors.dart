import 'package:flutter/material.dart';

/// The "Pine & Paper" palette: a deep pine on warm paper, like a receipt.
///
/// Carried by the [ThemeData], so that every widget reading it through
/// `context.colors` rebuilds when light or dark mode changes. All text pairs
/// meet WCAG AA, which the theme tests check.
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.primary,
    required this.onPrimary,
    required this.soft,
    required this.background,
    required this.surface,
    required this.ink,
    required this.warning,
    required this.warningBar,
    required this.danger,
  });

  static const light = AppColors(
    primary: Color(0xFF0F6B5F),
    onPrimary: Color(0xFFFFFFFF),
    soft: Color(0xFFDCEFE9),
    background: Color(0xFFF8F6F1),
    surface: Color(0xFFFFFFFF),
    ink: Color(0xFF1B2B28),
    warning: Color(0xFF9A5B00),
    warningBar: Color(0xFFE2A03F),
    danger: Color(0xFFB3362B),
  );

  static const dark = AppColors(
    primary: Color(0xFF5CC7B2),
    onPrimary: Color(0xFF06231D),
    soft: Color(0xFF1F3A34),
    background: Color(0xFF0F1917),
    surface: Color(0xFF18241F),
    ink: Color(0xFFE7EFEC),
    warning: Color(0xFFF2B65A),
    warningBar: Color(0xFFF2B65A),
    danger: Color(0xFFF28B7D),
  );

  /// Accent: buttons and icons. Also what a warranty in force is drawn with.
  final Color primary;

  /// Text and icons on top of [primary].
  final Color onPrimary;

  /// Tinted background for avatars and the empty part of a progress bar.
  final Color soft;

  final Color background;
  final Color surface;

  /// Main text color; use with alpha for secondary text.
  final Color ink;

  /// Text for a warranty about to end.
  final Color warning;

  /// The progress bar for a warranty about to end. Lighter than [warning], so
  /// it is not meant for text.
  final Color warningBar;

  /// A warranty that has ended.
  final Color danger;

  /// Soft top-to-bottom gradient for the full-screen pages.
  BoxDecoration get softGradient => BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [soft, background],
    ),
  );

  @override
  AppColors copyWith({
    Color? primary,
    Color? onPrimary,
    Color? soft,
    Color? background,
    Color? surface,
    Color? ink,
    Color? warning,
    Color? warningBar,
    Color? danger,
  }) => AppColors(
    primary: primary ?? this.primary,
    onPrimary: onPrimary ?? this.onPrimary,
    soft: soft ?? this.soft,
    background: background ?? this.background,
    surface: surface ?? this.surface,
    ink: ink ?? this.ink,
    warning: warning ?? this.warning,
    warningBar: warningBar ?? this.warningBar,
    danger: danger ?? this.danger,
  );

  @override
  AppColors lerp(AppColors? other, double t) {
    if (other == null) return this;
    return AppColors(
      primary: Color.lerp(primary, other.primary, t)!,
      onPrimary: Color.lerp(onPrimary, other.onPrimary, t)!,
      soft: Color.lerp(soft, other.soft, t)!,
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      ink: Color.lerp(ink, other.ink, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      warningBar: Color.lerp(warningBar, other.warningBar, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
    );
  }
}

extension AppColorsContext on BuildContext {
  /// The current [AppColors]; registers a dependency on the theme.
  AppColors get colors => Theme.of(this).extension<AppColors>()!;
}
