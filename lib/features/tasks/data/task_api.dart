import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/dio_client.dart';
import 'models/paginated.dart';
import 'models/task.dart';
import 'models/task_filter.dart';

class TaskApi {
  TaskApi(this._dio);

  final Dio _dio;

  Future<Paginated<Task>> list(TaskFilter filter) => apiGuard(() async {
        final res = await _dio.get<Map<String, dynamic>>(
          '/tasks',
          queryParameters: filter.toQueryParameters(),
        );
        return Paginated.fromJson(res.data!, Task.fromJson);
      });

  Future<Task> getById(String id) => apiGuard(() async {
        final res = await _dio.get<Map<String, dynamic>>('/tasks/$id');
        return Task.fromJson(res.data!);
      });

  Future<Task> create(TaskInput input) => apiGuard(() async {
        final res = await _dio.post<Map<String, dynamic>>(
          '/tasks',
          data: input.toJson(),
        );
        return Task.fromJson(res.data!);
      });

  Future<Task> update(String id, Map<String, dynamic> patch) =>
      apiGuard(() async {
        final res = await _dio.patch<Map<String, dynamic>>(
          '/tasks/$id',
          data: patch,
        );
        return Task.fromJson(res.data!);
      });

  Future<void> delete(String id) => apiGuard(() async {
        await _dio.delete<void>('/tasks/$id'); // 204
      });
}

final taskApiProvider = Provider<TaskApi>((ref) {
  return TaskApi(ref.watch(dioProvider));
});
