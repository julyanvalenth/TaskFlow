import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/app_config.dart';
import '../storage/token_storage.dart';
import 'auth_events.dart';
import 'auth_interceptor.dart';

BaseOptions _baseOptions() => BaseOptions(
      baseUrl: AppConfig.baseUrl,
      connectTimeout: AppConfig.connectTimeout,
      receiveTimeout: AppConfig.receiveTimeout,
      headers: {'Accept': 'application/json'},
    );

/// Dio tunggal untuk seluruh aplikasi, dengan interceptor JWT
/// (attach token + auto-refresh saat 401).
final dioProvider = Provider<Dio>((ref) {
  final storage = ref.watch(tokenStorageProvider);
  final dio = Dio(_baseOptions());
  final refreshDio = Dio(_baseOptions());

  dio.interceptors.add(
    AuthInterceptor(
      refreshDio: refreshDio,
      storage: storage,
      onSessionExpired: () =>
          ref.read(authEventsProvider).emitSessionExpired(),
    ),
  );

  ref.onDispose(() {
    dio.close();
    refreshDio.close();
  });
  return dio;
});
