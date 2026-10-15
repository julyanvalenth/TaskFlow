import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:taskflow_mobile/features/settings/providers/settings_providers.dart';
import 'package:taskflow_mobile/features/tasks/data/models/task.dart';
import 'package:taskflow_mobile/features/tasks/providers/task_providers.dart';
import 'package:taskflow_mobile/features/tasks/ui/task_form_page.dart';

/// KnownCategories yang sudah terisi, termasuk tag @daily, untuk memastikan
/// tag itu tidak pernah muncul sebagai chip.
class _SeededKnownCategories extends KnownCategoriesNotifier {
  @override
  List<String> build() => [kDailyModeTag, 'kuliah', 'kerja'];
}

void main() {
  Future<Widget> formHost({String? savedMode}) async {
    SharedPreferences.setMockInitialValues({'lumo_task_mode': ?savedMode});
    final prefs = await SharedPreferences.getInstance();
    return ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        knownCategoriesProvider.overrideWith(_SeededKnownCategories.new),
      ],
      child: MaterialApp(
        theme: ThemeData(brightness: Brightness.dark),
        home: const TaskFormPage(),
      ),
    );
  }

  testWidgets('tag @daily tidak muncul sebagai chip kategori',
      (tester) async {
    await tester.pumpWidget(await formHost());
    expect(find.text(kDailyModeTag), findsNothing);
    expect(find.text('kuliah'), findsOneWidget);
    expect(find.text('kerja'), findsOneWidget);
  });

  testWidgets('mode College: badge College, kuota 0/5', (tester) async {
    await tester.pumpWidget(await formHost(savedMode: 'college'));
    expect(find.text('College'), findsOneWidget);
    expect(find.text('0/5'), findsOneWidget);
  });

  testWidgets('mode Daily: badge Daily, kuota berkurang jadi 0/4',
      (tester) async {
    await tester.pumpWidget(await formHost(savedMode: 'daily'));
    expect(find.text('Daily'), findsOneWidget);
    expect(find.text('0/4'), findsOneWidget);
  });
}
