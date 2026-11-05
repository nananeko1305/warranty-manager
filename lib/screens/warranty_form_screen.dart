import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/warranty.dart';
import '../models/warranty_draft.dart';
import '../services/background_save.dart';
import '../services/warranty_repository.dart';
import '../widgets/confirm_delete.dart';
import '../widgets/date_field.dart';
import '../widgets/money_fields.dart';
import '../widgets/receipt_field.dart';
import '../widgets/warranty_duration_field.dart';

/// Add a warranty, or look at and change an existing one. Only the name has to
/// be typed: the date is today and the duration the legal two years until
/// someone says otherwise.
class WarrantyFormScreen extends StatefulWidget {
  const WarrantyFormScreen({super.key, required this.ownerId, this.warranty});

  final String ownerId;
  final Warranty? warranty;

  @override
  State<WarrantyFormScreen> createState() => _WarrantyFormScreenState();
}

class _WarrantyFormScreenState extends State<WarrantyFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _draft = WarrantyDraft(warranty: widget.warranty);
  bool _uploading = false;

  /// The optional fields stay out of the way when there is nothing in them, so
  /// that everything else and the save button fit on one screen.
  late bool _details =
      _draft.store.text.isNotEmpty ||
      _draft.note.text.isNotEmpty ||
      _draft.amount.text.isNotEmpty;

  /// Lengths the rules enforce; better stopped here than refused on save.
  static const _maxName = 120;
  static const _maxNote = 1000;

  @override
  void dispose() {
    _draft.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) {
      // The fields stay mounted while hidden, so one of them may be the problem.
      setState(() => _details = true);
      return;
    }
    final warranty = _draft.build(ownerId: widget.ownerId);
    saveInBackground(
      context,
      () => WarrantyRepository.instance.save(warranty, before: widget.warranty),
    );
    Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    final t = AppLocalizations.of(context);
    final warranty = widget.warranty!;
    final ok = await confirmDelete(
      context,
      t.deleteWarrantyQ(warranty.name),
      body: t.deleteWarrantyBody,
    );
    if (!ok || !mounted) return;
    saveInBackground(
      context,
      () => WarrantyRepository.instance.delete(warranty),
    );
    Navigator.of(context).pop();
  }

  /// Never later than today, unless the warranty already says so.
  DateTime get _lastPurchaseDate {
    final today = DateUtils.dateOnly(DateTime.now());
    return _draft.purchaseDate.isAfter(today) ? _draft.purchaseDate : today;
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final existing = widget.warranty != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(existing ? t.editWarranty : t.newWarranty),
        actions: [
          if (existing)
            IconButton(
              tooltip: t.delete,
              icon: const Icon(Icons.delete_outline_rounded),
              onPressed: _delete,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            ReceiptField(
              url: _draft.receiptUrl,
              onChanged: (url) => setState(() => _draft.receiptUrl = url),
              onBusy: (busy) => setState(() => _uploading = busy),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _draft.name,
              maxLength: _maxName,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: t.productName,
                hintText: t.productNameHint,
                prefixIcon: const Icon(Icons.shopping_bag_rounded),
                counterText: '',
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? t.required : null,
            ),
            const SizedBox(height: 14),
            DateField(
              label: t.purchaseDate,
              value: _draft.purchaseDate,
              lastDate: _lastPurchaseDate,
              onChanged: (d) => setState(() => _draft.purchaseDate = d),
            ),
            const SizedBox(height: 14),
            WarrantyDurationField(
              amount: _draft.duration,
              unit: _draft.unit,
              purchaseDate: _draft.purchaseDate,
              onUnit: (u) => setState(() => _draft.unit = u),
            ),
            const SizedBox(height: 6),
            _DetailsToggle(
              open: _details,
              onTap: () => setState(() => _details = !_details),
            ),
            Visibility(
              visible: _details,
              maintainState: true,
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _draft.store,
                    maxLength: _maxName,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      labelText: t.storeOptional,
                      prefixIcon: const Icon(Icons.storefront_rounded),
                      counterText: '',
                    ),
                  ),
                  const SizedBox(height: 14),
                  MoneyFields(
                    amount: _draft.amount,
                    currency: _draft.currency,
                    onCurrency: (c) => setState(() => _draft.currency = c),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _draft.note,
                    maxLength: _maxNote,
                    minLines: 1,
                    maxLines: 4,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      labelText: t.noteOptional,
                      hintText: t.noteHint,
                      prefixIcon: const Icon(Icons.notes_rounded),
                      counterText: '',
                    ),
                  ),
                  const SizedBox(height: 6),
                ],
              ),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              secondary: const Icon(Icons.notifications_active_rounded),
              title: Text(t.notifyOnExpiry),
              subtitle: Text(t.notifyOnExpiryHint),
              value: _draft.notify,
              onChanged: (v) => setState(() => _draft.notify = v),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _uploading ? null : _save,
              child: Text(_uploading ? t.receiptUploading : t.save),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailsToggle extends StatelessWidget {
  const _DetailsToggle({required this.open, required this.onTap});

  final bool open;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return TextButton.icon(
      onPressed: onTap,
      style: TextButton.styleFrom(alignment: Alignment.centerLeft),
      icon: Icon(open ? Icons.expand_less_rounded : Icons.expand_more_rounded),
      label: Text(t.moreDetails),
    );
  }
}
