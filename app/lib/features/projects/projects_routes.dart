import 'package:go_router/go_router.dart';

import 'presentation/project_detail_screen.dart';

/// Detail route of the projects feature. The search (`/projects/new/search`)
/// and context (`/projects/new/context`) routes live in app_router.dart.
/// Order matters: register these after the `/projects/new/*` routes.
final List<RouteBase> projectsRoutes = [
  GoRoute(
    path: '/projects/:id',
    builder: (_, state) =>
        ProjectDetailScreen(projectId: state.pathParameters['id']!),
  ),
];
