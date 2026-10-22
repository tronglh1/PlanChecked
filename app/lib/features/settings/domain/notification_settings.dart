/// `notif_type` enum values (spec §4.1) that have a toggle on screen 21.
enum NotifType {
  taskReminder('task_reminder'),
  checkinReminder('checkin_reminder'),
  assignment('assignment'),
  achievement('achievement');

  const NotifType(this.code);
  final String code;
}

/// Immutable snapshot of notification toggles. Defaults follow the mockup:
/// all types on, bundling off.
class NotificationSettings {
  const NotificationSettings({
    this.enabled = const {
      NotifType.taskReminder: true,
      NotifType.checkinReminder: true,
      NotifType.assignment: true,
      NotifType.achievement: true,
    },
    this.bundleDaily = false,
  });

  final Map<NotifType, bool> enabled;
  final bool bundleDaily;

  bool isEnabled(NotifType t) => enabled[t] ?? true;

  NotificationSettings withType(NotifType t, bool value) =>
      NotificationSettings(
        enabled: {...enabled, t: value},
        bundleDaily: bundleDaily,
      );

  NotificationSettings withBundle(bool value) =>
      NotificationSettings(enabled: enabled, bundleDaily: value);

  /// Local-store encoding: `task_reminder=1;...;bundle=0`.
  String encode() {
    final parts = [
      for (final t in NotifType.values) '${t.code}=${isEnabled(t) ? 1 : 0}',
      'bundle=${bundleDaily ? 1 : 0}',
    ];
    return parts.join(';');
  }

  factory NotificationSettings.decode(String? raw) {
    if (raw == null || raw.isEmpty) return const NotificationSettings();
    final map = <String, bool>{};
    for (final part in raw.split(';')) {
      final kv = part.split('=');
      if (kv.length == 2) map[kv[0]] = kv[1] == '1';
    }
    return NotificationSettings(
      enabled: {for (final t in NotifType.values) t: map[t.code] ?? true},
      bundleDaily: map['bundle'] ?? false,
    );
  }
}
