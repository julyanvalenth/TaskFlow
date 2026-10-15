import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/app_error_view.dart';
import '../../../core/widgets/course_card.dart';
import '../../../core/widgets/daily_goal_card.dart';
import '../../../core/widgets/mode_switch.dart';
import '../../auth/providers/auth_providers.dart';
import '../../dashboard/providers/dashboard_providers.dart';
import '../../settings/providers/settings_providers.dart';
import '../data/models/task.dart';
import '../providers/home_providers.dart';
import '../providers/task_providers.dart';
import 'widgets/notifications_sheet.dart';
import 'widgets/task_detail_sheet.dart';
import 'widgets/task_grid_card.dart';
import 'widgets/task_list_tile.dart';

/// Halaman Home: header, mode switch College/Daily, daily goal, search,
/// rail kategori, lalu daftar task dengan toggle card/list dan range chip.
class TaskListPage extends ConsumerStatefulWidget {
  const TaskListPage({super.key});

  @override
  ConsumerState<TaskListPage> createState() => _TaskListPageState();
}

class _TaskListPageState extends ConsumerState<TaskListPage> {
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

  Future<void> _toggleDone(Task task, bool done) async {
    try {
      await ref.read(taskMutationsProvider).setStatus(
            task.id,
            done ? TaskStatus.done : TaskStatus.todo,
          );
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.displayMessage)));
      }
    }
  }

  Future<void> _confirmDelete(Task task) async {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Hapus task?'),
            content: Text('"${task.title}" akan dihapus permanen.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Batal'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Hapus'),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed) return;

    try {
      await ref.read(taskMutationsProvider).delete(task.id);
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.displayMessage)));
      }
    }
  }

  static int _colorIndexOf(Task task) => AppCategoryColors.indexForName(
        task.visibleCategories.isEmpty ? null : task.visibleCategories.first,
      );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tasksAsync = ref.watch(taskListProvider);
    final filter = ref.watch(taskFilterProvider);
    final mode = ref.watch(taskModeProvider);
    final view = ref.watch(taskViewProvider);
    final range = ref.watch(taskRangeProvider);
    final settings = ref.watch(settingsProvider);
    final statsAsync = ref.watch(dashboardProvider);

    final email =
        ref.watch(authControllerProvider.select((s) => s.user?.email));
    final name = email?.split('@').first ?? 'User';
    final capitalizedName = name.isNotEmpty
        ? '${name[0].toUpperCase()}${name.substring(1)}'
        : name;
    final initials = capitalizedName.length >= 2
        ? capitalizedName.substring(0, 2).toUpperCase()
        : capitalizedName.toUpperCase();

    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good morning,'
        : hour < 18
            ? 'Good afternoon,'
            : 'Good evening,';

    final streak = statsAsync.value?.streak ?? 0;
    final hasAlerts = (statsAsync.value?.overdue.isNotEmpty ?? false) ||
        (statsAsync.value?.upcoming.isNotEmpty ?? false);

    return tasksAsync.when(
      skipLoadingOnRefresh: true,
      loading: () => const Center(
        child: CircularProgressIndicator(
          color: AppColors.primary,
          strokeWidth: 2.5,
        ),
      ),
      error: (error, _) => AppErrorView(
        error: error,
        onRetry: () => ref.invalidate(taskListProvider),
      ),
      data: (page) {
        final modeTasks =
            page.data.where((t) => taskMatchesMode(t, mode)).toList();
        final rangeTasks = sortTasksForHome(
          modeTasks.where((t) => taskMatchesRange(t, range)).toList(),
        );
        final categoryStats = computeCategoryStats(modeTasks);
        // Ring goal ikut mode aktif, streak dihitung dari semua task.
        final doneToday = countDoneToday(modeTasks);

        return RefreshIndicator(
          color: AppColors.primary,
          backgroundColor: AppSurfaces.card,
          onRefresh: () {
            ref.invalidate(dashboardProvider);
            return ref.refresh(taskListProvider.future);
          },
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 130),
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: () => context.go('/profile'),
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        gradient: AppGradients.accent,
                        shape: BoxShape.circle,
                        // Ring ganda ala design: blue ring luar dulu,
                        // lalu gap navy di atasnya (urutan paint Flutter:
                        // entri terakhir di atas).
                        boxShadow: [
                          BoxShadow(
                            color:
                                AppColors.primary.withValues(alpha: 0.7),
                            spreadRadius: 3.5,
                          ),
                          const BoxShadow(
                            color: AppSurfaces.background,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          initials,
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: const Color(0xFF021024),
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          greeting,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.textMuted,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          capitalizedName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w700,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _BellButton(
                    showDot: settings.notificationsEnabled && hasAlerts,
                    onTap: () => showNotificationsSheet(context),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              ModeSwitch(
                modes: const [
                  ModeSwitchItem(
                    label: 'College',
                    dotColor: AppColors.primary,
                  ),
                  ModeSwitchItem(
                    label: 'Daily',
                    dotColor: AppColors.warm,
                  ),
                ],
                selectedIndex: mode == TaskMode.college ? 0 : 1,
                onChanged: (i) => ref
                    .read(taskModeProvider.notifier)
                    .set(i == 0 ? TaskMode.college : TaskMode.daily),
              ),
              const SizedBox(height: 16),

              DailyGoalCard(
                done: doneToday,
                goal: settings.dailyGoal,
                streak: streak,
              ),
              const SizedBox(height: 16),

              Container(
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: AppSurfaces.glass,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppSurfaces.cardBorder),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.search_rounded,
                      size: 17,
                      color: AppColors.textSubtle,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onChanged: _onSearchChanged,
                        textInputAction: TextInputAction.search,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Search tasks…',
                          hintStyle: theme.textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSubtle,
                            fontSize: 14,
                          ),
                          filled: false,
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                          isDense: true,
                        ),
                      ),
                    ),
                    if (filter.search.isNotEmpty)
                      GestureDetector(
                        onTap: () {
                          _searchController.clear();
                          ref
                              .read(taskFilterProvider.notifier)
                              .setSearch('');
                        },
                        child: const Icon(
                          Icons.close_rounded,
                          size: 16,
                          color: AppColors.textMuted,
                        ),
                      ),
                  ],
                ),
              ),

              if (categoryStats.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.only(top: 26, bottom: 14),
                  child: Text(
                    mode == TaskMode.daily ? 'Categories' : 'Courses',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 17,
                    ),
                  ),
                ),
                SizedBox(
                  height: 148,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    clipBehavior: Clip.none,
                    itemCount: categoryStats.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 12),
                    itemBuilder: (context, i) {
                      final stat = categoryStats[i];
                      return CourseCard(
                        name: stat.name,
                        tasksLeft: stat.left,
                        progressPercent: stat.pct,
                        colorDef: AppCategoryColors.forName(stat.name),
                      );
                    },
                  ),
                ),
              ],

              Padding(
                padding: const EdgeInsets.only(top: 26, bottom: 12),
                child: Row(
                  children: [
                    Text(
                      'Tasks',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 17,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${rangeTasks.length} '
                      '${rangeTasks.length == 1 ? 'task' : 'tasks'}',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: AppColors.textSubtle,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                    const Spacer(),
                    _ViewToggle(
                      icon: Icons.grid_view_rounded,
                      isActive: view == TaskViewStyle.card,
                      onTap: () => ref
                          .read(taskViewProvider.notifier)
                          .set(TaskViewStyle.card),
                    ),
                    const SizedBox(width: 6),
                    _ViewToggle(
                      icon: Icons.format_list_bulleted_rounded,
                      isActive: view == TaskViewStyle.list,
                      onTap: () => ref
                          .read(taskViewProvider.notifier)
                          .set(TaskViewStyle.list),
                    ),
                  ],
                ),
              ),

              Row(
                children: [
                  for (final r in TaskRange.values) ...[
                    Expanded(
                      child: _RangeChip(
                        label: r.label,
                        isSelected: range == r,
                        onTap: () =>
                            ref.read(taskRangeProvider.notifier).set(r),
                      ),
                    ),
                    if (r != TaskRange.values.last)
                      const SizedBox(width: 8),
                  ],
                ],
              ),
              const SizedBox(height: 14),

              if (rangeTasks.isEmpty)
                _EmptyTasks(hasFilter: filter.hasActiveFilter)
              else if (view == TaskViewStyle.card)
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.8,
                  children: [
                    for (final task in rangeTasks)
                      GestureDetector(
                        onLongPress: () => _confirmDelete(task),
                        child: TaskGridCard(
                          task: task,
                          colorIndex: _colorIndexOf(task),
                          onTap: () => showTaskDetailSheet(context, task),
                          onToggleDone: (v) => _toggleDone(task, v),
                        ),
                      ),
                  ],
                )
              else
                Column(
                  children: [
                    for (final task in rangeTasks)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Dismissible(
                          key: ValueKey(task.id),
                          direction: DismissDirection.endToStart,
                          confirmDismiss: (_) async {
                            await _confirmDelete(task);
                            // List di-refresh oleh invalidate provider.
                            return false;
                          },
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            decoration: BoxDecoration(
                              gradient: AppGradients.danger,
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: const Icon(
                              Icons.delete_outline_rounded,
                              color: Colors.white,
                            ),
                          ),
                          child: TaskListTile(
                            task: task,
                            colorIndex: _colorIndexOf(task),
                            onTap: () =>
                                showTaskDetailSheet(context, task),
                            onToggleDone: (v) => _toggleDone(task, v),
                          ),
                        ),
                      ),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }
}

