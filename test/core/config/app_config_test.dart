import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taskflow_mobile/core/config/app_config.dart';

void main() {
  // `flutter test` selalu berjalan di mode non-release (kReleaseMode
  // adalah compile-time const), jadi baris ini menjaga asumsi yang
  // dipakai test-test di bawah tetap valid.
  test('lingkungan test bukan release mode', () {
    expect(kReleaseMode, isFalse);
  });

  test('baseUrl fallback ke localhost/10.0.2.2 saat API_BASE_URL kosong '
      '(mode non-release)', () {
    // Tanpa --dart-define, _envBaseUrl kosong dan fallback dev yang dipakai.
    // StateError hanya dilempar di release mode.
    expect(
      () => AppConfig.baseUrl,
      returnsNormally,
    );
    expect(AppConfig.baseUrl, contains('/api'));
  });

  test('connect/receive timeout masuk akal untuk mobile network', () {
    expect(AppConfig.connectTimeout.inSeconds, greaterThan(0));
    expect(AppConfig.receiveTimeout.inSeconds, greaterThan(0));
  });
}
