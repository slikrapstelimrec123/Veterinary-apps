import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../../features/notifications/domain/app_notification.dart';

class LocalNotificationService {
  LocalNotificationService._();

  static final instance = LocalNotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  static const _details = NotificationDetails(
    android: AndroidNotificationDetails(
      'lappo_updates',
      'Lappo updates',
      channelDescription: 'Reminders and important account updates',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
    ),
    iOS: DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: 'default',
    ),
  );

  Future<void> initialize() async {
    if (_initialized) return;

    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
    );
    await _plugin.initialize(settings);
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Europe/Kyiv'));
    _initialized = true;
  }

  Future<bool> requestPermission() async {
    await initialize();

    final iosGranted = await _plugin
            .resolvePlatformSpecificImplementation<
                IOSFlutterLocalNotificationsPlugin>()
            ?.requestPermissions(alert: true, badge: true, sound: true) ??
        true;
    final androidGranted = await _plugin
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>()
            ?.requestNotificationsPermission() ??
        true;
    return iosGranted && androidGranted;
  }

  Future<void> show(AppNotification notification) async {
    await initialize();
    await _plugin.show(
      _stableId('notification:${notification.id}'),
      notification.title,
      notification.body,
      _details,
      payload: notification.id,
    );
  }

  Future<void> scheduleMedicationReminder({
    required String medicationId,
    required String medicationName,
    required String petName,
    required DateTime dueDate,
  }) async {
    await _scheduleReminder(
      key: 'medication:$medicationId',
      title: 'Час прийняти препарат',
      body: '$petName: $medicationName',
      dueDate: dueDate,
      payload: 'medication:$medicationId',
    );
  }

  Future<void> cancelMedicationReminder(String medicationId) async {
    await initialize();
    await _plugin.cancel(_stableId('medication:$medicationId'));
  }

  Future<void> scheduleVisitReminder({
    required String visitRecordId,
    required String petName,
    required DateTime dueDate,
  }) async {
    await _scheduleReminder(
      key: 'visit:$visitRecordId',
      title: 'Запланований повторний прийом',
      body: 'Не забудьте про повторний прийом для $petName.',
      dueDate: dueDate,
      payload: 'visit:$visitRecordId',
    );
  }

  Future<void> _scheduleReminder({
    required String key,
    required String title,
    required String body,
    required DateTime dueDate,
    required String payload,
  }) async {
    await initialize();
    final id = _stableId(key);
    await _plugin.cancel(id);

    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      dueDate.year,
      dueDate.month,
      dueDate.day,
      9,
    );
    final dueDay = DateTime(dueDate.year, dueDate.month, dueDate.day);
    final today = DateTime(now.year, now.month, now.day);
    if (dueDay.isBefore(today)) return;
    if (!scheduled.isAfter(now)) {
      scheduled = now.add(const Duration(seconds: 5));
    }

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      scheduled,
      _details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: payload,
    );
  }

  int _stableId(String value) {
    var hash = 0x811c9dc5;
    for (final codeUnit in value.codeUnits) {
      hash ^= codeUnit;
      hash = (hash * 0x01000193) & 0x7fffffff;
    }
    return hash;
  }
}