/// Tombol bell dengan titik notifikasi, membuka sheet notifikasi.
class _BellButton extends StatelessWidget {
  const _BellButton({required this.showDot, required this.onTap});

  final bool showDot;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: AppSurfaces.glass,
        shape: BoxShape.circle,
        border: Border.all(color: AppSurfaces.cardBorder),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          const Icon(
            Icons.notifications_none_rounded,
            size: 18,
            color: AppColors.textSecondary,
          ),
          if (showDot)
            Positioned(
              top: 10,
              right: 11,
              child: Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: AppColors.warm,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.warm.withValues(alpha: 0.8),
                      blurRadius: 8,
                    ),
                  ],
                ),
              ),
            ),
        ],
        ),
      ),
    );
  }
}

/// Tombol kecil pemilih view (grid / list).
class _ViewToggle extends StatelessWidget {
  const _ViewToggle({
    required this.icon,
    required this.isActive,
    required this.onTap,
  });

  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppDurations.microAnimation,
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          gradient: isActive ? AppGradients.primarySubtle : null,
          color: isActive ? null : AppSurfaces.glass,
          borderRadius: BorderRadius.circular(11),
          border: Border.all(
            color: isActive
                ? AppColors.primary.withValues(alpha: 0.9)
                : AppSurfaces.cardBorder,
          ),
        ),
        child: Icon(
          icon,
          size: 14,
          color: isActive ? const Color(0xFF021024) : AppColors.textSubtle,
        ),
      ),
    );
  }
}

/// Chip range (Today / Week / Month / All).
class _RangeChip extends StatelessWidget {
  const _RangeChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppDurations.microAnimation,
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          gradient: isSelected ? AppGradients.primarySubtle : null,
          color: isSelected ? null : AppSurfaces.glass,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(
            color: isSelected
                ? AppColors.primary.withValues(alpha: 0.9)
                : AppSurfaces.cardBorder,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.secondary.withValues(alpha: 0.45),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: isSelected
                      ? const Color(0xFF021024)
                      : AppColors.textMuted,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
          ),
        ),
      ),
    );
  }
}

class _EmptyTasks extends StatelessWidget {
  const _EmptyTasks({required this.hasFilter});

  final bool hasFilter;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              gradient: AppGradients.primary,
              borderRadius: BorderRadius.circular(24),
              boxShadow: AppShadows.accentGlow,
            ),
            child: const Icon(
              Icons.checklist_rounded,
              size: 36,
              color: Color(0xFF021024),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            hasFilter ? 'Tidak ada task yang cocok' : 'Belum ada task',
            style: theme.textTheme.titleMedium?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            hasFilter
                ? 'Coba ubah pencarian atau range.'
                : 'Tekan + untuk membuat task pertama 🚀',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}
