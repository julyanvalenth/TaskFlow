import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../settings/providers/settings_providers.dart';
import '../data/models/task.dart';

/// State UI Home: mode College/Daily, tampilan card/list, dan range chip
/// (Today/Week/Month/All). Mode dan tampilan disimpan.

enum TaskMode {
  college('College'),
  daily('Daily');

  const TaskMode(this.label);
  final String label;
}

final taskModeProvider =
    NotifierProvider<TaskModeNotifier, TaskMode>(TaskModeNotifier.new);

class TaskModeNotifier extends Notifier<TaskMode> {
  static const _key = 'lumo_task_mode';

  @override
  TaskMode build() {
    final saved = ref.read(sharedPreferencesProvider).getString(_key);
    return TaskMode.values.firstWhere(
      (m) => m.name == saved,
      orElse: () => TaskMode.college,
    );
  }

  Future<void> set(TaskMode mode) async {
    state = mode;
    await ref.read(sharedPreferencesProvider).setString(_key, mode.name);
  }
}

enum TaskViewStyle { card, list }

final taskViewProvider =
    NotifierProvider<TaskViewNotifier, TaskViewStyle>(TaskViewNotifier.new);

class TaskViewNotifier extends Notifier<TaskViewStyle> {
  static const _key = 'lumo_task_view';

  @override
  TaskViewStyle build() {
    final saved = ref.read(sharedPreferencesProvider).getString(_key);
    return TaskViewStyle.values.firstWhere(
      (v) => v.name == saved,
      orElse: () => TaskViewStyle.card,
    );
  }

  Future<void> set(TaskViewStyle view) async {
    state = view;
    await ref.read(sharedPreferencesProvider).setString(_key, view.name);
  }
}

enum TaskRange {
  today('Today'),
  week('Week'),
  month('Month'),
  all('All');

  const TaskRange(this.label);
  final String label;
}

final taskRangeProvider =
    NotifierProvider<TaskRangeNotifier, TaskRange>(TaskRangeNotifier.new);

class TaskRangeNotifier extends Notifier<TaskRange> {
  @override
  TaskRange build() => TaskRange.today;

  void set(TaskRange range) => state = range;
}

/// Helper filter sisi klien (mode + range) atas list task dari API.

bool taskMatchesMode(Task task, TaskMode mode) =>
    mode == TaskMode.daily ? task.isDailyMode : !task.isDailyMode;

bool taskMatchesRange(Task task, TaskRange range, {DateTime? now}) {
  if (range == TaskRange.all) return true;
  final due = task.dueDate;
  if (due == null) return false;

  final reference = now ?? DateTime.now();
  final today = DateTime(reference.year, reference.month, reference.day);
  final dueDay = DateTime(due.year, due.month, due.day);

  // Task lewat tenggat & belum selesai tetap muncul di semua range.
  if (dueDay.isBefore(today)) return !task.isDone;

  final horizon = switch (range) {
    TaskRange.today => today,
    TaskRange.week => today.add(const Duration(days: 6)),
    TaskRange.month => today.add(const Duration(days: 29)),
    TaskRange.all => today, // unreachable
  };
  return !dueDay.isAfter(horizon);
}

/// Urutkan: ber-tenggat dulu (naik), tanpa tenggat di akhir (terbaru dulu).
List<Task> sortTasksForHome(List<Task> tasks) {
  final sorted = tasks.toList()
    ..sort((a, b) {
      if (a.dueDate == null && b.dueDate == null) {
        return b.createdAt.compareTo(a.createdAt);
      }
      if (a.dueDate == null) return 1;
      if (b.dueDate == null) return -1;
      return a.dueDate!.compareTo(b.dueDate!);
    });
  return sorted;
}

/// Jumlah task dalam list yang selesai hari ini, untuk ring "Daily goal"
/// di mode aktif. Hari selesai diambil dari `updatedAt` task DONE.
int countDoneToday(List<Task> tasks, {DateTime? now}) {
  final reference = now ?? DateTime.now();
  final today =
      DateTime(reference.year, reference.month, reference.day);
  return tasks.where((t) {
    if (!t.isDone) return false;
    final local = t.updatedAt.toLocal();
    return DateTime(local.year, local.month, local.day) == today;
  }).length;
}

/// Statistik per kategori untuk rail "Courses/Categories" di Home.
class CategoryStat {
  const CategoryStat({
    required this.name,
    required this.total,
    required this.done,
  });

  final String name;
  final int total;
  final int done;

  int get left => total - done;
  int get pct => total == 0 ? 0 : ((done / total) * 100).round();
}

List<CategoryStat> computeCategoryStats(List<Task> tasks) {
  final totals = <String, int>{};
  final dones = <String, int>{};
  for (final task in tasks) {
    for (final cat in task.visibleCategories) {
      totals[cat] = (totals[cat] ?? 0) + 1;
      if (task.isDone) dones[cat] = (dones[cat] ?? 0) + 1;
    }
  }
  final stats = totals.keys
      .map((name) => CategoryStat(
            name: name,
            total: totals[name]!,
            done: dones[name] ?? 0,
          ))
      .toList()
    ..sort((a, b) => b.total.compareTo(a.total));
  return stats;
}
