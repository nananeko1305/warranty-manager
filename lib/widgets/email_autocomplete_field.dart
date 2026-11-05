import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';

/// Email field that suggests previously used emails while typing (or all
/// of them when empty and focused). Each suggestion can be removed.
class EmailAutocompleteField extends StatelessWidget {
  const EmailAutocompleteField({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.suggestions,
    required this.onSelected,
    required this.onRemove,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final List<String> suggestions;
  final ValueChanged<String> onSelected;
  final ValueChanged<String> onRemove;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return RawAutocomplete<String>(
      textEditingController: controller,
      focusNode: focusNode,
      optionsBuilder: (value) {
        final q = value.text.trim().toLowerCase();
        return suggestions.where((e) => e.contains(q) && e != q);
      },
      onSelected: onSelected,
      fieldViewBuilder: (context, controller, focusNode, onSubmit) {
        return TextFormField(
          controller: controller,
          focusNode: focusNode,
          keyboardType: TextInputType.emailAddress,
          autofillHints: const [AutofillHints.email],
          onFieldSubmitted: (_) => onSubmit(),
          decoration: InputDecoration(
            labelText: t.email,
            prefixIcon: const Icon(Icons.alternate_email_rounded),
          ),
          validator: (v) =>
              (v == null || !v.contains('@')) ? t.invalidEmail : null,
        );
      },
      optionsViewBuilder: (context, onSelect, options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 6,
            borderRadius: BorderRadius.circular(16),
            clipBehavior: Clip.antiAlias,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: 260,
                // Same width as the field (screen minus the page padding).
                maxWidth: MediaQuery.sizeOf(context).width - 56,
              ),
              child: ListView(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                children: [
                  for (final email in options)
                    ListTile(
                      leading: const Icon(Icons.history_rounded),
                      title: Text(email, overflow: TextOverflow.ellipsis),
                      onTap: () => onSelect(email),
                      trailing: IconButton(
                        tooltip: t.delete,
                        icon: const Icon(Icons.close_rounded, size: 20),
                        onPressed: () => onRemove(email),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
