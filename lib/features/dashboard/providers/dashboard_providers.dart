import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../tasks/data/models/task.dart';
import '../../tasks/data/models/task_filter.dart';
import '../../tasks/data/task_api.dart';

/// Statistik dashboard (streak, goal harian, bar mingguan, per kategori),
/// dihitung di klien dari daftar task.
///
/// Hari selesai diambil dari `updatedAt` task DONE karena API tidak
/// menyimpan completedAt.
class DashboardStats {
  const DashboardStats({
    required this.total,
    required this.byStatus,
    required this.byPriority,
    required this.upcoming,
    required this.overdue,
    required this.doneToday,
    required this.doneThisWeek,
    required this.doneByWeekday,
    required this.streak,
    required this.bestStreak,
    required this.activeDaysThisWeek,
    required this.byCategory,
  });

  final int total;
  final Map<TaskStatus, int> byStatus;
  final Map<TaskPriority, int> byPriority;

  /// Task belum selesai dengan tenggat ≤ 7 hari ke depan, terdekat dulu.
  final List<Task> upcoming;

  /// Task belum selesai yang sudah lewat tenggat.
  final List<Task> overdue;

  /// Task selesai hari ini, untuk ring "Daily goal".
  final int doneToday;

  /// Task selesai minggu ini (Senin sampai Minggu).
  final int doneThisWeek;

  /// Jumlah selesai per hari minggu ini, index 0 = Senin.
  final List<int> doneByWeekday;

  /// Hari beruntun dengan minimal 1 task selesai, dihitung mundur dari hari
  /// ini. Hari ini boleh masih kosong tanpa memutus streak.
  final int streak;

  /// Streak terpanjang yang pernah tercapai.
  final int bestStreak;

  /// Hari aktif (≥1 selesai) minggu ini.
  final int activeDaysThisWeek;

  /// Progress per kategori (untuk "By course/category").
  final List<CategoryProgress> byCategory;

  int get done => byStatus[TaskStatus.done] ?? 0;
  int get pending => total - done;
  double get doneRatio => total == 0 ? 0 : done / total;
}

class CategoryProgress {
  const CategoryProgress({
    required this.name,
    required this.total,
    required this.done,
  });

  final String name;
  final int total;
  final int done;

  int get pct => total == 0 ? 0 : ((done / total) * 100).round();
}

DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

DashboardStats computeStats(List<Task> tasks, {DateTime? now}) {
  final reference = now ?? DateTime.now();
  final horizon = reference.add(const Duration(days: 7));
  final today = _dateOnly(reference);
  final monday = today.subtract(Duration(days: today.weekday - 1));

  final byStatus = <TaskStatus, int>{};
  final byPriority = <TaskPriority, int>{};
  final upcoming = <Task>[];
  final overdue = <Task>[];
  final doneDays = <DateTime>{};
  final doneByWeekday = List<int>.filled(7, 0);
  final catTotals = <String, int>{};
  final catDones = <String, int>{};
  var doneToday = 0;

  for (final task in tasks) {
    byStatus[task.status] = (byStatus[task.status] ?? 0) + 1;
    byPriority[task.priority] = (byPriority[task.priority] ?? 0) + 1;

    for (final cat in task.visibleCategories) {
      catTotals[cat] = (catTotals[cat] ?? 0) + 1;
      if (task.isDone) catDones[cat] = (catDones[cat] ?? 0) + 1;
    }

    if (task.isDone) {
      final doneDay = _dateOnly(task.updatedAt.toLocal());
      doneDays.add(doneDay);
      if (doneDay == today) doneToday++;
      final sinceMonday = doneDay.difference(monday).inDays;
      if (sinceMonday >= 0 && sinceMonday < 7) {
        doneByWeekday[sinceMonday]++;
      }
    }

    final due = task.dueDate;
    if (!task.isDone && due != null) {
      if (due.isBefore(reference)) {
        overdue.add(task);
      } else if (!due.isAfter(horizon)) {
        upcoming.add(task);
      }
    }
  }

  int byDue(Task a, Task b) => a.dueDate!.compareTo(b.dueDate!);
  upcoming.sort(byDue);
  overdue.sort(byDue);

  // Streak berjalan: mundur dari hari ini (atau kemarin bila hari ini kosong).
  var streak = 0;
  var cursor = doneDays.contains(today)
      ? today
      : today.subtract(const Duration(days: 1));
  while (doneDays.contains(cursor)) {
    streak++;
    cursor = cursor.subtract(const Duration(days: 1));
  }

  // Streak terbaik: run beruntun terpanjang di seluruh riwayat.
  var bestStreak = 0;
  final sortedDays = doneDays.toList()..sort();
  var run = 0;
  DateTime? prev;
  for (final day in sortedDays) {
    run = (prev != null && day.difference(prev).inDays == 1) ? run + 1 : 1;
    if (run > bestStreak) bestStreak = run;
    prev = day;
  }

  final byCategory = catTotals.keys
      .map((name) => CategoryProgress(
            name: name,
            total: catTotals[name]!,
            done: catDones[name] ?? 0,
          ))
      .toList()
    ..sort((a, b) => b.total.compareTo(a.total));

  return DashboardStats(
    total: tasks.length,
    byStatus: byStatus,
    byPriority: byPriority,
    upcoming: upcoming,
    overdue: overdue,
    doneToday: doneToday,
    doneThisWeek: doneByWeekday.fold(0, (a, b) => a + b),
    doneByWeekday: doneByWeekday,
    streak: streak,
    bestStreak: bestStreak,
    activeDaysThisWeek: doneByWeekday.where((c) => c > 0).length,
    byCategory: byCategory,
  );
}

final dashboardProvider =
    FutureProvider.autoDispose<DashboardStats>((ref) async {
  final api = ref.watch(taskApiProvider);

  // Ambil hingga 5 halaman x 100 task untuk perhitungan statistik.
  const limit = 100;
  final tasks = <Task>[];
  var page = 1;
  while (true) {
    final result = await api.list(TaskFilter(page: page, limit: limit));
    tasks.addAll(result.data);
    if (page >= result.meta.totalPages || page >= 5) break;
    page++;
  }
  return computeStats(tasks);
});
