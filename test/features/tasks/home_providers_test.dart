import 'package:flutter_test/flutter_test.dart';
import 'package:taskflow_mobile/features/tasks/data/models/task.dart';
import 'package:taskflow_mobile/features/tasks/providers/home_providers.dart';

Task makeTask(
  String id, {
  TaskStatus status = TaskStatus.todo,
  DateTime? dueDate,
  List<String> categories = const [],
  DateTime? createdAt,
}) =>
    Task(
      id: id,
      userId: 'u-1',
      title: 'Task $id',
      status: status,
      priority: TaskPriority.medium,
      dueDate: dueDate,
      categories: categories,
      createdAt: createdAt ?? DateTime(2026, 7, 1),
      updatedAt: DateTime(2026, 7, 1),
    );

void main() {
  final now = DateTime(2026, 7, 17, 12); // Jumat

  group('taskMatchesMode', () {
    test('College = tanpa tag @daily, Daily = dengan tag', () {
      final college = makeTask('c', categories: ['Kalkulus']);
      final daily = makeTask('d', categories: ['Fitness', kDailyModeTag]);

      expect(taskMatchesMode(college, TaskMode.college), isTrue);
      expect(taskMatchesMode(college, TaskMode.daily), isFalse);
      expect(taskMatchesMode(daily, TaskMode.daily), isTrue);
      expect(taskMatchesMode(daily, TaskMode.college), isFalse);
    });
  });

  group('taskMatchesRange', () {
    test('today: hanya tenggat hari ini', () {
      final today = makeTask('t', dueDate: DateTime(2026, 7, 17, 20));
      final tomorrow = makeTask('b', dueDate: DateTime(2026, 7, 18, 9));

      expect(taskMatchesRange(today, TaskRange.today, now: now), isTrue);
      expect(taskMatchesRange(tomorrow, TaskRange.today, now: now), isFalse);
      expect(taskMatchesRange(tomorrow, TaskRange.week, now: now), isTrue);
    });

    test('overdue belum selesai selalu muncul; yang selesai tidak', () {
      final late = makeTask('l', dueDate: DateTime(2026, 7, 15));
      final lateDone = makeTask(
        'ld',
        status: TaskStatus.done,
        dueDate: DateTime(2026, 7, 15),
      );

      expect(taskMatchesRange(late, TaskRange.today, now: now), isTrue);
      expect(taskMatchesRange(lateDone, TaskRange.today, now: now), isFalse);
    });

    test('week/month batas horizon; all menerima tanpa tenggat', () {
      final in6 = makeTask('w', dueDate: DateTime(2026, 7, 23));
      final in10 = makeTask('m', dueDate: DateTime(2026, 7, 27));
      final noDue = makeTask('n');

      expect(taskMatchesRange(in6, TaskRange.week, now: now), isTrue);
      expect(taskMatchesRange(in10, TaskRange.week, now: now), isFalse);
      expect(taskMatchesRange(in10, TaskRange.month, now: now), isTrue);
      expect(taskMatchesRange(noDue, TaskRange.week, now: now), isFalse);
      expect(taskMatchesRange(noDue, TaskRange.all, now: now), isTrue);
    });
  });

  group('sortTasksForHome', () {
    test('bertenggat naik, tanpa tenggat di akhir', () {
      final sorted = sortTasksForHome([
        makeTask('no-due', createdAt: DateTime(2026, 7, 2)),
        makeTask('later', dueDate: DateTime(2026, 7, 18)),
        makeTask('sooner', dueDate: DateTime(2026, 7, 17, 9)),
      ]);

      expect(sorted.map((t) => t.id), ['sooner', 'later', 'no-due']);
    });
  });

  group('countDoneToday', () {
    Task doneAt(String id, DateTime updatedAt) => Task(
          id: id,
          userId: 'u-1',
          title: 'Task $id',
          status: TaskStatus.done,
          priority: TaskPriority.medium,
          createdAt: DateTime(2026, 7, 1),
          updatedAt: updatedAt,
        );

    test('hanya menghitung task DONE dengan updatedAt hari ini', () {
      final count = countDoneToday([
        doneAt('a', DateTime(2026, 7, 17, 8)), // hari ini
        doneAt('b', DateTime(2026, 7, 17, 22)), // hari ini
        doneAt('c', DateTime(2026, 7, 16, 23)), // kemarin
        makeTask('d', dueDate: DateTime(2026, 7, 17)), // belum selesai
      ], now: now);

      expect(count, 2);
    });

    test('list kosong aman', () {
      expect(countDoneToday(const [], now: now), 0);
    });
  });

  group('computeCategoryStats', () {
    test('menghitung total/done/left/pct per kategori visible', () {
      final stats = computeCategoryStats([
        makeTask('1', categories: ['Kalkulus'], status: TaskStatus.done),
        makeTask('2', categories: ['Kalkulus']),
        makeTask('3', categories: ['UX']),
        makeTask('4', categories: [kDailyModeTag]),
      ]);

      expect(stats.length, 2);
      expect(stats.first.name, 'Kalkulus'); // terbanyak dulu
      expect(stats.first.total, 2);
      expect(stats.first.done, 1);
      expect(stats.first.left, 1);
      expect(stats.first.pct, 50);
      expect(stats.last.name, 'UX');
    });
  });
}
