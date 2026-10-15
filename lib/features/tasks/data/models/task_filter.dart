import 'task.dart';

enum TaskSortBy {
  dueDate('dueDate', 'Tenggat'),
  priority('priority', 'Prioritas'),
  createdAt('createdAt', 'Dibuat');

  const TaskSortBy(this.wire, this.label);

  final String wire;
  final String label;
}

/// Kriteria filter, search, dan sort untuk list task.
class TaskFilter {
  const TaskFilter({
    this.status,
    this.priority,
    this.category,
    this.search = '',
    this.sortBy = TaskSortBy.createdAt,
    this.sortOrder = 'desc',
    this.page = 1,
    this.limit = 50,
  });

  final TaskStatus? status;
  final TaskPriority? priority;
  final String? category;
  final String search;
  final TaskSortBy sortBy;
  final String sortOrder; // 'asc' | 'desc'
  final int page;
  final int limit;

  static const Object _unset = Object();

  TaskFilter copyWith({
    Object? status = _unset,
    Object? priority = _unset,
    Object? category = _unset,
    String? search,
    TaskSortBy? sortBy,
    String? sortOrder,
    int? page,
    int? limit,
  }) =>
      TaskFilter(
        status: identical(status, _unset) ? this.status : status as TaskStatus?,
        priority: identical(priority, _unset)
            ? this.priority
            : priority as TaskPriority?,
        category:
            identical(category, _unset) ? this.category : category as String?,
        search: search ?? this.search,
        sortBy: sortBy ?? this.sortBy,
        sortOrder: sortOrder ?? this.sortOrder,
        page: page ?? this.page,
        limit: limit ?? this.limit,
      );

  bool get hasActiveFilter =>
      status != null ||
      priority != null ||
      category != null ||
      search.isNotEmpty;

  /// Query parameter untuk `GET /tasks`. Nilai kosong tidak ikut dikirim.
  Map<String, dynamic> toQueryParameters() => {
        if (status != null) 'status': status!.wire,
        if (priority != null) 'priority': priority!.wire,
        if (category != null && category!.isNotEmpty) 'category': category,
        if (search.trim().isNotEmpty) 'search': search.trim(),
        'sortBy': sortBy.wire,
        'sortOrder': sortOrder,
        'page': page,
        'limit': limit,
      };
}
