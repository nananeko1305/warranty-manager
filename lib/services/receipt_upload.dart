import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import '../models/receipt_id.dart';

/// Uploads a receipt photo to Cloudinary with an unsigned preset.
///
/// The cloud and preset names come from `--dart-define` at build time,
/// because this repository is public and they are enough to upload into
/// the account. They still ship inside the APK — anyone holding it can
/// read them — so the preset is the place to cap file size and formats.
///
/// There is no offline queue: Cloudinary has no local cache the way
/// Firestore does, so the upload happens while the form is open and a
/// warranty can always be saved without a receipt and get one later.
class ReceiptUpload {
  ReceiptUpload._();

  static const _cloud = String.fromEnvironment('CLOUDINARY_CLOUD');
  static const _preset = String.fromEnvironment('CLOUDINARY_PRESET');

  /// False in a build that was made without the upload settings; the
  /// receipt controls then stay hidden instead of failing on use.
  static bool get isConfigured => _cloud.isNotEmpty && _preset.isNotEmpty;

  /// The same image, delivered small.
  ///
  /// A list tile is 40 points wide but the stored photo is 1600 pixels,
  /// and downloading all of it to shrink it on the phone is the fastest
  /// way to spend the free bandwidth. Cloudinary resizes on its side
  /// when the recipe is in the URL. Anything that is not one of its URLs
  /// is left alone.
  static String thumbnail(String url, {int size = 160}) {
    const marker = '/image/upload/';
    final at = url.indexOf(marker);
    if (!url.startsWith('https://res.cloudinary.com/') || at < 0) return url;
    final cut = at + marker.length;
    return '${url.substring(0, cut)}w_$size,h_$size,c_fill,q_auto,f_auto/'
        '${url.substring(cut)}';
  }

  /// The secure URL of the uploaded image.
  static Future<String> send(XFile file) async {
    final request =
        http.MultipartRequest(
            'POST',
            Uri.https('api.cloudinary.com', '/v1_1/$_cloud/image/upload'),
          )
          ..fields['upload_preset'] = _preset
          ..files.add(await http.MultipartFile.fromPath('file', file.path));

    final response = await http.Response.fromStream(await request.send());
    if (response.statusCode != 200) {
      throw http.ClientException(
        'Upload failed (${response.statusCode})',
        request.url,
      );
    }
    return uploadedUrl(response.body);
  }

  /// The link in Cloudinary's answer to an upload.
  ///
  /// Refuses a link whose id is not the id Cloudinary reports: the push worker
  /// deletes photos no warranty refers to by that id, so a saved warranty with a
  /// wrong one would lose its photo.
  static String uploadedUrl(String responseBody) {
    final body = jsonDecode(responseBody) as Map<String, dynamic>;
    final url = body['secure_url'] as String?;
    if (url == null) {
      throw const FormatException('Upload returned no URL');
    }
    if (receiptIdOf(url) != body['public_id']) {
      throw const FormatException('Upload returned an unexpected URL');
    }
    return url;
  }
}
