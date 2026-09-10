import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// Schedules a single repeating local notification reminding the user to log
/// their spending. Entirely optional and off by default.
class ReminderService {
  ReminderService._();

  static final ReminderService instance = ReminderService._();

  static const _storage = FlutterSecureStorage();
  static const _enabledKey = 'reminder_enabled';
  static const _hourKey = 'reminder_hour';
  static const _minuteKey = 'reminder_minute';
  static const _notificationId = 1001;

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _ready = false;

  Future<void> init() async {
    if (_ready) return;
    _ready = true;

    tz_data.initializeTimeZones();
    _setLocalTimeZoneFromDeviceOffset();

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    await _plugin.initialize(
      settings: const InitializationSettings(android: android, iOS: ios),
    );

    if (await isEnabled()) {
      await _schedule(await getTime());
    }
  }

  /// The `timezone` package needs a named IANA location, but we have no
  /// timezone-lookup plugin installed — approximating with a fixed UTC-offset
  /// `Etc/GMT` zone is off by an hour around DST transitions, which is an
  /// acceptable trade for a best-effort personal reminder rather than adding
  /// another native plugin dependency just for this.
  void _setLocalTimeZoneFromDeviceOffset() {
    final offsetHours = DateTime.now().timeZoneOffset.inHours;
    final sign = offsetHours <= 0 ? '+' : '-';
    final name = 'Etc/GMT$sign${offsetHours.abs()}';
    try {
      tz.setLocalLocation(tz.getLocation(name));
    } catch (_) {
      tz.setLocalLocation(tz.UTC);
    }
  }

  Future<bool> isEnabled() async =>
      (await _storage.read(key: _enabledKey)) == 'true';

  Future<TimeOfDay> getTime() async {
    final hour = int.tryParse(await _storage.read(key: _hourKey) ?? '') ?? 20;
    final minute = int.tryParse(await _storage.read(key: _minuteKey) ?? '') ?? 0;
    return TimeOfDay(hour: hour, minute: minute);
  }

  Future<void> setReminder(TimeOfDay time) async {
    await _storage.write(key: _enabledKey, value: 'true');
    await _storage.write(key: _hourKey, value: time.hour.toString());
    await _storage.write(key: _minuteKey, value: time.minute.toString());
    if (Platform.isAndroid) {
      await _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.requestNotificationsPermission();
    }
    await _schedule(time);
  }

  Future<void> cancel() async {
    await _storage.write(key: _enabledKey, value: 'false');
    await _plugin.cancel(id: _notificationId);
  }

  Future<void> _schedule(TimeOfDay time) async {
    await _plugin.cancel(id: _notificationId);
    await _plugin.zonedSchedule(
      id: _notificationId,
      title: "Log today's spending",
      body: 'A quick tap keeps your Kinscope numbers accurate.',
      scheduledDate: _nextInstance(time),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_reminder',
          'Daily reminder',
          channelDescription: "Reminds you to log today's transactions",
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  tz.TZDateTime _nextInstance(TimeOfDay time) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }
}
