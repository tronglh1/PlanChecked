import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../l10n/app_localizations.dart';
import '../theme/tokens.dart';

/// Commit the APK was built from; CI passes `--dart-define=APP_BUILD=<sha>`.
const String _kAppBuild = String.fromEnvironment('APP_BUILD');

/// "Phiên bản 1.0.0 (12) · abc1234": tells testers which build they are on.
/// Renders nothing until the platform answers (and in widget tests, where
/// the plugin is absent).
class AppVersionLabel extends StatelessWidget {
  const AppVersionLabel({super.key});

  static Future<PackageInfo?>? _info;

  static Future<PackageInfo?> _load() async {
    try {
      return await PackageInfo.fromPlatform();
    } catch (_) {
      return null;
    }
  }

  static String format(String version, String buildNumber, String commit) {
    final parts = [
      buildNumber.isEmpty ? version : '$version ($buildNumber)',
      if (commit.isNotEmpty)
        commit.length > 7 ? commit.substring(0, 7) : commit,
    ];
    return parts.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PackageInfo?>(
      future: _info ??= _load(),
      builder: (context, snap) {
        final info = snap.data;
        if (info == null) return const SizedBox.shrink();
        return Text(
          AppLocalizations.of(context)
              .appVersion(format(info.version, info.buildNumber, _kAppBuild)),
          key: const Key('app-version'),
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall
              ?.copyWith(color: AppColors.textSecondary),
        );
      },
    );
  }
}
