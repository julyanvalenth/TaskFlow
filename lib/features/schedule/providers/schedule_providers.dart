import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../tasks/data/models/task.dart';
import '../../tasks/data/models/task_filter.dart';
import '../../tasks/data/task_api.dart';

/// Hari yang dipilih pada halaman schedule (dinormalisasi ke tanggal,
/// tanpa komponen jam). Default: hari ini.
final selectedScheduleDayProvider =
    NotifierProvider<SelectedScheduleDayNotifier, DateTime>(
  SelectedScheduleDayNotifier.new,
);

class SelectedScheduleDayNotifier extends Notifier<DateTime> {
  @override
  DateTime build() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  void select(DateTime day) => state = DateTime(day.year, day.month, day.day);
}

/// Semua task yang punya dueDate, urut naik. API belum bisa filter rentang
/// tanggal, jadi pemilahan per hari dilakukan di klien.
final scheduleTasksProvider =
    FutureProvider.autoDispose<List<Task>>((ref) async {
  const filter = TaskFilter(
    sortBy: TaskSortBy.dueDate,
    sortOrder: 'asc',
    limit: 100,
  );
  final page = await ref.watch(taskApiProvider).list(filter);
  return page.data.where((t) => t.dueDate != null).toList();
});
