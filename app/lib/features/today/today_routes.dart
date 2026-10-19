import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/widgets/widgets.dart';
import '../../l10n/app_localizations.dart';
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
  // Placeholder until the check-in milestone replaces it.
  GoRoute(
    path: '/projects/:id/checkin',
    builder: (context, _) => _Placeholder(
      title: AppLocalizations.of(context).todayCheckinDueTitle,
      message: AppLocalizations.of(context).taskCheckinPlaceholder,
    ),
  ),
];

class _Placeholder extends StatelessWidget {
  const _Placeholder({required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return GlassScaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(title),
        leading: BackButton(
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/today'),
        ),
      ),
      body: EmptyState(icon: Icons.construction_rounded, title: message),
    );
  }
}
