import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';

/// Semua request membaca base URL gateway dari sini. Bisa dioverride saat
/// build/run:
///
/// ```sh
/// flutter run --dart-define=API_BASE_URL=http://192.168.1.10:3000/api
/// ```
abstract final class AppConfig {
  static const String _envBaseUrl = String.fromEnvironment('API_BASE_URL');

  /// - Emulator Android tidak bisa mengakses `localhost` milik host, jadi
  ///   dipetakan ke `10.0.2.2`.
  /// - Device fisik: `--dart-define=API_BASE_URL=http://<ip-lan>:3000/api`.
  /// - Build release wajib mengisi nilai ini (lihat `scripts/build_release.ps1`).
  ///   Kalau kosong, app langsung gagal saat start daripada diam-diam
  ///   menembak `localhost` di device user.
  static String get baseUrl {
    if (_envBaseUrl.isNotEmpty) return _envBaseUrl;
    if (kReleaseMode) {
      throw StateError(
        'API_BASE_URL belum di-set untuk build release. Jalankan:\n'
        '  flutter build apk --release '
        '--dart-define=API_BASE_URL=https://api-produksi-kamu.com/api\n'
        'atau gunakan scripts/build_release.ps1.',
      );
    }
    if (!kIsWeb && Platform.isAndroid) return 'http://10.0.2.2:3000/api';
    return 'http://localhost:3000/api';
  }

  static const Duration connectTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 15);
}
