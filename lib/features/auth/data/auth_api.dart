import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/dio_client.dart';
import 'models/auth_tokens.dart';
import 'models/user.dart';

class AuthApi {
  AuthApi(this._dio);

  final Dio _dio;

  Future<User> register({
    required String email,
    required String password,
  }) =>
      apiGuard(() async {
        final res = await _dio.post<Map<String, dynamic>>(
          '/auth/register',
          data: {'email': email, 'password': password},
        );
        return User.fromJson(res.data!);
      });

  Future<AuthTokens> login({
    required String email,
    required String password,
  }) =>
      apiGuard(() async {
        final res = await _dio.post<Map<String, dynamic>>(
          '/auth/login',
          data: {'email': email, 'password': password},
        );
        return AuthTokens.fromJson(res.data!);
      });

  Future<User> profile() => apiGuard(() async {
        final res = await _dio.get<Map<String, dynamic>>('/auth/profile');
        return User.fromJson(res.data!);
      });
}

final authApiProvider = Provider<AuthApi>((ref) {
  return AuthApi(ref.watch(dioProvider));
});
