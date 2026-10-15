import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taskflow_mobile/core/network/api_exception.dart';
import 'package:taskflow_mobile/features/tasks/data/models/paginated.dart';
import 'package:taskflow_mobile/features/tasks/data/models/task.dart';

void main() {
  group('Task.fromJson', () {
    test('parse JSON lengkap sesuai kontrak API', () {
      final task = Task.fromJson({
        'id': 't-1',
        'userId': 'u-1',
        'title': 'Belajar Flutter',
        'description': 'Riverpod + Dio',
        'dueDate': '2026-07-20T09:00:00.000Z',
        'priority': 'URGENT',
        'categories': ['kuliah', 'kerja'],
        'subtasks': [
          {'title': 'Setup project', 'done': true},
          {'title': 'Bikin UI', 'done': false},
        ],
        'status': 'IN_PROGRESS',
        'createdAt': '2026-07-10T01:00:00.000Z',
        'updatedAt': '2026-07-11T02:30:00.000Z',
      });

      expect(task.id, 't-1');
      expect(task.userId, 'u-1');
      expect(task.title, 'Belajar Flutter');
      expect(task.description, 'Riverpod + Dio');
      expect(task.priority, TaskPriority.urgent);
      expect(task.status, TaskStatus.inProgress);
      expect(task.categories, ['kuliah', 'kerja']);
      expect(task.categoryLabel, 'kuliah • kerja');
      expect(task.subtasks, hasLength(2));
      expect(task.subtasksDone, 1);
      expect(task.subtaskProgress, 0.5);
      // dueDate dikonversi ke waktu lokal, momen tetap sama.
      expect(
        task.dueDate!.toUtc(),
        DateTime.utc(2026, 7, 20, 9),
      );
      expect(task.isDone, isFalse);
    });

    test('payload lama ber-category tunggal tetap terbaca', () {
      final task = Task.fromJson({
        'id': 't-1b',
        'userId': 'u-1',
        'title': 'Legacy',
        'priority': 'LOW',
        'category': 'kuliah',
        'status': 'TODO',
        'createdAt': '2026-07-10T01:00:00.000Z',
        'updatedAt': '2026-07-10T01:00:00.000Z',
      });

      expect(task.categories, ['kuliah']);
      expect(task.categoryLabel, 'kuliah');
    });

    test('field opsional null tetap aman', () {
      final task = Task.fromJson({
        'id': 't-2',
        'userId': 'u-1',
        'title': 'Tanpa deskripsi',
        'description': null,
        'dueDate': null,
        'priority': 'LOW',
        'categories': null,
        'subtasks': null,
        'status': 'DONE',
        'createdAt': '2026-07-10T01:00:00.000Z',
        'updatedAt': '2026-07-10T01:00:00.000Z',
      });

      expect(task.description, isNull);
      expect(task.dueDate, isNull);
      expect(task.categories, isEmpty);
      expect(task.categoryLabel, isNull);
      expect(task.subtasks, isEmpty);
      expect(task.subtaskProgress, isNull);
      expect(task.isDone, isTrue);
      expect(task.isOverdue, isFalse);
    });

    test('nilai enum tak dikenal jatuh ke default aman', () {
      expect(TaskPriority.fromWire('EXTREME'), TaskPriority.medium);
      expect(TaskStatus.fromWire('ARCHIVED'), TaskStatus.todo);
    });

    test('isOverdue true untuk task belum selesai yang lewat tenggat', () {
      final task = Task.fromJson({
        'id': 't-3',
        'userId': 'u-1',
        'title': 'Terlambat',
        'priority': 'HIGH',
        'status': 'TODO',
        'dueDate':
            DateTime.now().subtract(const Duration(days: 1)).toUtc().toIso8601String(),
        'createdAt': '2026-07-10T01:00:00.000Z',
        'updatedAt': '2026-07-10T01:00:00.000Z',
      });
      expect(task.isOverdue, isTrue);
    });
  });

  group('TaskInput.toJson', () {
    test('dueDate dikirim sebagai ISO-8601 UTC', () {
      final localDue = DateTime(2026, 7, 20, 16, 30); // waktu lokal
      final json = TaskInput(
        title: 'Kirim laporan',
        dueDate: localDue,
        priority: TaskPriority.high,
        status: TaskStatus.todo,
      ).toJson();

      final wire = json['dueDate'] as String;
      expect(wire, endsWith('Z'));
      expect(DateTime.parse(wire), localDue.toUtc());
      expect(json['priority'], 'HIGH');
      expect(json['status'], 'TODO');
    });

    test('field kosong/null tidak ikut dikirim', () {
      final json = TaskInput(title: 'Minimal', description: '').toJson();
      expect(json.keys, ['title']);
    });

    test('categories & subtasks dikirim, termasuk list kosong (clear)', () {
      final json = TaskInput(
        title: 'Dengan checklist',
        categories: const ['kuliah', 'kerja'],
        subtasks: const [Subtask(title: 'Draft', done: true)],
      ).toJson();

      expect(json['categories'], ['kuliah', 'kerja']);
      expect(json['subtasks'], [
        {'title': 'Draft', 'done': true},
      ]);

      // List kosong tetap dikirim agar server bisa mengosongkan nilai.
      final cleared = TaskInput(
        title: 'Bersih',
        categories: const [],
        subtasks: const [],
      ).toJson();
      expect(cleared['categories'], isEmpty);
      expect(cleared['subtasks'], isEmpty);
    });
  });

  group('Paginated.fromJson', () {
    test('parse envelope {data, meta}', () {
      final page = Paginated.fromJson({
        'data': [
          {
            'id': 't-1',
            'userId': 'u-1',
            'title': 'A',
            'priority': 'LOW',
            'status': 'TODO',
            'createdAt': '2026-07-10T01:00:00.000Z',
            'updatedAt': '2026-07-10T01:00:00.000Z',
          },
        ],
        'meta': {'total': 12, 'page': 2, 'limit': 10, 'totalPages': 2},
      }, Task.fromJson);

      expect(page.data, hasLength(1));
      expect(page.data.single.title, 'A');
      expect(page.meta.total, 12);
      expect(page.meta.page, 2);
      expect(page.meta.totalPages, 2);
    });
  });

  group('ApiException', () {
    DioException badResponse(Object body, int status) => DioException(
        requestOptions: RequestOptions(path: '/tasks'),
        type: DioExceptionType.badResponse,
        response: Response(
          requestOptions: RequestOptions(path: '/tasks'),
          statusCode: status,
          data: body,
        ),
      );

    test('message berupa array validasi → details per pesan', () {
      final e = ApiException.fromDioException(badResponse({
        'statusCode': 400,
        'message': [
          'title should not be empty',
          'dueDate must be a valid ISO 8601 date string',
        ],
        'error': 'Bad Request',
      }, 400));

      expect(e.type, ApiErrorType.validation);
      expect(e.details, hasLength(2));
      expect(e.errorFor('title'), 'title should not be empty');
      expect(
        e.errorFor('dueDate'),
        'dueDate must be a valid ISO 8601 date string',
      );
      expect(e.errorFor('category'), isNull);
      expect(e.displayMessage, contains('title should not be empty'));
    });

    test('message string biasa', () {
      final e = ApiException.fromDioException(badResponse({
        'statusCode': 409,
        'message': 'Email already registered',
        'error': 'Conflict',
      }, 409));

      expect(e.type, ApiErrorType.conflict);
      expect(e.message, 'Email already registered');
      expect(e.details, isEmpty);
    });

    test('timeout → tipe network dengan pesan ramah', () {
      final e = ApiException.fromDioException(DioException(
        requestOptions: RequestOptions(path: '/tasks'),
        type: DioExceptionType.connectionTimeout,
      ));
      expect(e.type, ApiErrorType.network);
      expect(e.message, contains('koneksi'));
    });

    test('5xx → tipe server', () {
      final e = ApiException.fromDioException(
        badResponse({'statusCode': 502, 'message': 'Bad Gateway'}, 502),
      );
      expect(e.type, ApiErrorType.server);
    });
  });
}
