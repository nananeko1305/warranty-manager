import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../l10n/app_localizations.dart';
import '../l10n/error_text.dart';
import '../screens/receipt_screen.dart';
import '../services/receipt_upload.dart';
import '../theme/app_colors.dart';

/// Photograph of the receipt, at the top of the form because it is the point
/// of the app: take one, pick one, or look at the one that is already there.
///
/// The upload happens here and now, so a warranty is only ever saved with a
/// link that works. Nothing is lost if it fails: the warranty saves without a
/// receipt and one can be added later.
class ReceiptField extends StatefulWidget {
  const ReceiptField({
    super.key,
    required this.url,
    required this.onChanged,
    this.onBusy,
    this.configured,
  });

  final String url;
  final ValueChanged<String> onChanged;

  /// Told when an upload starts and ends, so the form can hold off saving:
  /// saving meanwhile would lose the photo.
  final ValueChanged<bool>? onBusy;

  /// Overrides whether the build has upload settings; only tests pass it.
  final bool? configured;

  @override
  State<ReceiptField> createState() => _ReceiptFieldState();
}

class _ReceiptFieldState extends State<ReceiptField> {
  bool _busy = false;

  void _setBusy(bool busy) {
    setState(() => _busy = busy);
    widget.onBusy?.call(busy);
  }

  Future<void> _pick(ImageSource source) async {
    final t = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final picked = await ImagePicker().pickImage(
      source: source,
      // Plenty for a receipt, and it keeps the upload quick.
      maxWidth: 1600,
      imageQuality: 80,
    );
    if (picked == null || !mounted) return;
    _setBusy(true);
    try {
      final url = await ReceiptUpload.send(picked);
      if (mounted) widget.onChanged(url);
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(errorText(t, e))));
    } finally {
      if (mounted) _setBusy(false);
    }
  }

  Future<void> _choose() async {
    final t = AppLocalizations.of(context);
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_rounded),
              title: Text(t.receiptCamera),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded),
              title: Text(t.receiptGallery),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source != null) await _pick(source);
  }

  void _open() {
    final t = AppLocalizations.of(context);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ReceiptScreen(url: widget.url, title: t.receipt),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // A build made without the upload settings hides the whole thing
    // rather than offering a button that cannot work.
    if (!(widget.configured ?? ReceiptUpload.isConfigured)) {
      return const SizedBox.shrink();
    }
    if (_busy) return _Busy();
    return widget.url.isEmpty
        ? _Empty(onTap: _choose)
        : _Photo(
            url: widget.url,
            onOpen: _open,
            onReplace: _choose,
            onRemove: () => widget.onChanged(''),
          );
  }
}

/// The fixed height keeps the form from jumping as the field changes state.
const double _height = 168;

class _Busy extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Card(
      child: SizedBox(
        height: _height,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 14),
            Text(t.receiptUploading),
          ],
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final colors = context.colors;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: _height,
          width: double.infinity,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: colors.soft,
                  foregroundColor: colors.primary,
                  child: const Icon(Icons.photo_camera_rounded, size: 26),
                ),
                const SizedBox(height: 12),
                Text(
                  t.addReceipt,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  t.receiptHint,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: colors.ink.withValues(alpha: 0.65),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Photo extends StatelessWidget {
  const _Photo({
    required this.url,
    required this.onOpen,
    required this.onReplace,
    required this.onRemove,
  });

  final String url;
  final VoidCallback onOpen;
  final VoidCallback onReplace;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final colors = context.colors;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        height: _height,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            InkWell(
              onTap: onOpen,
              child: Ink.image(
                image: NetworkImage(ReceiptUpload.thumbnail(url, size: 640)),
                fit: BoxFit.cover,
                onImageError: (_, _) {},
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: Row(
                children: [
                  IconButton.filledTonal(
                    tooltip: t.edit,
                    icon: const Icon(Icons.photo_camera_rounded),
                    color: colors.ink,
                    onPressed: onReplace,
                  ),
                  const SizedBox(width: 6),
                  IconButton.filledTonal(
                    tooltip: t.delete,
                    icon: const Icon(Icons.delete_outline_rounded),
                    color: colors.ink,
                    onPressed: onRemove,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
