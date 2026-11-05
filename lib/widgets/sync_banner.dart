import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../services/sync_status.dart';
import '../theme/app_colors.dart';

/// Thin top banner while a save is on its way, with a check when it is done.
class SyncBanner extends StatelessWidget {
  const SyncBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return ValueListenableBuilder<SyncPhase>(
      valueListenable: syncController,
      builder: (context, phase, _) {
        final syncing = phase == SyncPhase.syncing;
        final visible = phase != SyncPhase.idle;
        final colors = context.colors;
        return AnimatedSize(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          child: !visible
              ? const SizedBox(width: double.infinity, height: 0)
              : Container(
                  width: double.infinity,
                  color: syncing ? colors.ink : colors.primary,
                  padding: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 16,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (syncing)
                        SizedBox(
                          width: 15,
                          height: 15,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: syncing
                                ? colors.background
                                : colors.onPrimary,
                          ),
                        )
                      else
                        Icon(
                          Icons.check_circle_rounded,
                          size: 18,
                          color: colors.onPrimary,
                        ),
                      const SizedBox(width: 10),
                      Text(
                        syncing ? t.syncing : t.synced,
                        style: TextStyle(
                          color: syncing ? colors.background : colors.onPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
        );
      },
    );
  }
}
