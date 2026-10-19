import 'package:go_router/go_router.dart';

import 'presentation/achievements_screen.dart';
import 'presentation/milestone_screen.dart';

class GamificationPaths {
  const GamificationPaths._();
  static const achievements = '/achievements';
  static String milestone(String projectId, String code) =>
      '/projects/$projectId/milestone/$code';
}

/// Branch routes of the "Thành tích" tab (shell, tab bar visible).
List<RouteBase> gamificationTabRoutes() => [
  GoRoute(
    path: GamificationPaths.achievements,
    builder: (_, _) => const AchievementsScreen(),
  ),
];

/// Full-screen routes (no tab bar).
List<RouteBase> gamificationRoutes() => [
  GoRoute(
    path: '/projects/:id/milestone/:code',
    builder: (_, state) => MilestoneScreen(
      projectId: state.pathParameters['id']!,
      code: state.pathParameters['code']!,
    ),
  ),
];
