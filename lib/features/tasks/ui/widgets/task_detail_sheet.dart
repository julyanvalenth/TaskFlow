import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/lumo_checkbox.dart';
import '../../data/models/task.dart';
import '../../providers/task_providers.dart';

final _timeFormat = DateFormat('h:mm a');
final _dayFormat = DateFormat('EEE d');

/// Bottom sheet detail task: badge kategori, judul, meta, deskripsi, subtask
/// yang bisa dicentang, dan tombol complete/undo.
class TaskDetailSheet extends ConsumerStatefulWidget {
  const TaskDetailSheet({super.key, required this.task});

  final Task task;

  @override
  ConsumerState<TaskDetailSheet> createState() => _TaskDetailSheetState();
}

class _TaskDetailSheetState extends ConsumerState<TaskDetailSheet> {
  late Task _task;

  @override
  void initState() {
    super.initState();
    _task = widget.task;
  }

  CategoryColorDef get _colorDef => AppCategoryColors.forName(
        _task.visibleCategories.isEmpty
            ? null
            : _task.visibleCategories.first,
      );

  PriorityStyle get _priStyle => switch (_task.priority) {
        TaskPriority.urgent => AppPriorityStyles.urgent,
        TaskPriority.high => AppPriorityStyles.high,
        TaskPriority.medium => AppPriorityStyles.medium,
        TaskPriority.low => AppPriorityStyles.low,
      };

  /// Rekonstruksi task lokal dengan subtasks/status baru (field immutable).
  Task _patched({List<Subtask>? subtasks, TaskStatus? status}) => Task(
        id: _task.id,
        userId: _task.userId,
        title: _task.title,
        priority: _task.priority,
        status: status ?? _task.status,
        createdAt: _task.createdAt,
        updatedAt: _task.updatedAt,
        description: _task.description,
        dueDate: _task.dueDate,
        categories: _task.categories,
        subtasks: subtasks ?? _task.subtasks,
      );

  void _showError(Object e) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(e is ApiException
            ? e.displayMessage
            : 'Gagal menyimpan perubahan'),
      ),
    );
  }

  Future<void> _toggleSubtask(int index) async {
    final newSubs = _task.subtasks.toList();
    final old = newSubs[index];
    newSubs[index] = old.copyWith(done: !old.done);

    // Semua subtask selesai berarti task selesai. Kalau satu subtask dibuka
    // lagi di task yang sudah DONE, task kembali ke TODO.
    final allDone = newSubs.every((s) => s.done);
    final newStatus = allDone && !_task.isDone
        ? TaskStatus.done
        : !allDone && _task.isDone
            ? TaskStatus.todo
            : null;

    try {
      await ref.read(taskMutationsProvider).update(
        _task.id,
        {
          'subtasks': newSubs.map((s) => s.toJson()).toList(),
          if (newStatus != null) 'status': newStatus.wire,
        },
      );
      if (mounted) {
        setState(() {
          _task = _patched(subtasks: newSubs, status: newStatus);
        });
      }
    } catch (e) {
      _showError(e);
    }
  }

  Future<void> _toggleComplete() async {
    final newStatus = _task.isDone ? TaskStatus.todo : TaskStatus.done;
    // Tombol complete ikut mengubah semua subtask.
    final newSubs = [
      for (final s in _task.subtasks)
        s.copyWith(done: newStatus == TaskStatus.done),
    ];
    try {
      await ref.read(taskMutationsProvider).update(
        _task.id,
        {
          'status': newStatus.wire,
          if (newSubs.isNotEmpty)
            'subtasks': newSubs.map((s) => s.toJson()).toList(),
        },
      );
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      _showError(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = _task.subtaskProgress ?? (_task.isDone ? 1.0 : 0.0);
    final pct = (progress * 100).toInt();

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.76,
      ),
      decoration: const BoxDecoration(
        color: AppSurfaces.sheet,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        // Harus uniform, Flutter menolak border non-uniform + borderRadius.
        border: Border.fromBorderSide(
          BorderSide(color: AppSurfaces.cardBorderHover),
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(22, 14, 22, 44),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
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
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _colorDef.soft,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Text(
                    _task.categoryLabel ?? 'Task',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: _colorDef.color,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                    ),
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () {
                    Navigator.of(context).pop();
                    context.go('/tasks/${_task.id}/edit');
                  },
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: const BoxDecoration(
                      color: AppSurfaces.glass,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.edit_outlined,
                      size: 14,
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
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
            const SizedBox(height: 14),

            Text(
              _task.title,
              style: theme.textTheme.titleLarge?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 21,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 12),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (_task.dueDate != null)
                  // Hanya jam mulai. Model tidak punya durasi, jadi jam
                  // selesai tidak ditampilkan.
                  _MetaChip(
                    icon: Icons.access_time_rounded,
                    label: _timeFormat.format(_task.dueDate!),
                  ),
                if (_task.dueDate != null)
                  _MetaChip(
                    label: _dayFormat.format(_task.dueDate!),
                  ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: _priStyle.bg,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Text(
                    '${_task.priority.label} priority',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: _priStyle.fg,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            if (_task.description?.isNotEmpty == true) ...[
              Text(
                _task.description!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF9CBBDA),
                  fontSize: 13,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 22),
            ],

            if (_task.subtasks.isNotEmpty) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Subtasks',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    '$pct%',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Container(
                height: 5,
                decoration: BoxDecoration(
                  color: AppSurfaces.glass,
                  borderRadius: BorderRadius.circular(3),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: progress,
                  child: Container(
                    decoration: BoxDecoration(
                      color: _colorDef.color,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              ...List.generate(_task.subtasks.length, (i) {
                final sub = _task.subtasks[i];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: GestureDetector(
                    onTap: () => _toggleSubtask(i),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0x0AC1E8FF),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: const Color(0x12C1E8FF),
                        ),
                      ),
                      child: Row(
                        children: [
                          LumoCheckbox(
                            value: sub.done,
                            size: 21,
                            borderRadius: 8,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              sub.title,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: sub.done
                                    ? AppColors.textMuted
                                    : AppColors.textPrimary,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                                decoration: sub.done
                                    ? TextDecoration.lineThrough
                                    : null,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ],
            const SizedBox(height: 22),

            GestureDetector(
              onTap: _toggleComplete,
              child: Container(
                height: 54,
                decoration: BoxDecoration(
                  color: _task.isDone
                      ? AppSurfaces.glass
                      : AppColors.primary,
                  borderRadius: BorderRadius.circular(27),
                  border: Border.all(
                    color: AppSurfaces.cardBorderHover,
                  ),
                ),
                child: Center(
                  child: Text(
                    _task.isDone ? 'Completed. Undo?' : 'Mark as complete',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: _task.isDone
                          ? AppColors.primary
                          : const Color(0xFF021024),
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.label, this.icon});
  final String label;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0x0FC1E8FF),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: AppColors.textMuted),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
          ),
        ],
      ),
    );
  }
}

void showTaskDetailSheet(BuildContext context, Task task) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: AppSurfaces.scrim,
    builder: (_) => TaskDetailSheet(task: task),
  );
}
