import 'package:flutter/material.dart';

import '../../../../core/theme/app_tokens.dart';

/// Tag penanda task mode Daily; task tanpa tag ini masuk College. Disimpan
/// sebagai kategori biasa supaya API tidak perlu diubah, tapi tidak pernah
/// ditampilkan sebagai kategori.
const String kDailyModeTag = '@daily';

enum TaskPriority {
  low('LOW', 'Rendah'),
  medium('MEDIUM', 'Sedang'),
  high('HIGH', 'Tinggi'),
  urgent('URGENT', 'Mendesak');

  const TaskPriority(this.wire, this.label);

  /// Nilai yang dikirim/diterima API.
  final String wire;
  final String label;

  static TaskPriority fromWire(String value) =>
      TaskPriority.values.firstWhere(
        (p) => p.wire == value,
        orElse: () => TaskPriority.medium,
      );

  /// Warna prioritas per mode tema. Selalu tampilkan bersama label teks,
  /// jangan warna saja.
  Color color(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    return switch (this) {
      TaskPriority.low =>
        dark ? AppColors.priorityLowDark : AppColors.priorityLowLight,
      TaskPriority.medium =>
        dark ? AppColors.priorityMediumDark : AppColors.priorityMediumLight,
      TaskPriority.high =>
        dark ? AppColors.priorityHighDark : AppColors.priorityHighLight,
      TaskPriority.urgent =>
        dark ? AppColors.priorityUrgentDark : AppColors.priorityUrgentLight,
    };
  }
}

enum TaskStatus {
  todo('TODO', 'To Do'),
  inProgress('IN_PROGRESS', 'Dikerjakan'),
  done('DONE', 'Selesai');

  const TaskStatus(this.wire, this.label);

  final String wire;
  final String label;

  static TaskStatus fromWire(String value) => TaskStatus.values.firstWhere(
        (s) => s.wire == value,
        orElse: () => TaskStatus.todo,
      );
}

/// Checklist di dalam task, disimpan sebagai JSON di server.
class Subtask {
  const Subtask({required this.title, this.done = false});

  factory Subtask.fromJson(Map<String, dynamic> json) => Subtask(
        title: json['title'] as String,
        done: json['done'] as bool? ?? false,
      );

  final String title;
  final bool done;

  Map<String, dynamic> toJson() => {'title': title, 'done': done};

  Subtask copyWith({String? title, bool? done}) =>
      Subtask(title: title ?? this.title, done: done ?? this.done);
}

class Task {
  const Task({
    required this.id,
    required this.userId,
    required this.title,
    required this.priority,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.description,
    this.dueDate,
    this.categories = const [],
    this.subtasks = const [],
  });

  factory Task.fromJson(Map<String, dynamic> json) => Task(
        id: json['id'] as String,
        userId: json['userId'] as String,
        title: json['title'] as String,
        description: json['description'] as String?,
        dueDate: json['dueDate'] != null
            ? DateTime.parse(json['dueDate'] as String).toLocal()
            : null,
        priority: TaskPriority.fromWire(json['priority'] as String),
        // Kompatibel dengan payload lama ber-`category` tunggal.
        categories: (json['categories'] as List?)?.cast<String>() ??
            [
              if ((json['category'] as String?)?.isNotEmpty == true)
                json['category'] as String,
            ],
        subtasks: (json['subtasks'] as List?)
                ?.map((s) => Subtask.fromJson(s as Map<String, dynamic>))
                .toList() ??
            const [],
        status: TaskStatus.fromWire(json['status'] as String),
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
      );

  final String id;
  final String userId;
  final String title;
  final String? description;
  final DateTime? dueDate;
  final TaskPriority priority;
  final List<String> categories;
  final List<Subtask> subtasks;
  final TaskStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isDone => status == TaskStatus.done;

  bool get isOverdue =>
      !isDone && dueDate != null && dueDate!.isBefore(DateTime.now());

  /// True kalau task masuk mode Daily.
  bool get isDailyMode => categories.contains(kDailyModeTag);

  /// Kategori yang boleh ditampilkan ke user (tanpa tag mode internal).
  List<String> get visibleCategories =>
      categories.where((c) => c != kDailyModeTag).toList();

  /// Label gabungan kategori untuk tampilan ("kuliah • kerja").
  String? get categoryLabel =>
      visibleCategories.isEmpty ? null : visibleCategories.join(' • ');

  int get subtasksDone => subtasks.where((s) => s.done).length;

  /// Progress dari subtask (0.0 sampai 1.0), null kalau tidak ada subtask.
  double? get subtaskProgress =>
      subtasks.isEmpty ? null : subtasksDone / subtasks.length;
}

/// Payload create/update task. Field null tidak dikirim (PATCH parsial).
class TaskInput {
  const TaskInput({
    required this.title,
    this.description,
    this.dueDate,
    this.priority,
    this.categories,
    this.subtasks,
    this.status,
  });

  final String title;
  final String? description;
  final DateTime? dueDate;
  final TaskPriority? priority;
  final List<String>? categories;
  final List<Subtask>? subtasks;
  final TaskStatus? status;

  /// dueDate dikirim sebagai ISO-8601 UTC. categories/subtasks dikirim apa
  /// adanya, termasuk list kosong supaya edit bisa mengosongkan nilai; hanya
  /// null yang tidak dikirim.
  Map<String, dynamic> toJson() => {
        'title': title,
        if (description != null && description!.isNotEmpty)
          'description': description,
        if (dueDate != null) 'dueDate': dueDate!.toUtc().toIso8601String(),
        if (priority != null) 'priority': priority!.wire,
        if (categories != null) 'categories': categories,
        if (subtasks != null)
          'subtasks': subtasks!.map((s) => s.toJson()).toList(),
        if (status != null) 'status': status!.wire,
      };
}
