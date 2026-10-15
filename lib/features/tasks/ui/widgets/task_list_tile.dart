import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/lumo_checkbox.dart';
import '../../data/models/task.dart';

final _timeFormat = DateFormat('h:mm a');
final _dayFormat = DateFormat('EEE, d MMM');

/// Label waktu: hari ini cukup jam; selain itu tanggal + jam.
String _whenLabel(DateTime due) {
  final now = DateTime.now();
  final sameDay =
      due.year == now.year && due.month == now.month && due.day == now.day;
  return sameDay
      ? _timeFormat.format(due)
      : '${_dayFormat.format(due)} · ${_timeFormat.format(due)}';
}

/// Baris task untuk tampilan list.
class TaskListTile extends StatelessWidget {
  const TaskListTile({
    super.key,
    required this.task,
    required this.colorIndex,
    this.onTap,
    this.onToggleDone,
  });

  final Task task;
  final int colorIndex;
  final VoidCallback? onTap;
  final ValueChanged<bool>? onToggleDone;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorDef = AppCategoryColors.forIndex(colorIndex);
    final priStyle = _priorityStyle(task.priority);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedOpacity(
        duration: AppDurations.microAnimation,
        opacity: task.isDone ? 0.55 : 1.0,
        child: Container(
          // Border harus uniform bila memakai borderRadius (aturan Flutter);
          // aksen kiri warna kategori dirender via Stack di dalam ClipRRect.
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                AppSurfaces.glass,
                Color(0x08C1E8FF),
              ],
            ),
            borderRadius: BorderRadius.all(Radius.circular(18)),
          ),
          foregroundDecoration: const BoxDecoration(
            borderRadius: BorderRadius.all(Radius.circular(18)),
            border: Border.fromBorderSide(
              BorderSide(color: AppSurfaces.cardBorder),
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Stack(
              children: [
                // Aksen kiri warna kategori (pengganti border-left 3px).
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  width: 3,
                  child: ColoredBox(color: colorDef.color),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 13,
                  ),
                  child: Row(
            children: [
              LumoCheckbox(
                value: task.isDone,
                size: 24,
                borderRadius: 9,
                onChanged: onToggleDone != null
                    ? (v) => onToggleDone!(v)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
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
                        fontSize: 14,
                        decoration:
                            task.isDone ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: colorDef.color,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            task.categoryLabel ?? 'Task',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: AppColors.textMuted,
                              fontWeight: FontWeight.w600,
                              fontSize: 11,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            task.dueDate != null
                                ? _whenLabel(task.dueDate!)
                                : '',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: AppColors.textSubtle,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: priStyle.bg,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text(
                  task.priority.label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: priStyle.fg,
                    fontWeight: FontWeight.w700,
                    fontSize: 10,
                  ),
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

  PriorityStyle _priorityStyle(TaskPriority p) => switch (p) {
        TaskPriority.urgent => AppPriorityStyles.urgent,
        TaskPriority.high => AppPriorityStyles.high,
        TaskPriority.medium => AppPriorityStyles.medium,
        TaskPriority.low => AppPriorityStyles.low,
      };
}
