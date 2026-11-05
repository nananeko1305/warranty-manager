import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../l10n/error_text.dart';
import '../models/warranty.dart';
import '../models/warranty_list.dart';
import '../theme/app_colors.dart';
import 'warranty_card.dart';

/// The search field, the valid and expired lists, and the empty states.
class WarrantyListView extends StatefulWidget {
  const WarrantyListView({
    super.key,
    required this.warranties,
    required this.error,
    required this.now,
    required this.onOpen,
  });

  /// Null while the first answer is on its way: not here yet, as opposed to
  /// there being none.
  final List<Warranty>? warranties;
  final Object? error;
  final DateTime now;
  final ValueChanged<Warranty> onOpen;

  @override
  State<WarrantyListView> createState() => _WarrantyListViewState();
}

class _WarrantyListViewState extends State<WarrantyListView> {
  final _search = TextEditingController();
  bool _expired = false;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final all = widget.warranties;
    if (all == null) {
      // Regression in the app this came from: a failing listener left the list
      // null forever, so the screen spun instead of saying what was wrong.
      final error = widget.error;
      return error != null
          ? _Message(title: errorText(t, error))
          : const Center(child: CircularProgressIndicator());
    }
    if (all.isEmpty) {
      return _Message(
        icon: Icons.verified_user_rounded,
        title: t.emptyTitle,
        body: t.emptyBody,
      );
    }

    final lists = WarrantyLists.of(
      searchWarranties(all, _search.text),
      widget.now,
    );
    final shown = _expired ? lists.expired : lists.valid;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: TextField(
            controller: _search,
            onChanged: (_) => setState(() {}),
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: t.searchHint,
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: _search.text.isEmpty
                  ? null
                  : IconButton(
                      tooltip: t.cancel,
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => setState(_search.clear),
                    ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
          child: SizedBox(
            width: double.infinity,
            child: SegmentedButton<bool>(
              segments: [
                ButtonSegment(
                  value: false,
                  label: Text(t.validTab(lists.valid.length)),
                ),
                ButtonSegment(
                  value: true,
                  label: Text(t.expiredTab(lists.expired.length)),
                ),
              ],
              selected: {_expired},
              showSelectedIcon: false,
              onSelectionChanged: (s) => setState(() => _expired = s.first),
            ),
          ),
        ),
        Expanded(
          child: shown.isEmpty
              ? _Message(
                  title: _search.text.trim().isNotEmpty
                      ? t.noResults
                      : (_expired ? t.noExpired : t.noValid),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                  itemCount: shown.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, i) => WarrantyCard(
                    warranty: shown[i],
                    now: widget.now,
                    onTap: () => widget.onOpen(shown[i]),
                  ),
                ),
        ),
      ],
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.title, this.icon, this.body});

  final String title;
  final IconData? icon;
  final String? body;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              CircleAvatar(
                radius: 36,
                backgroundColor: colors.soft,
                foregroundColor: colors.primary,
                child: Icon(icon, size: 36),
              ),
              const SizedBox(height: 18),
            ],
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: body == null ? 15 : 18,
                fontWeight: body == null ? FontWeight.w500 : FontWeight.w800,
              ),
            ),
            if (body != null) ...[
              const SizedBox(height: 8),
              Text(
                body!,
                textAlign: TextAlign.center,
                style: TextStyle(color: colors.ink.withValues(alpha: 0.7)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
