import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'domain/household_models.dart';
import 'presentation/assign_task_screen.dart';
import 'presentation/household_providers.dart';
import 'presentation/household_screen.dart';
import 'presentation/household_setup_screen.dart';
import 'presentation/invite_screen.dart';
import 'presentation/join_screen.dart';

class HouseholdPaths {
  const HouseholdPaths._();
  static const onboarding = '/onboarding/household';
  static const tab = '/household';
  static const invite = '/household/invite';
  static const join = '/join';
  static String assign(String taskId) => '/task/$taskId/assign';
}

/// Branch routes of the "Gia đình" tab (shell, tab bar visible).
List<RouteBase> householdTabRoutes() => [
  GoRoute(path: HouseholdPaths.tab, builder: (_, _) => const HouseholdScreen()),
];

/// Full-screen routes (no tab bar).
List<RouteBase> householdRoutes() => [
  GoRoute(
    path: HouseholdPaths.onboarding,
    builder: (_, _) => const HouseholdSetupScreen(),
  ),
  GoRoute(path: HouseholdPaths.invite, builder: (_, _) => const InviteScreen()),
  GoRoute(
    path: HouseholdPaths.join,
    builder: (_, state) => JoinScreen(code: state.uri.queryParameters['code']),
  ),
  GoRoute(
    path: '/task/:taskId/assign',
    builder: (_, state) =>
        AssignTaskScreen(taskId: state.pathParameters['taskId']!),
  ),
];

/// Should [location] stay reachable while the household step is pending?
bool householdSetupExempt(String location) =>
    location == '/onboarding/profile' ||
    location == HouseholdPaths.onboarding ||
    location == HouseholdPaths.invite ||
    location.startsWith(HouseholdPaths.join);

/// Routes invite deep links (`vuonnha://join?code=`, `https://vuonnha.app/i/<code>`)
/// to `/join`. The code is also remembered so it survives a sign-in detour.
/// Other URIs (Supabase auth callbacks) are ignored.
StreamSubscription<Uri>? attachJoinDeepLinks(
  Ref ref,
  GoRouter router, {
  AppLinks? links,
}) {
  void handle(Uri uri) {
    final code = joinCodeFromUri(uri);
    if (code == null) return;
    ref.read(pendingJoinCodeProvider.notifier).set(code);
    router.go('${HouseholdPaths.join}?code=$code');
  }

  try {
    final l = links ?? AppLinks();
    l
        .getInitialLink()
        .then((u) {
          if (u != null) handle(u);
        })
        .catchError((_) {});
    return l.uriLinkStream.listen(handle, onError: (_) {});
  } catch (_) {
    return null;
  }
}
