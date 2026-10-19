import 'package:go_router/go_router.dart';

import 'presentation/checkin_capture_screen.dart';
import 'presentation/checkin_providers.dart';
import 'presentation/checkin_result_screen.dart';
import 'presentation/checkin_retake_screen.dart';

/// Check-in routes (screens 13, 14, 15). `retake` must stay before
/// `:checkinId` so it is not read as an id. The retake screen takes a
/// [RetakeInfo] as `extra`.
final List<RouteBase> checkinRoutes = [
  GoRoute(
    path: '/projects/:id/checkin',
    builder: (_, state) =>
        CheckinCaptureScreen(projectId: state.pathParameters['id']!),
  ),
  GoRoute(
    path: '/projects/:id/checkin/retake',
    builder: (_, state) => CheckinRetakeScreen(
      projectId: state.pathParameters['id']!,
      info: state.extra is RetakeInfo ? state.extra as RetakeInfo : null,
    ),
  ),
  GoRoute(
    path: '/projects/:id/checkin/:checkinId',
    builder: (_, state) => CheckinResultScreen(
      projectId: state.pathParameters['id']!,
      checkinId: state.pathParameters['checkinId']!,
    ),
  ),
];
