import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/animated_progress_bar.dart';
import '../../../core/widgets/app_error_view.dart';
import '../../../core/widgets/gradient_button.dart';
import '../data/models/task.dart';
import '../providers/home_providers.dart';
import '../providers/task_providers.dart';

const _maxCategories = 5;
const _maxSubtasks = 20;

/// Form buat/edit task: judul, deskripsi, due date, prioritas, status,
/// kategori (multi-select), dan subtask.
class TaskFormPage extends ConsumerWidget {
  const TaskFormPage({super.key, this.taskId});

  final String? taskId;

  bool get isEdit => taskId != null;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!isEdit) return const _TaskForm(initial: null);

    final taskAsync = ref.watch(taskDetailProvider(taskId!));
    return taskAsync.when(
      loading: () => Scaffold(
        backgroundColor: AppSurfaces.background,
        appBar: AppBar(title: const Text('Edit Task')),
        body: Center(
          child: CircularProgressIndicator(
            color: AppColors.primary.withValues(alpha: 0.6),
            strokeWidth: 2.5,
          ),
        ),
      ),
      error: (error, _) => Scaffold(
        backgroundColor: AppSurfaces.background,
        appBar: AppBar(title: const Text('Edit Task')),
        body: AppErrorView(
          error: error,
          onRetry: () => ref.invalidate(taskDetailProvider(taskId!)),
        ),
      ),
      data: (task) => _TaskForm(initial: task),
    );
  }
}

/// Satu baris editor subtask: controller teks + flag selesai.
class _SubtaskEntry {
  _SubtaskEntry({String title = '', this.done = false})
      : controller = TextEditingController(text: title);

  final TextEditingController controller;
  bool done;

  void dispose() => controller.dispose();
}

class _TaskForm extends ConsumerStatefulWidget {
  const _TaskForm({required this.initial});

  final Task? initial;

  @override
  ConsumerState<_TaskForm> createState() => _TaskFormState();
}

