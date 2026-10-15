import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taskflow_mobile/features/tasks/data/models/task.dart';
import 'package:taskflow_mobile/features/tasks/data/models/task_filter.dart';
import 'package:taskflow_mobile/features/tasks/providers/task_providers.dart';

void main() {
  group('TaskFilter.toQueryParameters', () {
    test('default hanya berisi sort + paging', () {
      const filter = TaskFilter();
      expect(filter.toQueryParameters(), {
        'sortBy': 'createdAt',
        'sortOrder': 'desc',
        'page': 1,
        'limit': 50,
      });
    });

    test('semua filter aktif ikut terkirim dengan nilai wire API', () {
      const filter = TaskFilter(
        status: TaskStatus.inProgress,
        priority: TaskPriority.urgent,
        category: 'kuliah',
        search: '  laporan  ',
        sortBy: TaskSortBy.dueDate,
        sortOrder: 'asc',
        page: 3,
        limit: 20,
      );
      expect(filter.toQueryParameters(), {
        'status': 'IN_PROGRESS',
        'priority': 'URGENT',
        'category': 'kuliah',
        'search': 'laporan',
        'sortBy': 'dueDate',
        'sortOrder': 'asc',
        'page': 3,
        'limit': 20,
      });
    });

    test('search whitespace-only tidak dikirim', () {
      const filter = TaskFilter(search: '   ');
      expect(filter.toQueryParameters().containsKey('search'), isFalse);
    });
  });

  group('TaskFilterNotifier', () {
    late ProviderContainer container;
    late TaskFilterNotifier notifier;

    setUp(() {
      container = ProviderContainer();
      addTearDown(container.dispose);
      notifier = container.read(taskFilterProvider.notifier);
    });

    TaskFilter state() => container.read(taskFilterProvider);

    test('chip status berperilaku toggle', () {
      notifier.toggleStatus(TaskStatus.done);
      expect(state().status, TaskStatus.done);

      notifier.toggleStatus(TaskStatus.done);
      expect(state().status, isNull);

      notifier.toggleStatus(TaskStatus.todo);
      notifier.toggleStatus(TaskStatus.done);
      expect(state().status, TaskStatus.done, reason: 'ganti pilihan');
    });

    test('mengubah filter mengembalikan page ke 1', () {
      notifier.setSearch('x'); // pastikan state baru
      notifier.toggleStatus(TaskStatus.todo);
      expect(state().page, 1);

      notifier.togglePriority(TaskPriority.high);
      expect(state().priority, TaskPriority.high);
      expect(state().page, 1);
    });

    test('toggle kategori dan reset', () {
      notifier.toggleCategory('kerja');
      notifier.setSearch('rapat');
      expect(state().hasActiveFilter, isTrue);

      notifier.reset();
      expect(state().hasActiveFilter, isFalse);
      expect(state().category, isNull);
      expect(state().search, isEmpty);
    });

    test('setSort kolom sama membalik arah urutan', () {
      notifier.setSort(TaskSortBy.dueDate);
      expect(state().sortBy, TaskSortBy.dueDate);
      expect(state().sortOrder, 'asc');

      notifier.setSort(TaskSortBy.dueDate);
      expect(state().sortOrder, 'desc');

      notifier.setSort(TaskSortBy.priority);
      expect(state().sortBy, TaskSortBy.priority);
      expect(state().sortOrder, 'asc');
    });

    test('setSearch dengan nilai sama tidak mengubah state', () {
      notifier.setSearch('abc');
      final before = state();
      notifier.setSearch('abc');
      expect(identical(state(), before), isTrue);
    });
  });

  group('KnownCategoriesNotifier', () {
    test('mengakumulasi kategori unik terurut', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(knownCategoriesProvider.notifier);

      notifier.addAll(['kerja', 'kuliah']);
      notifier.addAll(['kuliah', 'pribadi', '']);

      expect(
        container.read(knownCategoriesProvider),
        ['kerja', 'kuliah', 'pribadi'],
      );
    });
  });
}
