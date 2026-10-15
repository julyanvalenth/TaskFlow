import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taskflow_mobile/core/network/auth_interceptor.dart';
import 'package:taskflow_mobile/core/storage/token_storage.dart';

/// Adapter palsu: seluruh request HTTP dijawab oleh [handler].
class FakeAdapter implements HttpClientAdapter {
  FakeAdapter(this.handler);

  final Future<ResponseBody> Function(RequestOptions options) handler;
  final List<RequestOptions> requests = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) {
    requests.add(options);
    return handler(options);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody jsonResponse(Object data, int statusCode) =>
    ResponseBody.fromString(
      jsonEncode(data),
      statusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );

void main() {
  late InMemoryTokenStorage storage;
  late FakeAdapter adapter;
  late Dio dio;
  var sessionExpired = false;

  Dio buildDio() {
    final options = BaseOptions(baseUrl: 'http://gateway.test/api');
    final mainDio = Dio(options)..httpClientAdapter = adapter;
    final refreshDio = Dio(options)..httpClientAdapter = adapter;
    mainDio.interceptors.add(
      AuthInterceptor(
        refreshDio: refreshDio,
        storage: storage,
        onSessionExpired: () => sessionExpired = true,
      ),
    );
    return mainDio;
  }

  List<RequestOptions> requestsTo(String path) =>
      adapter.requests.where((r) => r.path.endsWith(path)).toList();

  setUp(() {
    storage = InMemoryTokenStorage()
      ..accessToken = 'access-old'
      ..refreshToken = 'refresh-old';
    sessionExpired = false;
  });

  test('menyisipkan Bearer access token pada request non-publik', () async {
    adapter = FakeAdapter((options) async => jsonResponse({'ok': true}, 200));
    dio = buildDio();

    await dio.get<Map<String, dynamic>>('/tasks');

    expect(
      adapter.requests.single.headers['Authorization'],
      'Bearer access-old',
    );
  });

  test('tidak menyisipkan token pada endpoint auth publik', () async {
    adapter = FakeAdapter((options) async => jsonResponse({'ok': true}, 200));
    dio = buildDio();

    await dio.post<Map<String, dynamic>>(
      '/auth/login',
      data: {'email': 'a@b.co', 'password': 'x'},
    );

    expect(
      adapter.requests.single.headers.containsKey('Authorization'),
      isFalse,
    );
  });

  test('401 → refresh → retry sekali dengan token baru', () async {
    adapter = FakeAdapter((options) async {
      if (options.path.endsWith('/auth/refresh')) {
        expect(options.data, {'refreshToken': 'refresh-old'});
        return jsonResponse({
          'accessToken': 'access-new',
          'refreshToken': 'refresh-new',
          'tokenType': 'Bearer',
        }, 200);
      }
      final auth = options.headers['Authorization'];
      if (auth == 'Bearer access-new') {
        return jsonResponse({'data': 'rahasia'}, 200);
      }
      return jsonResponse(
        {'statusCode': 401, 'message': 'Unauthorized'},
        401,
      );
    });
    dio = buildDio();

    final res = await dio.get<Map<String, dynamic>>('/tasks');

    expect(res.statusCode, 200);
    expect(res.data, {'data': 'rahasia'});
    // Token baru tersimpan.
    expect(storage.accessToken, 'access-new');
    expect(storage.refreshToken, 'refresh-new');
    // /tasks dipanggil 2x (gagal + retry), refresh tepat 1x.
    expect(requestsTo('/tasks'), hasLength(2));
    expect(requestsTo('/auth/refresh'), hasLength(1));
    expect(
      requestsTo('/tasks').last.headers['Authorization'],
      'Bearer access-new',
    );
    expect(sessionExpired, isFalse);
  });

  test('refresh gagal → token dihapus, session expired, error diteruskan',
      () async {
    adapter = FakeAdapter((options) async {
      if (options.path.endsWith('/auth/refresh')) {
        return jsonResponse(
          {'statusCode': 401, 'message': 'Invalid refresh token'},
          401,
        );
      }
      return jsonResponse(
        {'statusCode': 401, 'message': 'Unauthorized'},
        401,
      );
    });
    dio = buildDio();

    await expectLater(
      dio.get<Map<String, dynamic>>('/tasks'),
      throwsA(
        isA<DioException>().having(
          (e) => e.response?.statusCode,
          'statusCode',
          401,
        ),
      ),
    );

    expect(sessionExpired, isTrue);
    expect(storage.accessToken, isNull);
    expect(storage.refreshToken, isNull);
    // Tidak ada retry /tasks setelah refresh gagal.
    expect(requestsTo('/tasks'), hasLength(1));
    expect(requestsTo('/auth/refresh'), hasLength(1));
  });

  test('retry maksimal satu kali, 401 kedua tidak memicu refresh berantai',
      () async {
    adapter = FakeAdapter((options) async {
      if (options.path.endsWith('/auth/refresh')) {
        return jsonResponse({
          'accessToken': 'access-new',
          'refreshToken': 'refresh-new',
          'tokenType': 'Bearer',
        }, 200);
      }
      return jsonResponse(
        {'statusCode': 401, 'message': 'Unauthorized'},
        401,
      );
    });
    dio = buildDio();

    await expectLater(
      dio.get<Map<String, dynamic>>('/tasks'),
      throwsA(isA<DioException>()),
    );

    expect(requestsTo('/tasks'), hasLength(2)); // asli + 1 retry
    expect(requestsTo('/auth/refresh'), hasLength(1));
  });

  test(
      'token sudah dirotasi request lain → retry pakai token tersimpan '
      'tanpa refresh ulang', () async {
    adapter = FakeAdapter((options) async {
      if (options.path.endsWith('/tasks')) {
        final auth = options.headers['Authorization'];
        if (auth == 'Bearer access-rotated') {
          return jsonResponse({'data': 'ok'}, 200);
        }
        // Simulasikan request lain selesai refresh saat request ini in-flight.
        await storage.saveTokens(
          accessToken: 'access-rotated',
          refreshToken: 'refresh-rotated',
        );
        return jsonResponse(
          {'statusCode': 401, 'message': 'Unauthorized'},
          401,
        );
      }
      fail('refresh tidak boleh dipanggil: ${options.path}');
    });
    dio = buildDio();

    final res = await dio.get<Map<String, dynamic>>('/tasks');

    expect(res.data, {'data': 'ok'});
    expect(requestsTo('/auth/refresh'), isEmpty);
    expect(requestsTo('/tasks'), hasLength(2));
  });
}