class _TaskFormState extends ConsumerState<_TaskForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  final _newCategoryController = TextEditingController();
  DateTime? _dueDate;
  late TaskPriority _priority;
  late TaskStatus _status;
  late final List<String> _selectedCategories;
  late final List<_SubtaskEntry> _subtasks;
  late final bool _isDailyMode;
  bool _submitting = false;
  String? _formError;
  ApiException? _serverValidation;

  bool get isEdit => widget.initial != null;

  /// Batas kategori yang bisa dipilih. Server membatasi 5 (ArrayMaxSize)
  /// termasuk tag mode, jadi di mode Daily satu slot dipakai tag.
  int get _effectiveMaxCategories =>
      _isDailyMode ? _maxCategories - 1 : _maxCategories;

  @override
  void initState() {
    super.initState();
    final t = widget.initial;
    _titleController = TextEditingController(text: t?.title ?? '');
    _descriptionController =
        TextEditingController(text: t?.description ?? '');
    _dueDate = t?.dueDate;
    _priority = t?.priority ?? TaskPriority.medium;
    _status = t?.status ?? TaskStatus.todo;
    // Tag mode @daily tidak pernah tampil sebagai kategori pilihan;
    // mode dipertahankan terpisah dan ditambahkan lagi saat submit.
    _selectedCategories = [...?t?.visibleCategories];
    _isDailyMode = t?.isDailyMode ??
        (ref.read(taskModeProvider) == TaskMode.daily);
    _subtasks = [
      for (final s in t?.subtasks ?? const <Subtask>[])
        _SubtaskEntry(title: s.title, done: s.done),
    ];
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _newCategoryController.dispose();
    for (final s in _subtasks) {
      s.dispose();
    }
    super.dispose();
  }

  Future<void> _pickDueDate() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? now,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now.add(const Duration(days: 365 * 5)),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: _dueDate != null
          ? TimeOfDay.fromDateTime(_dueDate!)
          : const TimeOfDay(hour: 9, minute: 0),
    );
    setState(() {
      _dueDate = DateTime(
        date.year,
        date.month,
        date.day,
        time?.hour ?? 9,
        time?.minute ?? 0,
      );
    });
  }

  String? _serverErrorFor(String field) => _serverValidation?.errorFor(field);

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  void _toggleCategory(String category) {
    setState(() {
      if (_selectedCategories.contains(category)) {
        _selectedCategories.remove(category);
      } else if (_selectedCategories.length >= _effectiveMaxCategories) {
        _showMessage('Maksimal $_effectiveMaxCategories kategori per task');
      } else {
        _selectedCategories.add(category);
      }
    });
  }

  void _addNewCategory() {
    final category = _newCategoryController.text.trim().toLowerCase();
    if (category.isEmpty) return;
    if (category.startsWith('@')) {
      // Awalan '@' dicadangkan untuk tag internal (mis. @daily).
      _showMessage('Nama kategori tidak boleh diawali "@"');
      return;
    }
    if (category.length > 50) {
      _showMessage('Kategori maksimal 50 karakter');
      return;
    }
    if (_selectedCategories.length >= _effectiveMaxCategories &&
        !_selectedCategories.contains(category)) {
      _showMessage('Maksimal $_effectiveMaxCategories kategori per task');
      return;
    }
    setState(() {
      if (!_selectedCategories.contains(category)) {
        _selectedCategories.add(category);
      }
      _newCategoryController.clear();
    });
    // Agar langsung muncul sebagai chip pilihan.
    ref.read(knownCategoriesProvider.notifier).addAll([category]);
  }

  void _addSubtask() {
    if (_subtasks.length >= _maxSubtasks) {
      _showMessage('Maksimal $_maxSubtasks subtask per task');
      return;
    }
    setState(() => _subtasks.add(_SubtaskEntry()));
  }

  /// Lebarkan range chip Home (Today/Week/Month/All) bila perlu, supaya
  /// task yang baru dibuat langsung terlihat alih-alih tersaring filter
  /// yang lebih sempit dari tenggatnya.
  void _ensureRangeCoversDueDate() {
    final due = _dueDate;
    if (due == null) return;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dueDay = DateTime(due.year, due.month, due.day);
    final diff = dueDay.difference(today).inDays;
    final needed = diff <= 0
        ? TaskRange.today
        : diff <= 6
            ? TaskRange.week
            : diff <= 29
                ? TaskRange.month
                : TaskRange.all;

    final current = ref.read(taskRangeProvider);
    if (needed.index > current.index) {
      ref.read(taskRangeProvider.notifier).set(needed);
    }
  }

  Future<void> _submit() async {
    setState(() {
      _formError = null;
      _serverValidation = null;
    });
    if (!_formKey.currentState!.validate()) return;

    setState(() => _submitting = true);
    final input = TaskInput(
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      dueDate: _dueDate,
      priority: _priority,
      // Tag mode dipertahankan/ditambahkan lagi di sini (tidak tampil di UI).
      categories: [
        ..._selectedCategories,
        if (_isDailyMode) kDailyModeTag,
      ],
      // Baris kosong dibuang saja, tidak dianggap error.
      subtasks: [
        for (final s in _subtasks)
          if (s.controller.text.trim().isNotEmpty)
            Subtask(title: s.controller.text.trim(), done: s.done),
      ],
      status: _status,
    );

    try {
      final mutations = ref.read(taskMutationsProvider);
      if (isEdit) {
        await mutations.update(widget.initial!.id, input.toJson());
      } else {
        await mutations.create(input);
        _ensureRangeCoversDueDate();
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isEdit ? 'Task diperbarui' : 'Task dibuat'),
          ),
        );
        context.go('/home');
      }
    } on ApiException catch (e) {
      setState(() {
        if (e.type == ApiErrorType.validation && e.details.isNotEmpty) {
          _serverValidation = e;
          // Pesan yang tidak terpetakan ke field tetap tampil di banner.
          final unmapped = e.details
              .where((d) =>
                  d != e.errorFor('title') &&
                  d != e.errorFor('description') &&
                  d != e.errorFor('dueDate') &&
                  d != e.errorFor('categories') &&
                  d != e.errorFor('subtasks'))
              .toList();
          _formError = unmapped.isEmpty ? null : unmapped.join('\n');
        } else {
          _formError = e.displayMessage;
        }
      });
      // Trigger validator agar errorText server tampil di field.
      _formKey.currentState!.validate();
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Hapus task?'),
            content: const Text('Task akan dihapus permanen.'),
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

    setState(() => _submitting = true);
    try {
      await ref.read(taskMutationsProvider).delete(widget.initial!.id);
      if (mounted) context.go('/home');
    } on ApiException catch (e) {
      setState(() => _formError = e.displayMessage);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dueFormat = DateFormat('EEEE, d MMM yyyy • HH:mm');
    final knownCategories = ref.watch(knownCategoriesProvider);
    // Kategori yang pernah ada ditambah yang sedang dipilih. Tag @daily
    // tidak pernah ditawarkan sebagai chip.
    final categoryOptions = {
      ...knownCategories.where((c) => c != kDailyModeTag),
      ..._selectedCategories,
    }.toList()
      ..sort();

    return Scaffold(
      backgroundColor: AppSurfaces.background,
      appBar: AppBar(
        backgroundColor: AppSurfaces.background,
        title: Text(isEdit ? 'Edit Task' : 'Task Baru'),
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppSurfaces.card,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: AppSurfaces.cardBorder),
            ),
            child: const Icon(Icons.arrow_back_rounded, size: 20),
          ),
          onPressed: () => context.go('/home'),
        ),
        actions: [
          if (isEdit)
            IconButton(
              tooltip: 'Hapus',
              icon: Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(
                    color: AppColors.error.withValues(alpha: 0.3),
                  ),
                ),
                child: Icon(
                  Icons.delete_outline_rounded,
                  size: 18,
                  color: AppColors.error,
                ),
              ),
              onPressed: _submitting ? null : _delete,
            ),
          const SizedBox(width: AppSpacing.sm),
        ],
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              if (_formError != null) ...[
                InlineErrorBanner(message: _formError!),
                const SizedBox(height: AppSpacing.md),
              ],

              TextFormField(
                controller: _titleController,
                textInputAction: TextInputAction.next,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: 'Judul *'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Judul wajib diisi';
                  }
                  return _serverErrorFor('title');
                },
              ),
              const SizedBox(height: AppSpacing.md),

              TextFormField(
                controller: _descriptionController,
                minLines: 3,
                maxLines: 6,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Deskripsi',
                  alignLabelWithHint: true,
                ),
                validator: (_) => _serverErrorFor('description'),
              ),
              const SizedBox(height: AppSpacing.lg),

              _SectionLabel(label: 'Tenggat'),
              const SizedBox(height: AppSpacing.sm),
              GestureDetector(
                onTap: _pickDueDate,
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppSurfaces.card,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(color: AppSurfaces.cardBorder),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.event_rounded,
                        size: 20,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          _dueDate != null
                              ? dueFormat.format(_dueDate!)
                              : 'Pilih tanggal & jam',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: _dueDate != null
                                ? Colors.white
                                : AppColors.textMuted,
                          ),
                        ),
                      ),
                      if (_dueDate != null)
                        GestureDetector(
                          onTap: () => setState(() => _dueDate = null),
                          child: Icon(
                            Icons.close_rounded,
                            size: 18,
                            color: AppColors.textMuted,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              if (_serverErrorFor('dueDate') != null) ...[
                const SizedBox(height: AppSpacing.xs),
                Padding(
                  padding: const EdgeInsets.only(left: AppSpacing.md),
                  child: Text(
                    _serverErrorFor('dueDate')!,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: AppColors.error),
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.lg),

              _SectionLabel(label: 'Prioritas'),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  for (final p in TaskPriority.values)
                    _SelectChip(
                      label: p.label,
                      icon: Icons.flag_rounded,
                      accentColor: p.color(theme.brightness),
                      isSelected: _priority == p,
                      onTap: () => setState(() => _priority = p),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),

              _SectionLabel(label: 'Status'),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  for (final s in TaskStatus.values)
                    _SelectChip(
                      label: s.label,
                      icon: switch (s) {
                        TaskStatus.todo =>
                          Icons.radio_button_unchecked_rounded,
                        TaskStatus.inProgress => Icons.timelapse_rounded,
                        TaskStatus.done => Icons.check_circle_rounded,
                      },
                      accentColor: AppColors.primaryLight,
                      isSelected: _status == s,
                      onTap: () => setState(() => _status = s),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),

              Row(
                children: [
                  _SectionLabel(label: 'Kategori'),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    '${_selectedCategories.length}/$_effectiveMaxCategories',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: AppColors.textSubtle,
                    ),
                  ),
                  const Spacer(),
                  // Penanda workspace task ini (dari mode switch Home).
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppSurfaces.glass,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      border: Border.all(color: AppSurfaces.cardBorder),
                    ),
                    child: Text(
                      _isDailyMode ? 'Daily' : 'College',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: _isDailyMode
                            ? AppColors.warm
                            : AppColors.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              if (categoryOptions.isNotEmpty) ...[
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    for (final category in categoryOptions)
                      _SelectChip(
                        label: category,
                        icon: _selectedCategories.contains(category)
                            ? Icons.check_rounded
                            : Icons.tag_rounded,
                        accentColor: AppColors.primaryLight,
                        isSelected: _selectedCategories.contains(category),
                        onTap: () => _toggleCategory(category),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
              ],
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: AppSurfaces.card,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: AppSurfaces.cardBorder),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _newCategoryController,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _addNewCategory(),
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          hintText: 'Kategori baru, mis. kuliah',
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          filled: false,
                          isDense: true,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: _addNewCategory,
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          gradient: AppGradients.primary,
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                        ),
                        child: const Icon(
                          Icons.add_rounded,
                          size: 18,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (_serverErrorFor('categories') != null) ...[
                const SizedBox(height: AppSpacing.xs),
                Padding(
                  padding: const EdgeInsets.only(left: AppSpacing.md),
                  child: Text(
                    _serverErrorFor('categories')!,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: AppColors.error),
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.lg),

              Row(
                children: [
                  _SectionLabel(label: 'Subtask'),
                  const SizedBox(width: AppSpacing.sm),
                  if (_subtasks.isNotEmpty)
                    Text(
                      '${_subtasks.where((s) => s.done).length}'
                      '/${_subtasks.length} selesai',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: AppColors.textSubtle,
                      ),
                    ),
                ],
              ),
              // Progress live mengikuti toggle subtask di bawah.
              if (_subtasks.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.sm),
                AnimatedProgressBar(
                  value: _subtasks.where((s) => s.done).length /
                      _subtasks.length,
                  height: 5,
                  gradient: _subtasks.every((s) => s.done)
                      ? AppGradients.success
                      : AppGradients.primary,
                  backgroundColor: AppSurfaces.elevated,
                ),
              ],
              const SizedBox(height: AppSpacing.sm),
              for (int i = 0; i < _subtasks.length; i++) ...[
                _SubtaskRow(
                  entry: _subtasks[i],
                  onToggle: () => setState(
                    () => _subtasks[i].done = !_subtasks[i].done,
                  ),
                  onRemove: () => setState(
                    () => _subtasks.removeAt(i).dispose(),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
              ],
              GestureDetector(
                onTap: _addSubtask,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: AppSpacing.sm + 2),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.add_rounded,
                        size: 18,
                        color: AppColors.primaryLight,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        'Tambah subtask',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: AppColors.primaryLight,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (_serverErrorFor('subtasks') != null) ...[
                const SizedBox(height: AppSpacing.xs),
                Padding(
                  padding: const EdgeInsets.only(left: AppSpacing.md),
                  child: Text(
                    _serverErrorFor('subtasks')!,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: AppColors.error),
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.xl),

              GradientButton(
                onPressed: _submitting ? null : _submit,
                isLoading: _submitting,
                child: Text(isEdit ? 'Simpan Perubahan' : 'Buat Task'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Chip pilihan untuk prioritas, status, dan kategori.
class _SelectChip extends StatelessWidget {
  const _SelectChip({
    required this.label,
    required this.icon,
    required this.accentColor,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color accentColor;
  final bool isSelected;
  final VoidCallback onTap;

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
              ? accentColor.withValues(alpha: 0.15)
              : AppSurfaces.card,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(
            color: isSelected
                ? accentColor.withValues(alpha: 0.5)
                : AppSurfaces.cardBorder,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected ? accentColor : AppColors.textSubtle,
            ),
            const SizedBox(width: AppSpacing.xs + 2),
            Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: isSelected ? Colors.white : AppColors.textMuted,
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

/// Baris editor subtask: toggle selesai, teks, dan hapus.
class _SubtaskRow extends StatelessWidget {
  const _SubtaskRow({
    required this.entry,
    required this.onToggle,
    required this.onRemove,
  });

  final _SubtaskEntry entry;
  final VoidCallback onToggle;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppSurfaces.card,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppSurfaces.cardBorder),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: onToggle,
            child: AnimatedContainer(
              duration: AppDurations.microAnimation,
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                gradient: entry.done ? AppGradients.success : null,
                shape: BoxShape.circle,
                border: entry.done
                    ? null
                    : Border.all(color: AppColors.textSubtle, width: 1.5),
              ),
              child: entry.done
                  ? const Icon(
                      Icons.check_rounded,
                      size: 14,
                      color: Colors.white,
                    )
                  : null,
            ),
          ),
          const SizedBox(width: AppSpacing.sm + 2),

          Expanded(
            child: TextField(
              controller: entry.controller,
              style: TextStyle(
                color: entry.done ? AppColors.textSubtle : Colors.white,
                decoration:
                    entry.done ? TextDecoration.lineThrough : null,
              ),
              decoration: const InputDecoration(
                hintText: 'Tulis subtask..',
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
                isDense: true,
              ),
            ),
          ),

          GestureDetector(
            onTap: onRemove,
            child: const Padding(
              padding: EdgeInsets.all(AppSpacing.xs),
              child: Icon(
                Icons.close_rounded,
                size: 18,
                color: AppColors.textSubtle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
    );
  }
}
