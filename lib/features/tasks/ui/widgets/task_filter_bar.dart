import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_tokens.dart';
import '../../data/models/task.dart';
import '../../data/models/task_filter.dart';
import '../../providers/task_providers.dart';

/// Search bar dan filter chip (status, prioritas, kategori, sort).
class TaskFilterBar extends ConsumerStatefulWidget {
  const TaskFilterBar({super.key});

  @override
  ConsumerState<TaskFilterBar> createState() => _TaskFilterBarState();
}

class _TaskFilterBarState extends ConsumerState<TaskFilterBar> {
  final _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(AppDurations.searchDebounce, () {
      ref.read(taskFilterProvider.notifier).setSearch(value);
    });
  }

  @override
  Widget build(BuildContext context) {
    final filter = ref.watch(taskFilterProvider);
    final categories = ref.watch(knownCategoriesProvider);
    final brightness = Theme.of(context).brightness;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: TextField(
            controller: _searchController,
            onChanged: _onSearchChanged,
            textInputAction: TextInputAction.search,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Cari task…',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: filter.search.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () {
                        _searchController.clear();
                        ref.read(taskFilterProvider.notifier).setSearch('');
                      },
                    )
                  : null,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),

        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Row(
            children: [
              for (final status in TaskStatus.values) ...[
                _FilterPill(
                  label: status.label,
                  isSelected: filter.status == status,
                  onTap: () => ref
                      .read(taskFilterProvider.notifier)
                      .toggleStatus(status),
                ),
                const SizedBox(width: AppSpacing.sm),
              ],
              _PillDivider(),
              const SizedBox(width: AppSpacing.sm),
              for (final priority in TaskPriority.values) ...[
                _FilterPill(
                  label: priority.label,
                  isSelected: filter.priority == priority,
                  onTap: () => ref
                      .read(taskFilterProvider.notifier)
                      .togglePriority(priority),
                  icon: Icons.flag_rounded,
                  iconColor: priority.color(brightness),
                ),
                const SizedBox(width: AppSpacing.sm),
              ],
              if (categories.isNotEmpty) ...[
                _PillDivider(),
                const SizedBox(width: AppSpacing.sm),
                for (final category in categories) ...[
                  _FilterPill(
                    label: category,
                    isSelected: filter.category == category,
                    onTap: () => ref
                        .read(taskFilterProvider.notifier)
                        .toggleCategory(category),
                    icon: Icons.label_outline_rounded,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                ],
              ],
              if (filter.hasActiveFilter)
                _FilterPill(
                  label: 'Reset',
                  isSelected: false,
                  onTap: () {
                    _searchController.clear();
                    ref.read(taskFilterProvider.notifier).reset();
                  },
                  icon: Icons.clear_all_rounded,
                  iconColor: AppColors.error,
                ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Row(
            children: [
              Icon(
                Icons.sort_rounded,
                size: 16,
                color: AppColors.textMuted,
              ),
              const SizedBox(width: AppSpacing.xs),
              for (final sort in TaskSortBy.values) ...[
                _SortPill(
                  label: sort.label,
                  isSelected: filter.sortBy == sort,
                  isAsc: filter.sortOrder == 'asc',
                  onTap: () =>
                      ref.read(taskFilterProvider.notifier).setSort(sort),
                ),
                const SizedBox(width: AppSpacing.sm),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _FilterPill extends StatelessWidget {
  const _FilterPill({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.icon,
    this.iconColor,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final IconData? icon;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppDurations.microAnimation,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.2)
              : AppSurfaces.card,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(
            color: isSelected
                ? AppColors.primary.withValues(alpha: 0.5)
                : AppSurfaces.cardBorder,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 14,
                color: iconColor ??
                    (isSelected ? AppColors.primaryLight : AppColors.textMuted),
              ),
              const SizedBox(width: AppSpacing.xs),
            ],
            Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: isSelected
                        ? AppColors.primaryLight
                        : AppColors.textMuted,
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.w400,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Divider kecil di antara group filter pills.
class _PillDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 20,
      color: AppSurfaces.cardBorder,
    );
  }
}

class _SortPill extends StatelessWidget {
  const _SortPill({
    required this.label,
    required this.isSelected,
    required this.isAsc,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final bool isAsc;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppDurations.microAnimation,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm + 2,
          vertical: AppSpacing.xs + 2,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(
            color: isSelected
                ? AppColors.primary.withValues(alpha: 0.4)
                : AppSurfaces.cardBorder,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: isSelected
                        ? AppColors.primaryLight
                        : AppColors.textMuted,
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.w400,
                  ),
            ),
            if (isSelected) ...[
              const SizedBox(width: 2),
              Icon(
                isAsc
                    ? Icons.arrow_upward_rounded
                    : Icons.arrow_downward_rounded,
                size: 12,
                color: AppColors.primaryLight,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
