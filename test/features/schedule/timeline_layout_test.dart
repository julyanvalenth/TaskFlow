import 'package:flutter_test/flutter_test.dart';
import 'package:taskflow_mobile/features/schedule/ui/schedule_page.dart';
import 'package:taskflow_mobile/features/tasks/data/models/task.dart';

Task makeTask(String id, DateTime due) => Task(
      id: id,
      userId: 'u-1',
      title: 'Task $id',
      status: TaskStatus.todo,
      priority: TaskPriority.medium,
      dueDate: due,
      createdAt: DateTime(2026, 7, 1),
      updatedAt: DateTime(2026, 7, 1),
    );

void main() {
  group('computeTimelineBlocks', () {
    test('task tunggal: lebar penuh pada baris jamnya', () {
      final specs = computeTimelineBlocks([
        makeTask('a', DateTime(2026, 7, 17, 13, 0)),
      ]);

      expect(specs, hasLength(1));
      expect(specs.first.top, (13 - 7) * 60);
      expect(specs.first.leftFraction, 0);
      expect(specs.first.widthFraction, 1);
      expect(specs.first.height, 54);
    });

    test('dua task sejam dibagi berdampingan (tidak menumpuk)', () {
      final specs = computeTimelineBlocks([
        makeTask('b', DateTime(2026, 7, 17, 9, 30)),
        makeTask('a', DateTime(2026, 7, 17, 9, 0)),
      ]);

      expect(specs, hasLength(2));
      // Urut jam: a (9:00) di kiri, b (9:30) di kanan.
      expect(specs[0].task.id, 'a');
      expect(specs[0].leftFraction, 0);
      expect(specs[0].widthFraction, 0.5);
      expect(specs[1].task.id, 'b');
      expect(specs[1].leftFraction, 0.5);
      expect(specs[1].widthFraction, 0.5);
      // Slot sama, baris sama.
      expect(specs[0].top, specs[1].top);
    });

    test('tiga task sejam: masing-masing sepertiga lebar', () {
      final specs = computeTimelineBlocks([
        makeTask('a', DateTime(2026, 7, 17, 14, 0)),
        makeTask('b', DateTime(2026, 7, 17, 14, 15)),
        makeTask('c', DateTime(2026, 7, 17, 14, 45)),
      ]);

      expect(specs.map((s) => s.widthFraction), everyElement(closeTo(1 / 3, 0.001)));
      expect(specs.map((s) => s.leftFraction).toList()..sort(),
          [0, closeTo(1 / 3, 0.001), closeTo(2 / 3, 0.001)]);
    });

    test('jam di luar grid di-clamp ke slot tepi dan ikut berbagi lebar',
        () {
      final specs = computeTimelineBlocks([
        makeTask('late', DateTime(2026, 7, 17, 23, 0)), // > 20 → slot 20
        makeTask('edge', DateTime(2026, 7, 17, 20, 0)),
        makeTask('early', DateTime(2026, 7, 17, 5, 0)), // < 7 → slot 7
      ]);

      final late = specs.firstWhere((s) => s.task.id == 'late');
      final edge = specs.firstWhere((s) => s.task.id == 'edge');
      final early = specs.firstWhere((s) => s.task.id == 'early');

      expect(early.top, 0); // slot 7 = baris pertama
      expect(late.top, (20 - 7) * 60);
      expect(edge.top, late.top);
      // Slot 20 berisi 2 task, jadi lebarnya dibagi.
      expect(late.widthFraction, 0.5);
      expect(edge.widthFraction, 0.5);
      expect(late.leftFraction, isNot(edge.leftFraction));
    });

    test('task tanpa dueDate diabaikan; hari kosong aman', () {
      expect(computeTimelineBlocks([]), isEmpty);
    });
  });
}
