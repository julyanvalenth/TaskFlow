import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Bus event auth ringan untuk memutus dependensi siklik antara
/// interceptor Dio (core) dan AuthController (feature auth).
///
/// Interceptor memancarkan [emitSessionExpired] saat refresh token gagal;
/// AuthController mendengarkan dan memindahkan state ke unauthenticated.
class AuthEvents {
  final _sessionExpired = StreamController<void>.broadcast();

  Stream<void> get sessionExpired => _sessionExpired.stream;

  void emitSessionExpired() {
    if (!_sessionExpired.isClosed) _sessionExpired.add(null);
  }

  void dispose() => _sessionExpired.close();
}

final authEventsProvider = Provider<AuthEvents>((ref) {
  final events = AuthEvents();
  ref.onDispose(events.dispose);
  return events;
});
