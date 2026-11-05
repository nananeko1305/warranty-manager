import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/warranty.dart';
import '../money/money.dart';
import '../services/receipt_upload.dart';
import '../theme/app_colors.dart';
import 'warranty_bar.dart';

/// One warranty in the list: what it is, where and when it was bought, what it
/// cost, and how much of the warranty is left.
class WarrantyCard extends StatelessWidget {
  const WarrantyCard({
    super.key,
    required this.warranty,
    required this.now,
    required this.onTap,
  });

  final Warranty warranty;
  final DateTime now;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toLanguageTag();
    final colors = context.colors;
    final meta = [
      if (warranty.store.isNotEmpty) warranty.store,
      DateFormat.yMMMd(locale).format(warranty.purchaseDate),
      if (warranty.amountMinor != null)
        formatMoney(
          warranty.amountMinor!,
          warranty.currency ?? Currency.rsd,
          locale,
        ),
    ].join(' · ');

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _ReceiptThumbnail(url: warranty.receiptUrl),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          warranty.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          meta,
                          style: TextStyle(
                            fontSize: 13,
                            color: colors.ink.withValues(alpha: 0.65),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Reminders are on by default, so only their absence is news.
                  if (!warranty.notify)
                    Padding(
                      padding: const EdgeInsets.only(left: 6),
                      child: Icon(
                        Icons.notifications_off_rounded,
                        size: 18,
                        color: colors.ink.withValues(alpha: 0.45),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 14),
              WarrantyBar(warranty: warranty, now: now),
            ],
          ),
        ),
      ),
    );
  }
}

/// The photo of the receipt when there is one, otherwise a plain icon.
class _ReceiptThumbnail extends StatelessWidget {
  const _ReceiptThumbnail({required this.url});

  final String url;

  static const _size = 48.0;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final icon = Container(
      width: _size,
      height: _size,
      color: colors.soft,
      child: Icon(Icons.verified_user_rounded, size: 22, color: colors.primary),
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: url.isEmpty
          ? icon
          : Image.network(
              ReceiptUpload.thumbnail(url),
              width: _size,
              height: _size,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => icon,
            ),
    );
  }
}
