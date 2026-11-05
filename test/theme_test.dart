import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:warranty_manager/theme/app_colors.dart';
import 'package:warranty_manager/theme/app_theme.dart';

double _contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final hi = la > lb ? la : lb;
  final lo = la > lb ? lb : la;
  return (hi + 0.05) / (lo + 0.05);
}

void main() {
  const aa = 4.5;
  for (final (name, c) in [
    ('light', AppColors.light),
    ('dark', AppColors.dark),
  ]) {
    group('$name palette meets WCAG AA', () {
      test('on the primary color', () {
        expect(_contrast(c.onPrimary, c.primary), greaterThanOrEqualTo(aa));
      });

      test('for body text', () {
        expect(_contrast(c.ink, c.background), greaterThanOrEqualTo(aa));
        expect(_contrast(c.ink, c.surface), greaterThanOrEqualTo(aa));
      });

      test('for the status labels on a card', () {
        expect(_contrast(c.warning, c.surface), greaterThanOrEqualTo(aa));
        expect(_contrast(c.danger, c.surface), greaterThanOrEqualTo(aa));
      });

      test('for the primary color as text', () {
        expect(_contrast(c.primary, c.background), greaterThanOrEqualTo(aa));
        expect(_contrast(c.primary, c.surface), greaterThanOrEqualTo(aa));
      });
    });
  }

  test('the status-bar icons follow the mode', () {
    expect(
      AppTheme.overlayStyle(true).statusBarIconBrightness,
      Brightness.light,
    );
    expect(
      AppTheme.overlayStyle(false).statusBarIconBrightness,
      Brightness.dark,
    );
  });

  testWidgets('both themes carry the palette', (tester) async {
    expect(AppTheme.light.extension<AppColors>(), AppColors.light);
    expect(AppTheme.dark.extension<AppColors>(), AppColors.dark);
  });
}
