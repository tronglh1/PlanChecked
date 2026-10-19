import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/widgets.dart';
import '../data/push_service.dart';
import 'today_providers.dart';

/// Latest foreground push, shown as an in-app banner.
class PushBannerNotifier extends Notifier<PushMessage?> {
  @override
  PushMessage? build() => null;
  void show(PushMessage m) => state = m;
  void dismiss() => state = null;
}

final pushBannerProvider = NotifierProvider<PushBannerNotifier, PushMessage?>(
  PushBannerNotifier.new,
);

/// Wraps the app (MaterialApp.builder): keeps Today's data synced
/// (app resume + periodic retry while actions are queued), starts FCM after
/// sign-in, opens the screen of a tapped reminder and hosts the push banner.
class TodayBootstrap extends ConsumerStatefulWidget {
  const TodayBootstrap({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<TodayBootstrap> createState() => _TodayBootstrapState();
}

class _TodayBootstrapState extends ConsumerState<TodayBootstrap>
    with WidgetsBindingObserver {
  Timer? _timer;
  PushService? _push;
  StreamSubscription<String>? _taps;
  Timer? _bannerTimer;
  bool _initialUserHandled = false;

  void _onUser(String? uid) {
    if (uid != null) {
      _startPush(uid);
      _listenTaps();
    } else {
      _push?.stop();
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Offline retry: no connectivity plugin, so poll while anything is queued.
    _timer = Timer.periodic(const Duration(seconds: 45), (_) {
      if (!mounted) return;
      final m = ref.read(todayModelProvider);
      if (m.userId != null && m.pendingCount > 0) {
        ref.read(todayModelProvider.notifier).syncNow();
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _bannerTimer?.cancel();
    _taps?.cancel();
    _push?.stop();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed &&
        ref.read(todayModelProvider).userId != null) {
      ref.read(todayModelProvider.notifier).syncNow(force: true);
    }
  }

  Future<void> _startPush(String userId) async {
    try {
      _push ??= PushService(
        messaging: ref.read(pushMessagingProvider),
        tokens: ref.read(pushTokenRepositoryProvider),
        platform: pushPlatformName(),
        onForegroundMessage: (m) {
          ref.read(pushBannerProvider.notifier).show(m);
          _bannerTimer?.cancel();
          _bannerTimer = Timer(
            const Duration(seconds: 5),
            () => ref.read(pushBannerProvider.notifier).dismiss(),
          );
        },
      );
      await _push!.start(userId);
    } catch (e) {
      debugPrint('Push start skipped: $e');
    }
  }

  void _listenTaps() {
    try {
      _taps ??= ref.read(notificationGatewayProvider).taps.listen((route) {
        ref.read(appRouterProvider).go(route);
      });
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    // Instantiate the controller as soon as the user is signed in, even when
    // the Today tab is not visible, so reminders are always planned.
    ref.listen(todayModelProvider, (_, _) {});
    ref.listen<String?>(currentUserIdProvider, (_, uid) => _onUser(uid));
    if (!_initialUserHandled) {
      _initialUserHandled = true;
      final uid = ref.read(currentUserIdProvider);
      if (uid != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _onUser(uid));
      }
    }

    final banner = ref.watch(pushBannerProvider);
    return Stack(
      children: [
        widget.child,
        if (banner != null)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Material(
                  color: Colors.transparent,
                  child: GlassCard(
                    key: const Key('push-banner'),
                    onTap: () =>
                        ref.read(pushBannerProvider.notifier).dismiss(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (banner.title != null)
                          Text(
                            banner.title!,
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        if (banner.body != null) Text(banner.body!),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
