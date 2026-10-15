import 'package:flutter_test/flutter_test.dart';
import 'package:taskflow_mobile/features/dashboard/providers/dashboard_providers.dart';
import 'package:taskflow_mobile/features/tasks/data/models/task.dart';

Task makeTask(
  String id, {
  TaskStatus status = TaskStatus.todo,
  TaskPriority priority = TaskPriority.medium,
  DateTime? dueDate,
  DateTime? updatedAt,
  List<String> categories = const [],
}) =>
    Task(
      id: id,
      userId: 'u-1',
      title: 'Task $id',
      status: status,
      priority: priority,
      dueDate: dueDate,
      categories: categories,
      createdAt: DateTime(2026, 7, 1),
      updatedAt: updatedAt ?? DateTime(2026, 7, 1),
    );

void main() {
  final now = DateTime(2026, 7, 12, 12);

  test('menghitung selesai vs pending dan distribusi', () {
    final stats = computeStats([
      makeTask('1', status: TaskStatus.done, priority: TaskPriority.low),
      makeTask('2', status: TaskStatus.done, priority: TaskPriority.urgent),
      makeTask('3', status: TaskStatus.inProgress),
      makeTask('4', status: TaskStatus.todo, priority: TaskPriority.high),
    ], now: now);

    expect(stats.total, 4);
    expect(stats.done, 2);
    expect(stats.pending, 2);
    expect(stats.doneRatio, 0.5);
    expect(stats.byPriority[TaskPriority.medium], 1);
    expect(stats.byPriority[TaskPriority.urgent], 1);
    expect(stats.byStatus[TaskStatus.inProgress], 1);
  });

  test('upcoming: hanya task belum selesai dengan tenggat ≤ 7 hari, terurut',
      () {
    final stats = computeStats([
      makeTask('due-3h', dueDate: now.add(const Duration(hours: 3))),
      makeTask('due-6d', dueDate: now.add(const Duration(days: 6))),
      makeTask('due-10d', dueDate: now.add(const Duration(days: 10))),
      makeTask(
        'done-due-1d',
        status: TaskStatus.done,
        dueDate: now.add(const Duration(days: 1)),
      ),
      makeTask('no-due'),
    ], now: now);

    expect(stats.upcoming.map((t) => t.id), ['due-3h', 'due-6d']);
  });

  test('overdue: task lewat tenggat yang belum selesai, terurut', () {
    final stats = computeStats([
      makeTask('late-2d', dueDate: now.subtract(const Duration(days: 2))),
      makeTask('late-1h', dueDate: now.subtract(const Duration(hours: 1))),
      makeTask(
        'done-late',
        status: TaskStatus.done,
        dueDate: now.subtract(const Duration(days: 5)),
      ),
    ], now: now);

    expect(stats.overdue.map((t) => t.id), ['late-2d', 'late-1h']);
  });

  test('daftar kosong aman', () {
    final stats = computeStats(const [], now: now);
    expect(stats.total, 0);
    expect(stats.pending, 0);
    expect(stats.doneRatio, 0);
    expect(stats.upcoming, isEmpty);
    expect(stats.streak, 0);
    expect(stats.bestStreak, 0);
    expect(stats.doneToday, 0);
    expect(stats.byCategory, isEmpty);
  });

  group('progress Lumo', () {
    // now = Minggu 12 Jul 2026; Senin minggu berjalan = 6 Jul.
    Task doneOn(String id, DateTime day, {List<String> categories = const []}) =>
        makeTask(id,
            status: TaskStatus.done, updatedAt: day, categories: categories);

    test('doneToday & bar mingguan (index 0 = Senin)', () {
      final stats = computeStats([
        doneOn('a', DateTime(2026, 7, 12, 9)), // Minggu (hari ini)
        doneOn('b', DateTime(2026, 7, 12, 20)), // Minggu (hari ini)
        doneOn('c', DateTime(2026, 7, 6, 10)), // Senin minggu ini
        doneOn('d', DateTime(2026, 7, 4, 10)), // Sabtu minggu lalu
        makeTask('e'), // belum selesai
      ], now: now);

      expect(stats.doneToday, 2);
      expect(stats.doneByWeekday, [1, 0, 0, 0, 0, 0, 2]);
      expect(stats.doneThisWeek, 3);
      expect(stats.activeDaysThisWeek, 2);
    });

    test('streak dihitung mundur, hari ini kosong tidak memutus', () {
      final stats = computeStats([
        doneOn('a', DateTime(2026, 7, 11)), // kemarin
        doneOn('b', DateTime(2026, 7, 10)),
        doneOn('c', DateTime(2026, 7, 8)), // putus di 9 Jul
      ], now: now);

      expect(stats.streak, 2);
      expect(stats.bestStreak, 2);
    });

    test('bestStreak: run terpanjang di riwayat', () {
      final stats = computeStats([
        doneOn('a', DateTime(2026, 7, 1)),
        doneOn('b', DateTime(2026, 7, 2)),
        doneOn('c', DateTime(2026, 7, 3)),
        doneOn('d', DateTime(2026, 7, 12)),
      ], now: now);

      expect(stats.streak, 1);
      expect(stats.bestStreak, 3);
    });

    test('byCategory: tag mode @daily disembunyikan', () {
      final stats = computeStats([
        doneOn('a', now, categories: ['Kalkulus', kDailyModeTag]),
        makeTask('b', categories: ['Kalkulus']),
        makeTask('c', categories: [kDailyModeTag]),
      ], now: now);

      expect(stats.byCategory.length, 1);
      expect(stats.byCategory.first.name, 'Kalkulus');
      expect(stats.byCategory.first.total, 2);
      expect(stats.byCategory.first.done, 1);
      expect(stats.byCategory.first.pct, 50);
    });
  });
}
