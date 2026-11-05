import 'package:flutter_test/flutter_test.dart';
import 'package:warranty_manager/models/receipt_id.dart';
import 'package:warranty_manager/models/warranty.dart';
import 'package:warranty_manager/models/warranty_dates.dart';
import 'package:warranty_manager/services/receipt_upload.dart';

const _url =
    'https://res.cloudinary.com/cpg7114d/image/upload/v1793881507/vceyvhp3bp6hiylf93zc.png';

Warranty _w({String receiptUrl = _url, String note = ''}) => Warranty(
  id: 'w1',
  ownerId: 'u1',
  name: 'Frižider',
  note: note,
  purchaseDate: DateTime(2026, 1, 10),
  warrantyAmount: 2,
  warrantyUnit: WarrantyUnit.years,
  receiptUrl: receiptUrl,
);

void main() {
  group('receiptIdOf', () {
    test('reads the id out of a real link', () {
      expect(receiptIdOf(_url), 'vceyvhp3bp6hiylf93zc');
    });

    test('keeps a folder that is part of the id', () {
      expect(
        receiptIdOf(
          'https://res.cloudinary.com/x/image/upload/v1/receipts/abc.jpg',
        ),
        'receipts/abc',
      );
    });

    test('copes with a link without a version', () {
      expect(
        receiptIdOf('https://res.cloudinary.com/x/image/upload/abc.jpg'),
        'abc',
      );
    });

    test('is empty without a photo, or with something else', () {
      expect(receiptIdOf(''), '');
      expect(receiptIdOf('https://example.com/a.jpg'), '');
    });
  });

  group('Warranty', () {
    test('stores the id along with the link', () {
      expect(_w().toMap()['receiptId'], 'vceyvhp3bp6hiylf93zc');
      expect(_w(receiptUrl: '').toMap()['receiptId'], '');
    });

    // A queued edit from another phone must not restore a replaced photo: the new
    // one would lose its only reference, and the old one may be gone already.
    test('an edit leaves an unchanged photo out', () {
      final map = _w(note: 'new').toEditMap(_w());
      expect(map.containsKey('receiptUrl'), isFalse);
      expect(map.containsKey('receiptId'), isFalse);
      expect(map['note'], 'new');
    });

    test('an edit writes a photo that changed', () {
      final map = _w(
        receiptUrl: 'https://res.cloudinary.com/x/image/upload/v2/next.jpg',
      ).toEditMap(_w());
      expect(map['receiptId'], 'next');
    });

    test('an edit writes a removed photo', () {
      final map = _w(receiptUrl: '').toEditMap(_w());
      expect(map['receiptUrl'], '');
      expect(map['receiptId'], '');
    });
  });

  group('uploadedUrl', () {
    test('takes the link when the id agrees', () {
      expect(
        ReceiptUpload.uploadedUrl(
          '{"secure_url":"$_url","public_id":"vceyvhp3bp6hiylf93zc"}',
        ),
        _url,
      );
    });

    // Saved with a wrong id, the warranty's photo would look unused, and go.
    test('refuses a link whose id is not what Cloudinary reports', () {
      expect(
        () => ReceiptUpload.uploadedUrl(
          '{"secure_url":"$_url","public_id":"something-else"}',
        ),
        throwsFormatException,
      );
    });

    test('refuses an answer without a link', () {
      expect(
        () => ReceiptUpload.uploadedUrl('{"public_id":"x"}'),
        throwsFormatException,
      );
    });
  });
}
