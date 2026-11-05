import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../l10n/app_localizations.dart';
import '../models/warranty.dart';
import '../models/warranty_dates.dart';
import '../theme/app_colors.dart';

/// How far a warranty has run: empty on the day of purchase, full once it is
/// over.
///
/// [now] is passed in rather than read from the clock, so the bar can be
/// tested and so a whole list shares one instant.
class WarrantyBar extends StatelessWidget {
  const WarrantyBar({super.key, required this.warranty, required this.now});

  final Warranty warranty;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final colors = context.colors;
    final status = warranty.status(now);
    final days = warranty.daysLeft(now);
    final end = DateFormat.yMMMd(locale).format(warranty.warrantyEnd);
    // A full bar reads the same whether the warranty ended today or years
    // ago, so the label carries the meaning.
    final label = switch (status) {
      WarrantyStatus.expired => t.warrantyExpiredOn(end),
      WarrantyStatus.expiringSoon when days == 0 => t.warrantyEndsToday,
      WarrantyStatus.expiringSoon => t.warrantyDaysLeft(days),
      WarrantyStatus.active => t.warrantyUntil(end),
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: warranty.progress(now),
            minHeight: 6,
            backgroundColor: colors.soft,
            color: switch (status) {
              WarrantyStatus.active => colors.primary,
              WarrantyStatus.expiringSoon => colors.warningBar,
              WarrantyStatus.expired => colors.danger,
            },
            semanticsLabel: t.warranty,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: switch (status) {
              WarrantyStatus.active => colors.ink.withValues(alpha: 0.65),
              WarrantyStatus.expiringSoon => colors.warning,
              WarrantyStatus.expired => colors.danger,
            },
          ),
        ),
      ],
    );
  }
}
