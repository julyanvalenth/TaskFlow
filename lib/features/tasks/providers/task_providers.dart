import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/paginated.dart';
import '../data/models/task.dart';
import '../data/models/task_filter.dart';
import '../data/task_api.dart';
import '../../dashboard/providers/dashboard_providers.dart';
import '../../schedule/providers/schedule_providers.dart';

/// Filter aktif di halaman list: chip status/prioritas/kategori dan search.
final taskFilterProvider =
    NotifierProvider<TaskFilterNotifier, TaskFilter>(TaskFilterNotifier.new);

class TaskFilterNotifier extends Notifier<TaskFilter> {
  @override
  TaskFilter build() => const TaskFilter();

  /// Chip berperilaku toggle: memilih nilai yang sama akan menghapus filter.
  void toggleStatus(TaskStatus status) {
    state = state.copyWith(
      status: state.status == status ? null : status,
      page: 1,
    );
  }

  void togglePriority(TaskPriority priority) {
    state = state.copyWith(
      priority: state.priority == priority ? null : priority,
      page: 1,
    );
  }

  void toggleCategory(String category) {
    state = state.copyWith(
      category: state.category == category ? null : category,
      page: 1,
    );
  }

  void setSearch(String query) {
    if (query == state.search) return;
    state = state.copyWith(search: query, page: 1);
  }

  void setSort(TaskSortBy sortBy, {String? order}) {
    // Memilih kolom yang sama membalik arah urutan.
    final sameColumn = state.sortBy == sortBy;
    state = state.copyWith(
      sortBy: sortBy,
      sortOrder:
          order ?? (sameColumn ? (state.sortOrder == 'asc' ? 'desc' : 'asc') : 'asc'),
      page: 1,
    );
  }

  void reset() => state = const TaskFilter();
}

/// List task sesuai filter aktif. Pull-to-refresh cukup `ref.refresh`.
///
/// Mengambil sampai 5 halaman x 100 (sama dengan dashboard) supaya range
/// "All" lengkap dan angka di Home sama dengan halaman Progress.
final taskListProvider =
    FutureProvider.autoDispose<Paginated<Task>>((ref) async {
  final filter = ref.watch(taskFilterProvider);
  final api = ref.watch(taskApiProvider);

  const pageSize = 100;
  const maxPages = 5;
  final first = await api.list(filter.copyWith(limit: pageSize, page: 1));
  final tasks = [...first.data];
  var page = 1;
  while (page < first.meta.totalPages && page < maxPages) {
    page++;
    final next =
        await api.list(filter.copyWith(limit: pageSize, page: page));
    tasks.addAll(next.data);
  }

  ref.read(knownCategoriesProvider.notifier).addAll(
        tasks.expand((t) => t.categories),
      );
  return Paginated(data: tasks, meta: first.meta);
});

/// Kategori yang pernah muncul di sesi ini, untuk chip filter kategori.
/// Dikumpulkan terus (bukan dari list yang sudah terfilter) supaya chip
/// tidak hilang saat filter lain aktif.
final knownCategoriesProvider =
    NotifierProvider<KnownCategoriesNotifier, List<String>>(
  KnownCategoriesNotifier.new,
);

class KnownCategoriesNotifier extends Notifier<List<String>> {
  @override
  List<String> build() => const [];

  void addAll(Iterable<String> categories) {
    final merged = {...state, ...categories.where((c) => c.isNotEmpty)};
    if (merged.length != state.length) {
      state = merged.toList()..sort();
    }
  }
}

/// Detail satu task (untuk form edit).
final taskDetailProvider =
    FutureProvider.autoDispose.family<Task, String>((ref, id) {
  return ref.watch(taskApiProvider).getById(id);
});

/// Operasi tulis; meng-invalidate list & dashboard setelah sukses.
final taskMutationsProvider = Provider<TaskMutations>(TaskMutations.new);

class TaskMutations {
  TaskMutations(this._ref);

  final Ref _ref;

  TaskApi get _api => _ref.read(taskApiProvider);

  void _invalidate() {
    _ref.invalidate(taskListProvider);
    _ref.invalidate(dashboardProvider);
    _ref.invalidate(scheduleTasksProvider);
  }

  Future<Task> create(TaskInput input) async {
    final task = await _api.create(input);
    _invalidate();
    return task;
  }

  Future<Task> update(String id, Map<String, dynamic> patch) async {
    final task = await _api.update(id, patch);
    _ref.invalidate(taskDetailProvider(id));
    _invalidate();
    return task;
  }

  Future<Task> setStatus(String id, TaskStatus status) =>
      update(id, {'status': status.wire});

  Future<void> delete(String id) async {
    await _api.delete(id);
    _invalidate();
  }
}
