import 'dart:convert';

import 'package:warranty_manager/services/update_checker.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('compareVersions', () {
    test('orders by major, then minor, then patch', () {
      expect(compareVersions('1.1.0', '1.0.9'), greaterThan(0));
      expect(compareVersions('2.0.0', '1.9.9'), greaterThan(0));
      expect(compareVersions('1.0.1', '1.0.2'), lessThan(0));
      expect(compareVersions('1.2.3', '1.2.3'), 0);
    });

    // Regression guard: comparing "1.10.0" as text puts it before
    // "1.9.0", which would hide an update from everyone.
    test('ten is newer than nine', () {
      expect(compareVersions('1.10.0', '1.9.0'), greaterThan(0));
      expect(compareVersions('1.0.10', '1.0.9'), greaterThan(0));
    });

    test('missing and unreadable parts count as zero', () {
      expect(compareVersions('1.1', '1.1.0'), 0);
      expect(compareVersions('1', '1.0.0'), 0);
      expect(compareVersions('', '0.0.1'), lessThan(0));
      expect(compareVersions('1.0.0-beta', '1.0.0'), 0);
    });
  });

  test('parses version.json written by the release workflow', () {
    // Same shape the workflow's heredoc produces.
    const raw =
        '{"version":"1.0.0","build":7,"url":"https://github.com/o/r/releases/latest/download/car-expenses.apk"}';
    final info = ReleaseInfo.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    expect(info.version, '1.0.0');
    expect(info.build, 7);
    expect(info.downloadUrl, endsWith('car-expenses.apk'));
  });
}
