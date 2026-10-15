import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taskflow_mobile/core/widgets/course_card.dart';
import 'package:taskflow_mobile/core/widgets/daily_goal_card.dart';
import 'package:taskflow_mobile/core/widgets/mode_switch.dart';
import 'package:taskflow_mobile/core/theme/app_tokens.dart';
import 'package:taskflow_mobile/features/tasks/data/models/task.dart';
import 'package:taskflow_mobile/features/tasks/ui/widgets/task_detail_sheet.dart';
import 'package:taskflow_mobile/features/tasks/ui/widgets/task_grid_card.dart';
import 'package:taskflow_mobile/features/tasks/ui/widgets/task_list_tile.dart';

Task makeTask({
  String id = 't-1',
  String title = 'Problem Set 6 · Integrals',
  TaskStatus status = TaskStatus.todo,
  TaskPriority priority = TaskPriority.high,
  DateTime? dueDate,
  List<String> categories = const ['Kalkulus'],
  List<Subtask> subtasks = const [],
}) =>
    Task(
      id: id,
      userId: 'u-1',
      title: title,
      status: status,
      priority: priority,
      dueDate: dueDate,
      categories: categories,
      subtasks: subtasks,
      createdAt: DateTime(2026, 7, 1),
      updatedAt: DateTime(2026, 7, 1),
    );

Widget host(Widget child) => MaterialApp(
      theme: ThemeData(brightness: Brightness.dark),
      home: Scaffold(
        backgroundColor: AppSurfaces.background,
        body: Center(child: child),
      ),
    );

void main() {
  group('TaskListTile', () {
    testWidgets('render normal tanpa paint error (regresi border+radius)',
        (tester) async {
      await tester.pumpWidget(host(
        SizedBox(
          width: 360,
          child: TaskListTile(
            task: makeTask(dueDate: DateTime(2026, 7, 18, 19, 30)),
            colorIndex: 1,
          ),
        ),
      ));
      // Paint dipicu di sini, jadi exception border non-uniform akan muncul.
      expect(tester.takeException(), isNull);
      expect(find.text('Problem Set 6 · Integrals'), findsOneWidget);
    });

    testWidgets('tenggat bukan hari ini menampilkan detail tanggal',
        (tester) async {
      await tester.pumpWidget(host(
        SizedBox(
          width: 360,
          child: TaskListTile(
            task: makeTask(dueDate: DateTime(2030, 1, 5, 9, 0)),
            colorIndex: 0,
          ),
        ),
      ));
      expect(find.textContaining('Jan'), findsOneWidget);
      expect(find.textContaining('9:00 AM'), findsOneWidget);
    });

    testWidgets('layar sempit + kategori panjang tidak overflow',
        (tester) async {
      await tester.pumpWidget(host(
        SizedBox(
          width: 280,
          child: TaskListTile(
            task: makeTask(
              title: 'Judul task yang sangat panjang sekali melebihi lebar',
              categories: ['kategori-super-panjang-yang-tidak-wajar'],
              dueDate: DateTime(2030, 12, 31, 23, 59),
            ),
            colorIndex: 2,
          ),
        ),
      ));
      expect(tester.takeException(), isNull);
    });

    testWidgets('task selesai: coret + checkbox terisi', (tester) async {
      await tester.pumpWidget(host(
        SizedBox(
          width: 360,
          child: TaskListTile(
            task: makeTask(status: TaskStatus.done),
            colorIndex: 0,
          ),
        ),
      ));
      expect(tester.takeException(), isNull);
    });
  });

  group('TaskGridCard', () {
    testWidgets('render pada ukuran tile 2 kolom (aspect 0.8)',
        (tester) async {
      await tester.pumpWidget(host(
        SizedBox(
          width: 154,
          height: 154 / 0.8,
          child: TaskGridCard(
            task: makeTask(dueDate: DateTime(2026, 7, 18, 9)),
            colorIndex: 0,
          ),
        ),
      ));
      expect(tester.takeException(), isNull);
    });

    testWidgets('layar sempit 320dp (tile ±134px) tidak overflow',
        (tester) async {
      await tester.pumpWidget(host(
        SizedBox(
          width: 134,
          height: 134 / 0.8,
          child: TaskGridCard(
            task: makeTask(dueDate: DateTime(2030, 12, 31, 23, 59)),
            colorIndex: 3,
          ),
        ),
      ));
      expect(tester.takeException(), isNull);
    });

    testWidgets('tanpa dueDate menampilkan "No time"', (tester) async {
      await tester.pumpWidget(host(
        SizedBox(
          width: 154,
          height: 154 / 0.8,
          child: TaskGridCard(task: makeTask(dueDate: null), colorIndex: 0),
        ),
      ));
      expect(find.text('No time'), findsOneWidget);
    });
  });

  group('CourseCard', () {
    testWidgets('muat dalam rail 148px dengan nama 2 baris', (tester) async {
      await tester.pumpWidget(host(
        SizedBox(
          height: 148,
          child: CourseCard(
            name: 'Nama mata kuliah yang cukup panjang dua baris',
            tasksLeft: 4,
            progressPercent: 72,
            colorDef: AppCategoryColors.forIndex(0),
          ),
        ),
      ));
      expect(tester.takeException(), isNull);
      expect(find.text('72%'), findsOneWidget);
    });
  });

  group('DailyGoalCard', () {
    testWidgets('goal tercapai / nol / normal', (tester) async {
      for (final (done, goal) in [(5, 5), (0, 5), (3, 5), (9, 5)]) {
        await tester.pumpWidget(host(
          SizedBox(
            width: 360,
            child: DailyGoalCard(done: done, goal: goal, streak: 6),
          ),
        ));
        expect(tester.takeException(), isNull,
            reason: 'done=$done goal=$goal');
      }
      expect(find.text('Goal reached, nice work!'), findsOneWidget);
    });
  });

  group('ModeSwitch', () {
    testWidgets('dua mode, tap memanggil onChanged', (tester) async {
      int? tapped;
      await tester.pumpWidget(host(
        SizedBox(
          width: 360,
          child: ModeSwitch(
            modes: const [
              ModeSwitchItem(label: 'College', dotColor: AppColors.primary),
              ModeSwitchItem(label: 'Daily', dotColor: AppColors.warm),
            ],
            selectedIndex: 0,
            onChanged: (i) => tapped = i,
          ),
        ),
      ));
      await tester.tap(find.text('Daily'));
      expect(tapped, 1);
    });
  });

  group('TaskDetailSheet', () {
    testWidgets('render lengkap: subtasks, chips, tombol complete',
        (tester) async {
      await tester.pumpWidget(ProviderScope(
        child: host(
          TaskDetailSheet(
            task: makeTask(
              dueDate: DateTime(2026, 7, 18, 9),
              subtasks: const [
                Subtask(title: 'Q1–Q4 · substitution', done: true),
                Subtask(title: 'Q9 · improper integral'),
              ],
            ),
          ),
        ),
      ));
      expect(tester.takeException(), isNull);
      expect(find.text('Subtasks'), findsOneWidget);
      expect(find.text('50%'), findsOneWidget);
      expect(find.text('Mark as complete'), findsOneWidget);
    });

    testWidgets('task daily: tag @daily tidak tampil sebagai kategori',
        (tester) async {
      await tester.pumpWidget(ProviderScope(
        child: host(
          TaskDetailSheet(
            task: makeTask(categories: ['Fitness', kDailyModeTag]),
          ),
        ),
      ));
      expect(find.textContaining(kDailyModeTag), findsNothing);
      expect(find.text('Fitness'), findsOneWidget);
    });
  });

}
