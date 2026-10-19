import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/auth_state.dart';
import '../../features/auth/presentation/config_error_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/plants/presentation/plant_search_screen.dart';
import '../../features/profile/presentation/profile_providers.dart';
import '../../features/profile/presentation/profile_setup_screen.dart';
import '../../features/projects/presentation/project_context_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/today/presentation/today_screen.dart';
import '../../features/today/today_routes.dart';
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
  static const onboardingProfile = '/onboarding/profile';
  static const plantSearch = '/projects/new/search';
  static const projectContext = '/projects/new/context';
  static const configError = '/config-error';
}

/// Pure redirect rule so it can be unit tested.
///
/// [profile] only matters when signed in: a signed-in user whose profile is
/// [ProfileStatus.missing] is held on the onboarding profile screen.
String? authRedirect(
  AuthStatus status,
  String location, {
  ProfileStatus profile = ProfileStatus.complete,
}) {
  switch (status) {
    case AuthStatus.configMissing:
      return location == AppRoutes.configError ? null : AppRoutes.configError;
    case AuthStatus.signedOut:
      return location == AppRoutes.login ? null : AppRoutes.login;
    case AuthStatus.signedIn:
      if (profile == ProfileStatus.missing) {
        return location == AppRoutes.onboardingProfile
            ? null
            : AppRoutes.onboardingProfile;
      }
      if (location == AppRoutes.login || location == AppRoutes.configError) {
        return AppRoutes.today;
      }
      return null;
  }
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier<int>(0);
  ref.listen<AuthStatus>(authStateProvider, (_, _) => refresh.value++);
  ref.listen<ProfileStatus>(profileStatusProvider, (_, _) => refresh.value++);
  ref.onDispose(refresh.dispose);

  final router = GoRouter(
    initialLocation: AppRoutes.today,
    refreshListenable: refresh,
    redirect: (context, state) => authRedirect(
      ref.read(authStateProvider),
      state.matchedLocation,
      profile: ref.read(profileStatusProvider),
    ),
    routes: [
      GoRoute(path: AppRoutes.login, builder: (_, _) => const LoginScreen()),
      GoRoute(
        path: AppRoutes.onboardingProfile,
        builder: (_, _) => const ProfileSetupScreen(),
      ),
      GoRoute(
        path: AppRoutes.plantSearch,
        builder: (_, _) => const PlantSearchScreen(),
      ),
      GoRoute(
        path: AppRoutes.projectContext,
        builder: (_, state) => ProjectContextScreen(
          plantId: state.uri.queryParameters['plant'],
          freeText: state.uri.queryParameters['name'],
        ),
      ),
      GoRoute(
        path: AppRoutes.configError,
        builder: (_, _) => const ConfigErrorScreen(),
      ),
      ...todayRoutes,
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => _Shell(shell: shell),
        branches: [
          _branch(
            AppRoutes.today,
            Icons.today_rounded,
            (l) => l.tabToday,
            builder: (_) => const TodayScreen(),
          ),
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
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.settings,
                builder: (_, _) => const SettingsScreen(),
              ),
            ],
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
  String Function(AppLocalizations) title, {
  WidgetBuilder? builder,
}) {
  return StatefulShellBranch(
    routes: [
      GoRoute(
        path: path,
        builder: (context, _) =>
            builder?.call(context) ??
            TabPlaceholder(
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
