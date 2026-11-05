import 'dart:async';

import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/reminder_push.dart';
import '../models/warranty.dart';
import '../services/live_data.dart';
import '../services/push_service.dart';
import '../services/update_checker.dart';
import '../services/warranty_repository.dart';
import '../widgets/reminder_banner.dart';
import '../widgets/sync_banner.dart';
import '../widgets/update_dialog.dart';
import '../widgets/warranty_list_view.dart';
import 'settings_screen.dart';
import 'warranty_form_screen.dart';

/// The app once signed in: the account's warranties.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.uid});

  final String uid;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final LiveData _data = LiveData(
    () => WarrantyRepository.instance.watchMine(widget.uid),
  );
  late final List<StreamSubscription<Object?>> _subs;
  bool _updateDialogOpen = false;

  /// A tapped reminder that arrived before the warranties did.
  String? _pendingOpen;

  @override
  void initState() {
    super.initState();
    final push = PushService.instance;
    _subs = [
      // A release push (received in the foreground or tapped) re-runs the
      // same check, which then shows the download dialog.
      push.onRelease.listen((_) => _checkForUpdate()),
      push.onReminder.listen(_showReminder),
      push.onOpen.listen(_openById),
    ];
    _data.addListener(_openPending);
    _checkForUpdate();
    push.start();
    push.registerToken();
  }

  @override
  void dispose() {
    for (final sub in _subs) {
      sub.cancel();
    }
    _data.dispose();
    super.dispose();
  }

  /// On app start and on release pushes; silent when offline or already
  /// up to date, and never stacks a second dialog on an open one.
  Future<void> _checkForUpdate() async {
    if (_updateDialogOpen) return;
    final result = await UpdateChecker.instance.check();
    if (!mounted || result is! UpdateAvailable || _updateDialogOpen) return;
    _updateDialogOpen = true;
    await showUpdateDialog(context, result);
    _updateDialogOpen = false;
  }

  /// In the foreground Android shows nothing, so the app has to.
  void _showReminder(ReminderPush push) {
    if (!mounted) return;
    final t = AppLocalizations.of(context);
    final left = push.daysLeft == 0
        ? t.warrantyEndsToday
        : t.warrantyDaysLeft(push.daysLeft);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${push.name}: $left'),
        action: SnackBarAction(
          label: t.open,
          onPressed: () => _openById(push.warrantyId),
        ),
      ),
    );
  }

  /// A warranty this account does not have is ignored: it may have been
  /// deleted, or the push may be from before another account signed in here.
  void _openById(String id) {
    if (_data.warranties == null) {
      _pendingOpen = id;
      return;
    }
    final warranty = _data.byId(id);
    if (warranty != null) _openForm(warranty);
  }

  void _openPending() {
    final id = _pendingOpen;
    if (id == null || _data.warranties == null) return;
    _pendingOpen = null;
    _openById(id);
  }

  void _openForm([Warranty? warranty]) {
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            WarrantyFormScreen(ownerId: widget.uid, warranty: warranty),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(t.warranties),
        actions: [
          IconButton(
            tooltip: t.settings,
            icon: const Icon(Icons.settings_rounded),
            onPressed: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const SettingsScreen())),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openForm,
        icon: const Icon(Icons.add_rounded),
        label: Text(t.addWarranty),
      ),
      body: Column(
        children: [
          const SyncBanner(),
          const ReminderBanner(),
          Expanded(
            child: ListenableBuilder(
              listenable: _data,
              builder: (context, _) => WarrantyListView(
                warranties: _data.warranties,
                error: _data.error,
                now: DateUtils.dateOnly(DateTime.now()),
                onOpen: _openForm,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
