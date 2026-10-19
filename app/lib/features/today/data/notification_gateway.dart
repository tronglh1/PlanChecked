import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../domain/reminder_planner.dart';

/// The only place that touches `flutter_local_notifications`, so scheduling
/// logic can be tested with a fake.
abstract class NotificationGateway {
  Future<void> init({String timezone});

  /// Shows the OS permission prompt. Returns whether notifications are
  /// allowed afterwards.
  Future<bool> requestPermission();

  Future<bool> isPermissionGranted();

  /// Cancels every pending local notification and schedules [items].
  /// [channels] carries the localized Android channel names.
  Future<void> replaceAll(
    List<PlannedNotification> items, {
    ReminderChannels? channels,
  });

  /// Route payloads of tapped notifications.
  Stream<String> get taps;
}

class LocalNotificationsGateway implements NotificationGateway {
  LocalNotificationsGateway([FlutterLocalNotificationsPlugin? plugin])
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;
  final StreamController<String> _taps = StreamController<String>.broadcast();
  bool _ready = false;
  tz.Location? _location;

  static const _taskChannelId = 'task_reminders';
  static const _checkinChannelId = 'checkin_reminders';

  /// Channel names/descriptions come from the ARB files (see
  /// [ReminderChannels]); the ids are the fallback names if none are given.
  static AndroidNotificationDetails _details(
    String id,
    String name,
    String? description,
  ) => AndroidNotificationDetails(
    id,
    name,
    channelDescription: description,
    importance: Importance.defaultImportance,
    priority: Priority.defaultPriority,
  );

  @override
  Stream<String> get taps => _taps.stream;

  @override
  Future<void> init({String timezone = 'Asia/Ho_Chi_Minh'}) async {
    if (_ready) return;
    tzdata.initializeTimeZones();
    try {
      _location = tz.getLocation(timezone);
    } catch (_) {
      _location = tz.getLocation('Asia/Ho_Chi_Minh');
    }
    tz.setLocalLocation(_location!);
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
      onDidReceiveNotificationResponse: (r) {
        final p = r.payload;
        if (p != null && p.isNotEmpty) _taps.add(p);
      },
    );
    _ready = true;
  }

  @override
  Future<bool> requestPermission() async {
    await init();
    try {
      final android = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      if (android != null) {
        return await android.requestNotificationsPermission() ?? false;
      }
      final ios = _plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >();
      if (ios != null) {
        return await ios.requestPermissions(
              alert: true,
              badge: true,
              sound: true,
            ) ??
            false;
      }
    } catch (e) {
      debugPrint('Notification permission request failed: $e');
    }
    return false;
  }

  @override
  Future<bool> isPermissionGranted() async {
    await init();
    try {
      final android = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      if (android != null) {
        return await android.areNotificationsEnabled() ?? false;
      }
      return true; // iOS: scheduling silently no-ops without permission.
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> replaceAll(
    List<PlannedNotification> items, {
    ReminderChannels? channels,
  }) async {
    await init();
    await _plugin.cancelAllPendingNotifications();
    final loc = _location!;
    final taskChannel = _details(
      _taskChannelId,
      channels?.taskName ?? _taskChannelId,
      channels?.taskDescription,
    );
    final checkinChannel = _details(
      _checkinChannelId,
      channels?.checkinName ?? _checkinChannelId,
      channels?.checkinDescription,
    );
    if (channels != null) {
      // Re-creating a channel updates its name, so a language switch shows
      // up in the system settings.
      try {
        final android = _plugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();
        await android?.createNotificationChannel(
          AndroidNotificationChannel(
            _taskChannelId,
            channels.taskName,
            description: channels.taskDescription,
          ),
        );
        await android?.createNotificationChannel(
          AndroidNotificationChannel(
            _checkinChannelId,
            channels.checkinName,
            description: channels.checkinDescription,
          ),
        );
      } catch (e) {
        debugPrint('Updating notification channels failed: $e');
      }
    }
    for (final n in items) {
      final w = n.when;
      try {
        await _plugin.zonedSchedule(
          id: n.id,
          title: n.title,
          body: n.body,
          scheduledDate: tz.TZDateTime(
            loc,
            w.year,
            w.month,
            w.day,
            w.hour,
            w.minute,
          ),
          notificationDetails: NotificationDetails(
            android: n.kind == ReminderKind.task ? taskChannel : checkinChannel,
            iOS: const DarwinNotificationDetails(),
          ),
          // Inexact on purpose: no SCHEDULE_EXACT_ALARM permission needed.
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          payload: n.payload,
        );
      } catch (e) {
        debugPrint('Schedule notification ${n.id} failed: $e');
      }
    }
  }
}

/// No-op gateway for platforms/tests without the plugin.
class NoopNotificationGateway implements NotificationGateway {
  @override
  Future<void> init({String timezone = 'Asia/Ho_Chi_Minh'}) async {}
  @override
  Future<bool> requestPermission() async => false;
  @override
  Future<bool> isPermissionGranted() async => false;
  @override
  Future<void> replaceAll(
    List<PlannedNotification> items, {
    ReminderChannels? channels,
  }) async {}
  @override
  Stream<String> get taps => const Stream.empty();
}
