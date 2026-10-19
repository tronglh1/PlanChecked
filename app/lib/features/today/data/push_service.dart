import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// A push received while the app is open (shown as an in-app banner).
class PushMessage {
  const PushMessage({this.title, this.body, this.data = const {}});

  final String? title;
  final String? body;
  final Map<String, dynamic> data;

  bool get isEmpty =>
      (title == null || title!.isEmpty) && (body == null || body!.isEmpty);
}

/// Thin wrapper over Firebase so the rest of the app (and tests) never
/// import it.
abstract class PushMessaging {
  /// Initializes Firebase. Returns false (never throws) when the app has no
  /// Firebase config (`google-services.json` / plist missing).
  Future<bool> init();
  Future<String?> getToken();
  Stream<String> get onTokenRefresh;
  Stream<PushMessage> get onMessage;
}

class FirebasePushMessaging implements PushMessaging {
  bool _ready = false;

  @override
  Future<bool> init() async {
    if (_ready) return true;
    try {
      await Firebase.initializeApp();
      _ready = true;
    } catch (e) {
      debugPrint('Firebase not configured, push disabled: $e');
    }
    return _ready;
  }

  @override
  Future<String?> getToken() async {
    if (!_ready) return null;
    try {
      return await FirebaseMessaging.instance.getToken();
    } catch (e) {
      debugPrint('FCM getToken failed: $e');
      return null;
    }
  }

  @override
  Stream<String> get onTokenRefresh =>
      _ready ? FirebaseMessaging.instance.onTokenRefresh : const Stream.empty();

  @override
  Stream<PushMessage> get onMessage => !_ready
      ? const Stream.empty()
      : FirebaseMessaging.onMessage.map(
          (m) => PushMessage(
            title: m.notification?.title,
            body: m.notification?.body,
            data: m.data,
          ),
        );
}

/// Stores the device token in `push_tokens (user_id, token, platform)`.
abstract class PushTokenRepository {
  Future<void> save({
    required String userId,
    required String token,
    required String platform,
  });
}

class SupabasePushTokenRepository implements PushTokenRepository {
  SupabasePushTokenRepository([SupabaseClient? client])
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  @override
  Future<void> save({
    required String userId,
    required String token,
    required String platform,
  }) async {
    await _client.from('push_tokens').upsert({
      'user_id': userId,
      'token': token,
      'platform': platform,
    }, onConflict: 'user_id,token');
  }
}

/// Starts FCM once the user is signed in: init (guarded), save the token,
/// keep it fresh and forward foreground messages.
class PushService {
  PushService({
    required this.messaging,
    required this.tokens,
    required this.platform,
    required this.onForegroundMessage,
  });

  final PushMessaging messaging;
  final PushTokenRepository tokens;
  final String platform;
  final void Function(PushMessage) onForegroundMessage;

  final List<StreamSubscription<dynamic>> _subs = [];
  bool enabled = false;

  /// Returns whether push is active (false when Firebase is not configured).
  Future<bool> start(String userId) async {
    await stop();
    enabled = await messaging.init();
    if (!enabled) return false;
    final token = await messaging.getToken();
    if (token != null) await _save(userId, token);
    _subs.add(messaging.onTokenRefresh.listen((t) => _save(userId, t)));
    _subs.add(
      messaging.onMessage.listen((m) {
        if (!m.isEmpty) onForegroundMessage(m);
      }),
    );
    return true;
  }

  Future<void> _save(String userId, String token) async {
    try {
      await tokens.save(userId: userId, token: token, platform: platform);
    } catch (e) {
      debugPrint('Saving push token failed: $e');
    }
  }

  Future<void> stop() async {
    for (final s in _subs) {
      await s.cancel();
    }
    _subs.clear();
  }
}

/// Platform string stored in `push_tokens.platform`.
String pushPlatformName() => switch (defaultTargetPlatform) {
  TargetPlatform.android => 'android',
  TargetPlatform.iOS => 'ios',
  _ => kIsWeb ? 'web' : defaultTargetPlatform.name,
};
