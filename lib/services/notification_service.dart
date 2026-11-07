import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../models/alarm_model.dart';

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    tz.initializeTimeZones();
    try {
      final name = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(name));
    } catch (_) {}

    const android = AndroidInitializationSettings('@drawable/ic_notification');
    await _plugin.initialize(const InitializationSettings(android: android));

    final impl = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await impl?.requestNotificationsPermission();
    await impl?.requestExactAlarmsPermission();
  }

  int _notificationId(String id) => int.parse(id) % 2147483647;
    NotificationDetails get _details => const NotificationDetails(
        android: AndroidNotificationDetails(
          'habit_alarm_channel',
          'Habit alarms',
          channelDescription: 'Habit and reminder alarms',
          importance: Importance.max,
          priority: Priority.high,
        ),
      );

  Future<void> schedule(AlarmModel alarm) async {
    final now = tz.TZDateTime.now(tz.local);
    var when = tz.TZDateTime(
        tz.local, now.year, now.month, now.day, alarm.hour, alarm.minute);
    if (when.isBefore(now)) {
      when = when.add(const Duration(days: 1));
    }

    Future<void> go(AndroidScheduleMode mode) => _plugin.zonedSchedule(
          _notificationId(alarm.id),
          alarm.title,
          alarm.title,
          when,
          _details,
          androidScheduleMode: mode,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: DateTimeComponents.time,
        );

    try {
      await go(AndroidScheduleMode.exactAllowWhileIdle);
    } catch (_) {
      await go(AndroidScheduleMode.inexactAllowWhileIdle);
    }
  }

  Future<void> cancel(String alarmId) =>
      _plugin.cancel(_notificationId(alarmId));
}