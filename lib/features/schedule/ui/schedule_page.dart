import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/app_error_view.dart';
import '../../tasks/data/models/task.dart';
import '../../tasks/ui/widgets/task_detail_sheet.dart';
import '../providers/schedule_providers.dart';

final _monthFormat = DateFormat('MMMM yyyy');
final _dayTitleFormat = DateFormat('EEEE, MMMM d');
final _timeFormat = DateFormat('h:mm a');

/// Posisi satu blok pada grid timeline. Fraksi horizontal (0..1) dihitung
/// terhadap area blok (setelah kolom label jam) supaya bisa di-unit-test
/// tanpa tahu lebar layar.
class TimelineBlockSpec {
  const TimelineBlockSpec({
    required this.task,
    required this.top,
    required this.height,
    required this.leftFraction,
    required this.widthFraction,
  });

  final Task task;
  final double top;
  final double height;
  final double leftFraction;
  final double widthFraction;
}

/// Susun blok per slot jam. Task di jam yang sama (atau yang ter-clamp ke
/// slot tepi grid) dibagi berdampingan, dan tiap blok di-snap ke baris jamnya
/// supaya tidak melewati baris lain.
List<TimelineBlockSpec> computeTimelineBlocks(
  List<Task> dayTasks, {
  int startHour = 7,
  int hourCount = 14,
  double hourHeight = 60,
}) {
  final bySlot = <int, List<Task>>{};
  for (final task in dayTasks) {
    final due = task.dueDate;
    if (due == null) continue;
    final slot = due.hour.clamp(startHour, startHour + hourCount - 1);
    (bySlot[slot] ??= []).add(task);
  }

  final specs = <TimelineBlockSpec>[];
  for (final entry in bySlot.entries) {
    final tasks = entry.value
      ..sort((a, b) => a.dueDate!.compareTo(b.dueDate!));
    final n = tasks.length;
    for (var i = 0; i < n; i++) {
      specs.add(TimelineBlockSpec(
        task: tasks[i],
        top: (entry.key - startHour) * hourHeight,
        height: hourHeight - 6,
        leftFraction: i / n,
        widthFraction: 1 / n,
      ));
    }
  }
  return specs;
}

/// Halaman Schedule: header, strip pemilih hari, dan timeline per jam
/// (07.00 sampai 21.00) berisi blok task, plus garis "now" untuk hari ini.
class SchedulePage extends ConsumerStatefulWidget {
  const SchedulePage({super.key});

  @override
  ConsumerState<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends ConsumerState<SchedulePage> {
  static const _dayItemExtent = 54.0; // lebar item 46 + gap 8

  /// Grid jam: mulai 07.00, 14 baris x 60 px.
  static const int _startHour = 7;
  static const int _hourCount = 14;
  static const double _hourHeight = 60;

  /// Rentang hari pada strip: 2 minggu ke belakang s.d. 2 minggu ke depan.
  late final List<DateTime> _days;
  late final ScrollController _stripController;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    _days = List.generate(
      29,
      (i) => today.add(Duration(days: i - 14)),
    );
    // Posisikan "hari ini" (index 14) kira-kira di tengah layar.
    _stripController = ScrollController(
      initialScrollOffset: 14 * _dayItemExtent - 150,
    );
  }

