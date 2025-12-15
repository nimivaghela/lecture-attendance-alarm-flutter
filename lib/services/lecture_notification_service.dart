// lib/services/lecture_notification_service.dart
import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../lecture_settings.dart';

typedef NotificationTapCallback = void Function(String? payload);

class LectureNotificationService {
  LectureNotificationService._internal();

  static final LectureNotificationService instance =
      LectureNotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  NotificationTapCallback? _onTap;

  /// Init plugin + timezone. Accepts optional [onTap] callback.
  Future<void> init({NotificationTapCallback? onTap}) async {
    if (_initialized) return;
    _initialized = true;
    _onTap = onTap;

    // --- Timezone: India / Ahmedabad (IST, Asia/Kolkata) ---
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Kolkata'));

    // Use your custom launcher / app icon here
    const AndroidInitializationSettings androidInit =
        AndroidInitializationSettings('@drawable/attendance');

    const InitializationSettings initSettings = InitializationSettings(
      android: androidInit,
    );

    await _plugin.initialize(
      initSettings,
      // This runs when user taps notification or an action button
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        // If user pressed our STOP action button
        if (response.actionId == 'STOP_ALARM') {
          // Cancel just this notification (which stops sound)
          if (response.id != null) {
            await _plugin.cancel(response.id!);
          } else {
            await _plugin.cancelAll();
          }
          return; // don't navigate anywhere
        }

        // Normal tap on notification: cancel it (stop sound) and navigate
        if (response.id != null) {
          await _plugin.cancel(response.id!);
        }
        _onTap?.call(response.payload);
      },
    );

    if (Platform.isAndroid) {
      final androidImpl =
          _plugin
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >();
      await androidImpl?.requestNotificationsPermission();
    }
  }

  /// Called from LectureHomeScreen._saveAndSchedule()
  Future<void> scheduleFromSettings(LectureSettings s) async {
    await init();
    await cancelAll();

    for (int i = 0; i < s.lectures.length; i++) {
      final lec = s.lectures[i];
      if (!lec.enabled) continue; // skip disabled

      await _scheduleDailyLecture(
        id: i + 1,
        // unique id
        lectureKey: 'L${i + 1}',
        title: lec.name,
        hour: lec.hour,
        minute: lec.minute,
        // you can optionally use lec.days to schedule only on certain weekdays
      );
    }
  }

  Future<void> _scheduleDailyLecture({
    required int id,
    required String lectureKey, // "L1", "L2", ...
    required String title,
    required int hour,
    required int minute,
  }) async {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);

    // Candidate time for today at chosen hour:minute (seconds = 0)
    tz.TZDateTime scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
      0,
    );

    // ---- MINUTE-BASED LOGIC ----
    final bool sameDay =
        scheduled.year == now.year &&
        scheduled.month == now.month &&
        scheduled.day == now.day;

    final bool sameMinute =
        sameDay && scheduled.hour == now.hour && scheduled.minute == now.minute;

    if (sameMinute) {
      // If user scheduled for the current minute, fire a few seconds from now,
      // not tomorrow.
      scheduled = now.add(const Duration(seconds: 5));
    } else if (scheduled.isBefore(now)) {
      // Time already passed earlier today (different minute) → schedule tomorrow.
      scheduled = scheduled.add(const Duration(days: 1));
    }

    final payloadJson = jsonEncode(<String, dynamic>{
      'lectureId': lectureKey,
      'subject': title,
    });

    // --- Notification with STOP button ---
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'lecture_alarm_channel',
          'Lecture Alarms',
          channelDescription: 'Full-screen lecture alarm notifications',
          importance: Importance.max,
          priority: Priority.high,
          category: AndroidNotificationCategory.alarm,
          fullScreenIntent: true,
          playSound: true,
          sound: RawResourceAndroidNotificationSound('lecture_alert'),
          enableVibration: true,

          // Let user dismiss by tapping (and via STOP button)
          ongoing: false,
          autoCancel: true,

          // Extra action button to stop alarm only
          actions: <AndroidNotificationAction>[
            AndroidNotificationAction(
              'STOP_ALARM', // actionId we check in callback
              'Stop alarm', // button label
              showsUserInterface: false, // don't open app, just run callback
              cancelNotification: true, // cancel this notif -> sound stops
            ),
          ],
        );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
    );

    try {
      await _plugin.zonedSchedule(
        id,
        'Lecture Reminder',
        'It is time for $title',
        scheduled,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: payloadJson,
      );
    } on PlatformException catch (e) {
      if (e.code == 'exact_alarms_not_permitted') {
        await _plugin.zonedSchedule(
          id,
          'Lecture Reminder',
          'It is time for $title',
          scheduled,
          notificationDetails,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.time,
          payload: payloadJson,
        );
      } else {
        rethrow;
      }
    }
  }

  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }

  Future<void> testNow() async {
    await init();

    final payloadJson = jsonEncode(<String, dynamic>{
      'lectureId': 'TEST',
      'subject': 'Test Lecture',
    });

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'lecture_alarm_channel',
          'Lecture Alarms',
          channelDescription: 'Full-screen lecture alarm notifications',
          importance: Importance.max,
          priority: Priority.high,
          category: AndroidNotificationCategory.alarm,
          fullScreenIntent: true,
          playSound: true,
          sound: RawResourceAndroidNotificationSound('lecture_alert'),
          enableVibration: true,
          ongoing: false,
          autoCancel: true,
          actions: <AndroidNotificationAction>[
            AndroidNotificationAction(
              'STOP_ALARM',
              'Stop alarm',
              showsUserInterface: false,
              cancelNotification: true,
            ),
          ],
        );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
    );

    await _plugin.show(
      999,
      'Test Lecture Alarm',
      'This is a test lecture alarm.',
      notificationDetails,
      payload: payloadJson,
    );
  }
}
