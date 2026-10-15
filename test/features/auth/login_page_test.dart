import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taskflow_mobile/core/storage/token_storage.dart';
import 'package:taskflow_mobile/core/widgets/gradient_button.dart';
import 'package:taskflow_mobile/features/auth/ui/login_page.dart';

Widget buildLoginApp() => ProviderScope(
      overrides: [
        tokenStorageProvider.overrideWithValue(InMemoryTokenStorage()),
      ],
      child: const MaterialApp(home: LoginPage()),
    );

void main() {
  testWidgets('form kosong menampilkan pesan validasi wajib diisi',
      (tester) async {
    await tester.pumpWidget(buildLoginApp());

    await tester.tap(find.widgetWithText(GradientButton, 'Masuk'));
    await tester.pump();

    expect(find.text('Email wajib diisi'), findsOneWidget);
    expect(find.text('Password wajib diisi'), findsOneWidget);
  });

  testWidgets('email tidak valid dan password pendek ditolak',
      (tester) async {
    await tester.pumpWidget(buildLoginApp());

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Email'),
      'bukan-email',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Password'),
      'pendek',
    );
    await tester.tap(find.widgetWithText(GradientButton, 'Masuk'));
    await tester.pump();

    expect(find.text('Format email tidak valid'), findsOneWidget);
    expect(find.text('Password minimal 8 karakter'), findsOneWidget);
  });

  testWidgets('input valid tidak menampilkan pesan validasi', (tester) async {
    await tester.pumpWidget(buildLoginApp());

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Email'),
      'user@taskflow.dev',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Password'),
      'password123',
    );
    // Validasi manual tanpa submit (submit akan memanggil jaringan).
    final formState = tester.state<FormState>(find.byType(Form));
    expect(formState.validate(), isTrue);
  });
}
