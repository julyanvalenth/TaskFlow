class PageMeta {
  const PageMeta({
    required this.total,
    required this.page,
    required this.limit,
    required this.totalPages,
  });

  factory PageMeta.fromJson(Map<String, dynamic> json) => PageMeta(
        total: (json['total'] as num).toInt(),
        page: (json['page'] as num).toInt(),
        limit: (json['limit'] as num).toInt(),
        totalPages: (json['totalPages'] as num).toInt(),
      );

  final int total;
  final int page;
  final int limit;
  final int totalPages;
}

/// Respons list API: `{data: T[], meta: {...}}`.
class Paginated<T> {
  const Paginated({required this.data, required this.meta});

  factory Paginated.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) itemFromJson,
  ) =>
      Paginated(
        data: (json['data'] as List)
            .map((e) => itemFromJson(e as Map<String, dynamic>))
            .toList(growable: false),
        meta: PageMeta.fromJson(json['meta'] as Map<String, dynamic>),
      );

  final List<T> data;
  final PageMeta meta;
}
