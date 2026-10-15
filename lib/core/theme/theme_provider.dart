import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// ThemeMode aplikasi, default dark. Pilihan user disimpan di
/// SharedPreferences.
final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(
  ThemeModeNotifier.new,
);

class ThemeModeNotifier extends Notifier<ThemeMode> {
  static const _prefKey = 'taskflow_theme_mode';

  @override
  ThemeMode build() {
    _restore();
    return ThemeMode.dark;
  }

  Future<void> _restore() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_prefKey);
    if (saved != null) {
      state = ThemeMode.values.firstWhere(
        (m) => m.name == saved,
        orElse: () => ThemeMode.dark,
      );
    }
  }

  Future<void> set(ThemeMode mode) async {
    state = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, mode.name);
  }
}
