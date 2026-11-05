import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:warranty_manager/services/receipt_cleanup.dart';

void main() {
  test('names the warranty, and carries the sign-in', () async {
    late http.Request sent;
    final cleanup = ReceiptCleanup(
      client: MockClient((request) async {
        sent = request;
        return http.Response('', 204);
      }),
      idToken: () async => 'token',
    );
    expect(await cleanup.release('w1'), isTrue);
    expect(sent.url, kReleaseReceiptUrl);
    expect(sent.method, 'POST');
    expect(sent.headers['Authorization'], 'Bearer token');
    expect(jsonDecode(sent.body), {'warrantyId': 'w1'});
  });

  test('says so when the worker refuses', () async {
    final cleanup = ReceiptCleanup(
      client: MockClient((_) async => http.Response('', 403)),
      idToken: () async => 'token',
    );
    expect(await cleanup.release('w1'), isFalse);
  });

  // Offline must not stop anyone from deleting a warranty.
  test('a failure on the way does not throw', () async {
    final cleanup = ReceiptCleanup(
      client: MockClient((_) async => throw http.ClientException('offline')),
      idToken: () async => 'token',
    );
    expect(await cleanup.release('w1'), isFalse);
  });

  test('with nobody signed in it asks for nothing', () async {
    var called = false;
    final cleanup = ReceiptCleanup(
      client: MockClient((_) async {
        called = true;
        return http.Response('', 204);
      }),
      idToken: () async => null,
    );
    expect(await cleanup.release('w1'), isFalse);
    expect(called, isFalse);
  });

  test('a failing token does not throw either', () async {
    final cleanup = ReceiptCleanup(
      client: MockClient((_) async => http.Response('', 204)),
      idToken: () async => throw StateError('no token'),
    );
    expect(await cleanup.release('w1'), isFalse);
  });
}
