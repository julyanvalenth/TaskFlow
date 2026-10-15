import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Abstraksi reminder di sisi app. Implementasi sungguhan (misalnya lewat
/// flutter_local_notifications atau FCM) tinggal dipasang di
/// [notificationServiceProvider] tanpa mengubah kode fitur.
abstract class NotificationService {
  Future<void> init();

  Future<void> scheduleTaskReminder({
    required String taskId,
    required String title,
    required DateTime dueDate,
  });

  Future<void> cancelTaskReminder(String taskId);
}

/// Implementasi kosong, dipakai selama app belum punya reminder.
class NoopNotificationService implements NotificationService {
  @override
  Future<void> init() async {}

  @override
  Future<void> scheduleTaskReminder({
    required String taskId,
    required String title,
    required DateTime dueDate,
  }) async {}

  @override
  Future<void> cancelTaskReminder(String taskId) async {}
}

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NoopNotificationService();
});
