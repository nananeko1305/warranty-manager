import 'package:warranty_manager/services/receipt_upload.dart';
import 'package:flutter_test/flutter_test.dart';

const _full =
    'https://res.cloudinary.com/nnarit58/image/upload/v1790331444/ztfubikg4gep48y5oaue.jpg';

void main() {
  test('a thumbnail asks the host to resize, keeping the rest of the URL', () {
    final thumb = ReceiptUpload.thumbnail(_full);
    expect(
      thumb,
      'https://res.cloudinary.com/nnarit58/image/upload/'
      'w_160,h_160,c_fill,q_auto,f_auto/v1790331444/ztfubikg4gep48y5oaue.jpg',
    );
  });

  test('the size is the one asked for', () {
    expect(ReceiptUpload.thumbnail(_full, size: 320), contains('w_320,h_320'));
  });

  // Anything else is left alone rather than mangled into a broken link.
  test('a foreign or empty URL passes through untouched', () {
    for (final url in ['', 'https://example.com/racun.jpg', 'not a url']) {
      expect(ReceiptUpload.thumbnail(url), url, reason: url);
    }
  });
}
