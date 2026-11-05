import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../l10n/app_localizations.dart';
import '../l10n/error_text.dart';

/// The receipt, full screen and zoomable, with the share sheet — which
/// is also how the photo gets saved to the phone or sent to the shop.
class ReceiptScreen extends StatefulWidget {
  const ReceiptScreen({super.key, required this.url, required this.title});

  final String url;
  final String title;

  @override
  State<ReceiptScreen> createState() => _ReceiptScreenState();
}

class _ReceiptScreenState extends State<ReceiptScreen> {
  bool _sharing = false;

  /// Shares the picture itself rather than a link, so the phone can put
  /// it in the gallery or hand it to another app.
  Future<void> _share() async {
    final t = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _sharing = true);
    try {
      final response = await http.get(Uri.parse(widget.url));
      if (response.statusCode != 200) {
        throw http.ClientException('Download failed', Uri.parse(widget.url));
      }
      final dir = await getTemporaryDirectory();
      final name = widget.url.split('/').last;
      final file = File('${dir.path}/$name')
        ..writeAsBytesSync(response.bodyBytes);
      await SharePlus.instance.share(
        ShareParams(files: [XFile(file.path)], title: widget.title),
      );
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(errorText(t, e))));
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(t.receipt),
        actions: [
          IconButton(
            tooltip: t.share,
            icon: _sharing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.ios_share_rounded),
            onPressed: _sharing ? null : _share,
          ),
        ],
      ),
      // The zoom area is the whole screen. InteractiveViewer clips to its own
      // size, so wrapped around the picture it would keep a narrow receipt
      // narrow however far it is zoomed.
      body: InteractiveViewer(
        // A long receipt starts out small, so it needs more zoom than a normal
        // photo to fill the screen and still be readable.
        maxScale: 10,
        child: Center(
          child: Image.network(
            widget.url,
            fit: BoxFit.contain,
            loadingBuilder: (context, child, progress) => progress == null
                ? child
                : const Center(child: CircularProgressIndicator()),
            errorBuilder: (_, _, _) => Icon(
              Icons.broken_image_rounded,
              size: 48,
              color: Colors.white.withValues(alpha: 0.7),
            ),
          ),
        ),
      ),
    );
  }
}
