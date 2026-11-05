import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../l10n/app_localizations.dart';
import '../services/update_checker.dart';
import 'update_dialog.dart';

/// Settings rows: installed version, and a manual "check for updates".
class UpdateTiles extends StatefulWidget {
  const UpdateTiles({super.key});

  @override
  State<UpdateTiles> createState() => _UpdateTilesState();
}

class _UpdateTilesState extends State<UpdateTiles> {
  late final Future<PackageInfo> _app = UpdateChecker.instance.currentApp();
  bool _checking = false;

  Future<void> _check() async {
    final t = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _checking = true);
    final result = await UpdateChecker.instance.check();
    if (!mounted) return;
    setState(() => _checking = false);
    switch (result) {
      case UpdateAvailable():
        await showUpdateDialog(context, result);
      case UpToDate():
        messenger.showSnackBar(SnackBar(content: Text(t.upToDate)));
      case UpdateCheckFailed():
        messenger.showSnackBar(SnackBar(content: Text(t.updateCheckFailed)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return FutureBuilder<PackageInfo>(
      future: _app,
      builder: (context, snap) {
        final app = snap.data;
        return ListTile(
          leading: const Icon(Icons.system_update_rounded),
          title: Text(t.checkUpdates),
          subtitle: app == null ? null : Text(t.appVersion(app.version)),
          trailing: _checking
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : null,
          onTap: _checking ? null : _check,
        );
      },
    );
  }
}
