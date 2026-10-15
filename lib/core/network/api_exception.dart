import 'package:dio/dio.dart';

enum ApiErrorType {
  /// Tidak ada koneksi / timeout.
  network,

  /// 5xx dari server.
  server,

  /// 400/422 dengan pesan validasi (ValidationPipe NestJS).
  validation,

  /// 401.
  unauthorized,

  /// 404.
  notFound,

  /// 409 (mis. email duplikat).
  conflict,

  unknown,
}

/// Error yang dilempar layer data, hasil parse error envelope backend:
/// `{statusCode, message (string atau array pesan validasi), error}`.
class ApiException implements Exception {
  ApiException({
    required this.message,
    this.statusCode,
    this.type = ApiErrorType.unknown,
    this.details = const [],
  });

  factory ApiException.fromDioException(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionError:
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return ApiException(
          message:
              'Tidak dapat terhubung ke server. Periksa koneksi internet Anda.',
          type: ApiErrorType.network,
        );
      case DioExceptionType.badResponse:
        return ApiException._fromResponse(e.response);
      case DioExceptionType.cancel:
        return ApiException(
          message: 'Permintaan dibatalkan.',
          type: ApiErrorType.unknown,
        );
      case DioExceptionType.badCertificate:
      case DioExceptionType.unknown:
      default:
        return ApiException(
          message: 'Terjadi kesalahan tak terduga. Coba lagi.',
          type: ApiErrorType.unknown,
        );
    }
  }

  factory ApiException._fromResponse(Response<dynamic>? response) {
    final statusCode = response?.statusCode;
    final data = response?.data;

    String message = 'Terjadi kesalahan pada server.';
    List<String> details = const [];

    if (data is Map<String, dynamic>) {
      final rawMessage = data['message'];
      if (rawMessage is String && rawMessage.isNotEmpty) {
        message = rawMessage;
      } else if (rawMessage is List) {
        details =
            rawMessage.map((m) => m.toString()).toList(growable: false);
        message = details.isNotEmpty
            ? 'Periksa kembali isian Anda.'
            : message;
      }
    }

    final type = switch (statusCode) {
      401 => ApiErrorType.unauthorized,
      404 => ApiErrorType.notFound,
      409 => ApiErrorType.conflict,
      400 || 422 => ApiErrorType.validation,
      != null && >= 500 => ApiErrorType.server,
      _ => ApiErrorType.unknown,
    };

    if (type == ApiErrorType.server) {
      message = 'Server sedang bermasalah. Coba beberapa saat lagi.';
    }

    return ApiException(
      message: message,
      statusCode: statusCode,
      type: type,
      details: details,
    );
  }

  final String message;
  final int? statusCode;
  final ApiErrorType type;

  /// Daftar pesan validasi per field dari ValidationPipe,
  /// mis. `["title should not be empty"]`.
  final List<String> details;

  /// Cari pesan validasi yang menyebut [field] (konvensi pesan
  /// class-validator diawali nama properti, mis. `"title must be ..."`).
  String? errorFor(String field) {
    final lower = field.toLowerCase();
    for (final d in details) {
      if (d.toLowerCase().startsWith(lower) ||
          d.toLowerCase().contains(' $lower ')) {
        return d;
      }
    }
    return null;
  }

  /// Gabungan pesan yang layak ditampilkan langsung ke user.
  String get displayMessage =>
      details.isNotEmpty ? details.join('\n') : message;

  @override
  String toString() => 'ApiException($statusCode, $type): $displayMessage';
}

/// Menjalankan request API dan mengubah [DioException] jadi [ApiException].
Future<T> apiGuard<T>(Future<T> Function() run) async {
  try {
    return await run();
  } on DioException catch (e) {
    throw ApiException.fromDioException(e);
  }
}
