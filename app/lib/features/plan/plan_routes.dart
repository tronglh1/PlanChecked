import 'package:go_router/go_router.dart';

import 'presentation/generating_screen.dart';
import 'presentation/plan_calendar_screen.dart';
import 'presentation/plan_review_screen.dart';

/// Plan routes (screens 09, 10, 11).
final List<RouteBase> planRoutes = [
  GoRoute(
    path: '/projects/:id/generating',
    builder: (_, state) =>
        GeneratingScreen(
          projectId: state.pathParameters['id']!,
          plantGroup: state.uri.queryParameters['group'],
        ),
  ),
  GoRoute(
    path: '/projects/:id/plan',
    builder: (_, state) =>
        PlanReviewScreen(projectId: state.pathParameters['id']!),
  ),
  GoRoute(
    path: '/projects/:id/calendar',
    builder: (_, state) =>
        PlanCalendarScreen(projectId: state.pathParameters['id']!),
  ),
];
