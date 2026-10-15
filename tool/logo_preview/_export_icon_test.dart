// Skrip dev sekali-pakai: render aset icon/splash dari LumoMark ke PNG.
// Jalankan lagi hanya jika desain mark berubah:
//   flutter test tool/logo_preview/_export_icon_test.dart
//
// Menghasilkan:
// - app_icon.png            full-bleed, opaque (sumber flutter_launcher_icons)
// - app_icon_foreground.png transparan, mark dipadding (adaptive icon Android)
// - splash_logo.png         rounded tile untuk flutter_native_splash; sudah
//                           ada dan tidak digenerate ulang di sini
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taskflow_mobile/core/widgets/lumo_mark.dart';

Future<void> _export(
  WidgetTester tester,
  Widget child,
  String path,
) async {
  final key = GlobalKey();
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(child: RepaintBoundary(key: key, child: child)),
      ),
    ),
  );
  await tester.pumpAndSettle();

  await tester.runAsync(() async {
    final boundary =
        key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 1.0);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    await File(path).writeAsBytes(bytes!.buffer.asUint8List());
  });
}

void main() {
  testWidgets('export app icon assets (1024x1024)', (tester) async {
    tester.view.physicalSize = const Size(1024, 1024);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    // Sumber flutter_launcher_icons: full-bleed dan opaque, tanpa rounded
    // corner atau transparansi. OS yang menerapkan mask sendiri, dan iOS
    // menolak icon dengan alpha channel.
    await _export(
      tester,
      Container(
        width: 1024,
        height: 1024,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF5483B3), Color(0xFFC1E8FF)],
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(-0.4, -0.5),
                  radius: 0.7,
                  colors: [
                    Colors.white.withValues(alpha: 0.35),
                    Colors.white.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
            const LumoMark(size: 520, color: Color(0xFF021024)),
          ],
        ),
      ),
      'assets/icon/app_icon.png',
    );

    // Foreground adaptive icon Android: transparan, mark dipadding ke ~55%.
    // OS memotong viewport dengan berbagai bentuk mask, jadi butuh margin
    // aman di semua sisi.
    await _export(
      tester,
      const SizedBox(
        width: 1024,
        height: 1024,
        child: Center(child: LumoMark(size: 560, color: Color(0xFF021024))),
      ),
      'assets/icon/app_icon_foreground.png',
    );
  });
}
