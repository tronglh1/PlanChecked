import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/auth_state.dart';
import '../../features/auth/presentation/placeholder_screens.dart';
import '../../l10n/app_localizations.dart';
import '../widgets/glass_scaffold.dart';
import 'glass_bottom_bar.dart';
import 'tab_placeholder.dart';

class AppRoutes {
  const AppRoutes._();
  static const today = '/today';
  static const garden = '/garden';
  static const family = '/family';
  static const achievements = '/achievements';
  static const settings = '/settings';
  static const login = '/login';
  static const onboarding = '/onboarding';
  static const configError = '/config-error';
}

/// Pure redirect rule so it can be unit tested.
String? authRedirect(AuthStatus status, String location) {
  switch (status) {
    case AuthStatus.configMissing:
      return location == AppRoutes.configError ? null : AppRoutes.configError;
    case AuthStatus.signedOut:
      return location == AppRoutes.login ? null : AppRoutes.login;
    case AuthStatus.signedIn:
      if (location == AppRoutes.login || location == AppRoutes.configError) {
        return AppRoutes.today;
      }
      return null;
  }
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier<int>(0);
  ref.listen<AuthStatus>(authStateProvider, (_, _) => refresh.value++);
  ref.onDispose(refresh.dispose);

  final router = GoRouter(
    initialLocation: AppRoutes.today,
    refreshListenable: refresh,
    redirect: (context, state) =>
        authRedirect(ref.read(authStateProvider), state.matchedLocation),
    routes: [
      GoRoute(path: AppRoutes.login, builder: (_, _) => const LoginScreen()),
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (_, _) => const OnboardingScreen(),
      ),
      GoRoute(
        path: AppRoutes.configError,
        builder: (_, _) => const ConfigErrorScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => _Shell(shell: shell),
        branches: [
          _branch(AppRoutes.today, Icons.today_rounded, (l) => l.tabToday),
          _branch(AppRoutes.garden, Icons.yard_rounded, (l) => l.tabGarden),
          _branch(
            AppRoutes.family,
            Icons.family_restroom_rounded,
            (l) => l.tabFamily,
          ),
          _branch(
            AppRoutes.achievements,
            Icons.emoji_events_rounded,
            (l) => l.tabAchievements,
          ),
          _branch(
            AppRoutes.settings,
            Icons.settings_rounded,
            (l) => l.tabSettings,
          ),
        ],
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});

StatefulShellBranch _branch(
  String path,
  IconData icon,
  String Function(AppLocalizations) title,
) {
  return StatefulShellBranch(
    routes: [
      GoRoute(
        path: path,
        builder: (context, _) => TabPlaceholder(
          title: title(AppLocalizations.of(context)),
          icon: icon,
        ),
      ),
    ],
  );
}

class _Shell extends StatelessWidget {
  const _Shell({required this.shell});

  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) {
    return GlassScaffold(
      body: shell,
      bottomNavigationBar: GlassBottomBar(
        currentIndex: shell.currentIndex,
        onSelected: (i) =>
            shell.goBranch(i, initialLocation: i == shell.currentIndex),
      ),
    );
  }
}
