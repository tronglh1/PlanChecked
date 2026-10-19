import 'package:go_router/go_router.dart';

import 'presentation/task_detail_screen.dart';

class TodayRoutes {
  const TodayRoutes._();

  static String task(String id) => '/task/$id';
  static String assign(String id) => '/task/$id/assign';
  static String checkin(String projectId) => '/projects/$projectId/checkin';
}

/// Routes owned by the Today feature (outside the tab shell). Registered in
/// `core/router/app_router.dart` with `...todayRoutes`.
final List<RouteBase> todayRoutes = [
  GoRoute(
    path: '/task/:id',
    builder: (_, state) =>
        TaskDetailScreen(taskId: state.pathParameters['id']!),
  ),
];
