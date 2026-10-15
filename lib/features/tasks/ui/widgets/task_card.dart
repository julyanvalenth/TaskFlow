import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/animated_progress_bar.dart';
import '../../../../core/widgets/pressable.dart';
import '../../data/models/task.dart';

final _dueFormat = DateFormat('d MMM yyyy, HH:mm');

/// Kartu task di section "All Task".
class TaskCard extends StatelessWidget {
  const TaskCard({
    super.key,
    required this.task,
    this.onTap,
    this.onToggleDone,
  });

  final Task task;
  final VoidCallback? onTap;
  final ValueChanged<bool>? onToggleDone;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final priorityColor = task.priority.color(theme.brightness);

    return Pressable(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppSurfaces.card,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppSurfaces.cardBorder),
          boxShadow: AppShadows.cardGlow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (task.categoryLabel != null) ...[
                  Text(
                    task.categoryLabel!,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.3,
                    ),
                  ),
                ] else ...[
                  Text(
                    task.priority.label,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: priorityColor,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
                const Spacer(),
                GestureDetector(
                  onTap: onTap,
                  child: Icon(
                    Icons.more_vert_rounded,
                    size: 18,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),

            Text(
              task.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: task.isDone ? AppColors.textSubtle : Colors.white,
                decoration:
                    task.isDone ? TextDecoration.lineThrough : null,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),

            if (task.subtasks.isNotEmpty) ...[
              Row(
                children: [
                  Expanded(
                    child: AnimatedProgressBar(
                      value: task.subtaskProgress!,
                      height: 4,
                      gradient: task.subtasksDone == task.subtasks.length
                          ? AppGradients.success
                          : AppGradients.primary,
                      backgroundColor: AppSurfaces.elevated,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    '${task.subtasksDone}/${task.subtasks.length}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: task.subtasksDone == task.subtasks.length
                          ? AppColors.success
                          : AppColors.textMuted,
                      fontWeight: FontWeight.w600,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
            ],

            Row(
              children: [
                _MetaChip(
                  icon: switch (task.status) {
                    TaskStatus.todo =>
                      Icons.radio_button_unchecked_rounded,
                    TaskStatus.inProgress => Icons.timelapse_rounded,
                    TaskStatus.done => Icons.check_circle_rounded,
                  },
                  label: task.status.label,
                ),
                const SizedBox(width: AppSpacing.sm),

                if (task.dueDate != null) ...[
                  _MetaChip(
                    icon: Icons.schedule_rounded,
                    label: _formatRelativeDate(task.dueDate!),
                    color: task.isOverdue ? AppColors.error : null,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                ],

                const Spacer(),

                Row(
                  children: [
                    SizedBox(
                      width: 52,
                      height: 20,
                      child: Stack(
                        children: [
                          for (int i = 0; i < 3; i++)
                            Positioned(
                              left: i * 13.0,
                              child: Container(
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      [
                                        AppColors.warning,
                                        AppColors.error
                                      ],
                                      [
                                        AppColors.primary,
                                        AppColors.secondary
                                      ],
                                      [
                                        AppColors.tertiary,
                                        AppColors.success
                                      ],
                                    ][i],
                                  ),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: AppSurfaces.card,
                                    width: 1.5,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    _CompactCheckbox(
                      value: task.isDone,
                      onChanged: onToggleDone == null
                          ? null
                          : (v) => onToggleDone!(v ?? false),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatRelativeDate(DateTime date) {
    final now = DateTime.now();
    final diff = date.difference(now);
    if (diff.isNegative) return 'Overdue';
    if (diff.inHours < 24) return '${diff.inHours}h left';
    if (diff.inDays <= 7) return '${diff.inDays}d left';
    return _dueFormat.format(date);
  }
}

/// Chip metadata kecil (icon + label).
class _MetaChip extends StatelessWidget {
  const _MetaChip({
    required this.icon,
    required this.label,
    this.color,
  });

  final IconData icon;
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.textMuted;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm + 2,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: AppSurfaces.elevated,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: AppSurfaces.cardBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: c),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: c,
                  fontSize: 10,
                ),
          ),
        ],
      ),
    );
  }
}

/// Checkbox kecil dengan gradient.
class _CompactCheckbox extends StatelessWidget {
  const _CompactCheckbox({required this.value, this.onChanged});

  final bool value;
  final ValueChanged<bool?>? onChanged;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onChanged == null ? null : () => onChanged!(!value),
      child: AnimatedContainer(
        duration: AppDurations.microAnimation,
        width: 22,
        height: 22,
        decoration: BoxDecoration(
          gradient: value ? AppGradients.primary : null,
          color: value ? null : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: value
              ? null
              : Border.all(color: AppColors.textSubtle, width: 1.5),
        ),
        child: value
            ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
            : null,
      ),
    );
  }
}
