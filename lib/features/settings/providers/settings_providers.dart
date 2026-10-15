import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// [SharedPreferences] dimuat di `main()` sebelum `runApp` lalu di-override
/// lewat `ProviderScope.overrides`, supaya setting bisa dibaca sinkron oleh
/// redirect router.
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError(
    'sharedPreferencesProvider harus di-override di main()',
  ),
);

/// Setting yang disimpan: daily goal, notifikasi, dan flag onboarding.
class AppSettings {
  const AppSettings({
    required this.dailyGoal,
    required this.notificationsEnabled,
    required this.onboardingSeen,
  });

  final int dailyGoal;
  final bool notificationsEnabled;
  final bool onboardingSeen;

  AppSettings copyWith({
    int? dailyGoal,
    bool? notificationsEnabled,
    bool? onboardingSeen,
  }) =>
      AppSettings(
        dailyGoal: dailyGoal ?? this.dailyGoal,
        notificationsEnabled:
            notificationsEnabled ?? this.notificationsEnabled,
        onboardingSeen: onboardingSeen ?? this.onboardingSeen,
      );
}

final settingsProvider =
    NotifierProvider<SettingsNotifier, AppSettings>(SettingsNotifier.new);

class SettingsNotifier extends Notifier<AppSettings> {
  static const _kGoal = 'lumo_daily_goal';
  static const _kNotif = 'lumo_notifications';
  static const _kOnboard = 'lumo_onboarding_seen';

  SharedPreferences get _prefs => ref.read(sharedPreferencesProvider);

  @override
  AppSettings build() => AppSettings(
        dailyGoal: _prefs.getInt(_kGoal) ?? 5,
        notificationsEnabled: _prefs.getBool(_kNotif) ?? true,
        onboardingSeen: _prefs.getBool(_kOnboard) ?? false,
      );

  Future<void> setDailyGoal(int goal) async {
    state = state.copyWith(dailyGoal: goal.clamp(1, 10));
    await _prefs.setInt(_kGoal, state.dailyGoal);
  }

  Future<void> setNotifications(bool enabled) async {
    state = state.copyWith(notificationsEnabled: enabled);
    await _prefs.setBool(_kNotif, enabled);
  }

  Future<void> markOnboardingSeen() async {
    state = state.copyWith(onboardingSeen: true);
    await _prefs.setBool(_kOnboard, true);
  }
}