  @override
  void dispose() {
    _stripController.dispose();
    super.dispose();
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  /// Posisi vertikal (px) untuk jam desimal, di-clamp ke rentang grid.
  double _topFor(double hour) {
    final clamped =
        hour.clamp(_startHour.toDouble(), (_startHour + _hourCount - 1).toDouble());
    return (clamped - _startHour) * _hourHeight;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selectedDay = ref.watch(selectedScheduleDayProvider);
    final tasksAsync = ref.watch(scheduleTasksProvider);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

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
        onRetry: () => ref.invalidate(scheduleTasksProvider),
      ),
      data: (tasks) {
        final dayTasks = tasks
            .where((t) => _sameDay(t.dueDate!, selectedDay))
            .toList()
          ..sort((a, b) => a.dueDate!.compareTo(b.dueDate!));

        final hourNow = now.hour + now.minute / 60;
        final showNow = _sameDay(selectedDay, today) &&
            hourNow >= _startHour &&
            hourNow <= _startHour + _hourCount;

        return RefreshIndicator(
          color: AppColors.primary,
          backgroundColor: AppSurfaces.card,
          onRefresh: () => ref.refresh(scheduleTasksProvider.future),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(0, 14, 0, 130),
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Schedule',
                            style: theme.textTheme.titleLarge?.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w700,
                              fontSize: 22,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            _dayTitleFormat.format(selectedDay),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppColors.textMuted,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!_sameDay(selectedDay, today)) ...[
                      GestureDetector(
                        onTap: () => ref
                            .read(selectedScheduleDayProvider.notifier)
                            .select(today),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color:
                                AppColors.primary.withValues(alpha: 0.15),
                            borderRadius:
                                BorderRadius.circular(AppRadius.pill),
                            border: Border.all(
                              color:
                                  AppColors.primary.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Text(
                            'Today',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: AppColors.primaryLight,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppSurfaces.glass,
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                        border: Border.all(color: AppSurfaces.cardBorder),
                      ),
                      child: Text(
                        _monthFormat.format(selectedDay),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: AppColors.textMuted,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              SizedBox(
                height: 72,
                child: ListView.separated(
                  controller: _stripController,
                  scrollDirection: Axis.horizontal,
                  padding:
                      const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  itemCount: _days.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(width: AppSpacing.sm),
                  itemBuilder: (context, index) {
                    final day = _days[index];
                    return _DayChip(
                      day: day,
                      isSelected: _sameDay(day, selectedDay),
                      isToday: _sameDay(day, today),
                      onTap: () => ref
                          .read(selectedScheduleDayProvider.notifier)
                          .select(day),
                    );
                  },
                ),
              ),
              const SizedBox(height: 14),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: SizedBox(
                  height: _hourCount * _hourHeight + 20,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      // Area blok = lebar penuh minus kolom label jam.
                      final blockArea = constraints.maxWidth - 64;
                      return Stack(
                        children: [
                      for (int i = 0; i < _hourCount; i++)
                        Positioned(
                          top: i * _hourHeight,
                          left: 0,
                          right: 0,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                width: 46,
                                child: Text(
                                  DateFormat('h a')
                                      .format(DateTime(
                                          2026, 1, 1, _startHour + i))
                                      .toUpperCase(),
                                  textAlign: TextAlign.right,
                                  style: theme.textTheme.labelSmall
                                      ?.copyWith(
                                    color: AppColors.textSubtle,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Padding(
                                  padding:
                                      const EdgeInsets.only(top: 7),
                                  child: Container(
                                    height: 1,
                                    color: const Color(0x12C1E8FF),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                      if (dayTasks.isEmpty)
                        Positioned(
                          top: 2 * _hourHeight,
                          left: 64,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            decoration: BoxDecoration(
                              color: AppSurfaces.glass,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                  color: AppSurfaces.cardBorder),
                            ),
                            child: Text(
                              'Tidak ada jadwal di hari ini.\n'
                              'Tekan + untuk menambah task.',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: AppColors.textMuted,
                                height: 1.5,
                              ),
                            ),
                          ),
                        ),

                      for (final spec in computeTimelineBlocks(
                        dayTasks,
                        startHour: _startHour,
                        hourCount: _hourCount,
                        hourHeight: _hourHeight,
                      ))
                        Positioned(
                          top: spec.top + 9,
                          left: 64 + spec.leftFraction * blockArea,
                          width: spec.widthFraction * blockArea -
                              (spec.widthFraction < 1 ? 4 : 0),
                          height: spec.height,
                          child: _TimelineBlock(
                            task: spec.task,
                            onTap: () => showTaskDetailSheet(
                                context, spec.task),
                          ),
                        ),

                      if (showNow)
                        Positioned(
                          top: _topFor(hourNow) + 7,
                          left: 0,
                          right: 0,
                          child: IgnorePointer(
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    borderRadius: BorderRadius.circular(
                                        AppRadius.pill),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.primary
                                            .withValues(alpha: 0.4),
                                        blurRadius: 12,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Text(
                                    _timeFormat.format(now),
                                    style: theme.textTheme.labelSmall
                                        ?.copyWith(
                                      color: const Color(0xFF021024),
                                      fontWeight: FontWeight.w700,
                                      fontSize: 10,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Container(
                                    height: 2,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          AppColors.primary,
                                          AppColors.primary
                                              .withValues(alpha: 0.15),
                                        ],
                                      ),
                                      borderRadius:
                                          BorderRadius.circular(1),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Chip hari di strip. Pill gradient saat terpilih, titik kecil untuk hari ini.
class _DayChip extends StatelessWidget {
  const _DayChip({
    required this.day,
    required this.isSelected,
    required this.isToday,
    required this.onTap,
  });

  final DateTime day;
  final bool isSelected;
  final bool isToday;
  final VoidCallback onTap;

  static final _weekdayFormat = DateFormat('EEE');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppDurations.microAnimation,
        width: 46,
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          gradient: isSelected ? AppGradients.primarySubtle : null,
          color: isSelected ? null : AppSurfaces.glass,
          borderRadius: BorderRadius.circular(18),
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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _weekdayFormat.format(day).toUpperCase(),
              style: theme.textTheme.labelSmall?.copyWith(
                color: isSelected
                    ? const Color(0x99021024)
                    : AppColors.textSubtle,
                fontWeight: FontWeight.w700,
                fontSize: 9,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              '${day.day}',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 16,
                color: isSelected
                    ? const Color(0xFF021024)
                    : AppColors.textMuted,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Container(
              width: 4,
              height: 4,
              decoration: BoxDecoration(
                color: isToday && !isSelected
                    ? AppColors.primary
                    : Colors.transparent,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Blok task di grid jam, dengan aksen kiri warna kategori.
class _TimelineBlock extends StatelessWidget {
  const _TimelineBlock({required this.task, required this.onTap});

  final Task task;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorDef = AppCategoryColors.forName(
      task.visibleCategories.isEmpty ? null : task.visibleCategories.first,
    );

    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: task.isDone ? 0.55 : 1,
        child: Container(
          // Border harus uniform bila memakai borderRadius (aturan
          // Flutter); aksen kiri warna kategori dirender via Stack.
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: const Alignment(0.2, -0.5),
              end: const Alignment(1.0, 1.0),
              colors: [colorDef.soft, const Color(0xEB052042)],
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppSurfaces.cardBorder),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF021024).withValues(alpha: 0.45),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Stack(
              children: [
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  width: 3,
                  child: ColoredBox(color: colorDef.color),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 12.5,
                          decoration: task.isDone
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${_timeFormat.format(task.dueDate!)}'
                        '${task.categoryLabel != null ? ' · ${task.categoryLabel}' : ''}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: AppColors.textMuted,
                          fontSize: 10.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
