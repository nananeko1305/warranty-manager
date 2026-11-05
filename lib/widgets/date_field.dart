import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Read-only field showing a date; tapping opens the date picker.
class DateField extends StatelessWidget {
  const DateField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.enabled = true,
    this.lastDate,
  });

  final String label;
  final DateTime value;
  final ValueChanged<DateTime> onChanged;
  final bool enabled;

  /// The latest date the picker offers; a year from today when null.
  final DateTime? lastDate;

  Future<void> _pick(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: value,
      firstDate: DateTime(1990),
      lastDate: lastDate ?? DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) onChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toLanguageTag();
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: enabled ? () => _pick(context) : null,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          enabled: enabled,
          prefixIcon: const Icon(Icons.event_rounded),
        ),
        child: Text(DateFormat.yMMMMd(locale).format(value)),
      ),
    );
  }
}
