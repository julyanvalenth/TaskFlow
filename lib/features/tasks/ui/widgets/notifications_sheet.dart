import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_tokens.dart';
import '../../../dashboard/providers/dashboard_providers.dart';
import '../../data/models/task.dart';
import 'task_detail_sheet.dart';

final _dueFormat = DateFormat('EEE, d MMM • HH:mm');

/// Sheet notifikasi (dibuka dari bell di Home): task lewat tenggat dan
/// mendekati deadline 7 hari, dari data [dashboardProvider].
class NotificationsSheet extends ConsumerWidget {
  const NotificationsSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final stats = ref.watch(dashboardProvider).value;
    final overdue = stats?.overdue ?? const <Task>[];
    final upcoming = stats?.upcoming ?? const <Task>[];

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      decoration: const BoxDecoration(
        color: AppSurfaces.sheet,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        border: Border.fromBorderSide(
          BorderSide(color: AppSurfaces.cardBorderHover),
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(22, 14, 22, 44),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textSubtle.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Text(
                  'Notifications',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 19,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: const BoxDecoration(
                      color: AppSurfaces.glass,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close_rounded,
                      size: 14,
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (overdue.isEmpty && upcoming.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppSurfaces.glass,
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                  border: Border.all(color: AppSurfaces.cardBorder),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.verified_rounded,
                      size: 20,
                      color: AppColors.success,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        'Belum ada notifikasi. Semua aman.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppColors.textMuted,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            if (overdue.isNotEmpty) ...[
              _SectionLabel('LEWAT TENGGAT', color: AppColors.error),
              for (final task in overdue)
                _NotifRow(task: task, isOverdue: true),
            ],
            if (upcoming.isNotEmpty) ...[
              _SectionLabel('MENDEKATI DEADLINE'),
              for (final task in upcoming)
                _NotifRow(task: task, isOverdue: false),
            ],
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text, {this.color = AppColors.textMuted});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 14, bottom: 8),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 11,
              letterSpacing: 0.6,
            ),
      ),
    );
  }
}

class _NotifRow extends ConsumerWidget {
  const _NotifRow({required this.task, required this.isOverdue});

  final Task task;
  final bool isOverdue;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final color = isOverdue ? AppColors.error : AppColors.textMuted;

    return GestureDetector(
      onTap: () {
        Navigator.of(context).pop();
        showTaskDetailSheet(context, task);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Icon(
                isOverdue
                    ? Icons.warning_amber_rounded
                    : Icons.schedule_rounded,
                size: 16,
                color: color,
              ),
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
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    task.dueDate != null
                        ? _dueFormat.format(task.dueDate!)
                        : '',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: color,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              size: 16,
              color: AppColors.textSubtle,
            ),
          ],
        ),
      ),
    );
  }
}

void showNotificationsSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: AppSurfaces.scrim,
    builder: (_) => const NotificationsSheet(),
  );
}
