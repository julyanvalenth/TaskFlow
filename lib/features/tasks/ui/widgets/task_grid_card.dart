import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/lumo_checkbox.dart';
import '../../data/models/task.dart';

final _timeFormat = DateFormat('h:mm a');
final _dayFormat = DateFormat('d MMM');

/// Label waktu: hari ini cukup jam; selain itu tanggal + jam.
String _whenLabel(DateTime due) {
  final now = DateTime.now();
  final sameDay =
      due.year == now.year && due.month == now.month && due.day == now.day;
  return sameDay
      ? _timeFormat.format(due)
      : '${_dayFormat.format(due)} · ${_timeFormat.format(due)}';
}

/// Kartu task untuk tampilan grid 2 kolom.
class TaskGridCard extends StatelessWidget {
  const TaskGridCard({
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
    final progress = task.subtaskProgress ?? (task.isDone ? 1.0 : 0.0);
    final pct = (progress * 100).toInt();

    return GestureDetector(
      onTap: onTap,
      child: AnimatedOpacity(
        duration: AppDurations.microAnimation,
        opacity: task.isDone ? 0.55 : 1.0,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: const Alignment(0.2, -0.5),
              end: const Alignment(1.0, 1.0),
              colors: [colorDef.tint, const Color(0xEB041832)],
            ),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppSurfaces.cardBorderHover),
            boxShadow: [
              BoxShadow(
                color: colorDef.glow,
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Row(
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
                            task.categoryLabel?.toUpperCase() ?? 'TASK',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: AppColors.textMuted,
                              fontWeight: FontWeight.w700,
                              fontSize: 10,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  LumoCheckbox(
                    value: task.isDone,
                    onChanged: onToggleDone != null
                        ? (v) => onToggleDone!(v)
                        : null,
                  ),
                ],
              ),
              const SizedBox(height: 10),

              Expanded(
                child: Text(
                  task.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 13.5,
                    height: 1.35,
                    decoration:
                        task.isDone ? TextDecoration.lineThrough : null,
                  ),
                ),
              ),
              const SizedBox(height: 10),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      'Progress',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w700,
                        fontSize: 10,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '$pct%',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w700,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Container(
                height: 4,
                decoration: BoxDecoration(
                  color: AppSurfaces.cardBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: progress,
                  child: Container(
                    decoration: BoxDecoration(
                      color: colorDef.color,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // Keduanya flexible agar tidak overflow di tile sempit
              // (layar 320dp / font scaling besar).
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: AppSurfaces.glass,
                        borderRadius:
                            BorderRadius.circular(AppRadius.pill),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.access_time_rounded,
                              size: 10, color: AppColors.textMuted),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              task.dueDate != null
                                  ? _whenLabel(task.dueDate!)
                                  : 'No time',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: AppColors.textMuted,
                                fontWeight: FontWeight.w600,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: priStyle.bg,
                        borderRadius:
                            BorderRadius.circular(AppRadius.pill),
                      ),
                      child: Text(
                        task.priority.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: priStyle.fg,
                          fontWeight: FontWeight.w700,
                          fontSize: 9.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
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
