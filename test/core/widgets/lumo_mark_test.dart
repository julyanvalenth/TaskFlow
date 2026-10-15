import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taskflow_mobile/core/widgets/lumo_mark.dart';

void main() {
  group('LumoMark', () {
    testWidgets('render pada berbagai ukuran tanpa error', (tester) async {
      for (final size in [16.0, 24.0, 46.0, 96.0]) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(body: Center(child: LumoMark(size: size))),
          ),
        );
        expect(tester.takeException(), isNull, reason: 'size=$size');
        expect(tester.getSize(find.byType(LumoMark)), Size.square(size));
      }
    });
  });

  group('LumoMarkTile', () {
    testWidgets('render dengan & tanpa glow tanpa error', (tester) async {
      for (final glow in [true, false]) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              backgroundColor: const Color(0xFF021024),
              body: Center(child: LumoMarkTile(size: 72, glow: glow)),
            ),
          ),
        );
        expect(tester.takeException(), isNull, reason: 'glow=$glow');
      }
    });

    testWidgets('ukuran kecil (44px, dialog About) tidak overflow',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: Center(child: LumoMarkTile(size: 44))),
        ),
      );
      expect(tester.takeException(), isNull);
    });
  });
}
