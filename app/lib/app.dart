import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/glass_config.dart';
import 'features/settings/presentation/locale_provider.dart';
import 'l10n/app_localizations.dart';

/// Global switch for BackdropFilter blur (disable on low-end devices).
class GlassBlurNotifier extends Notifier<bool> {
  @override
  bool build() => true;
  void set(bool value) => state = value;
}

final glassBlurProvider = NotifierProvider<GlassBlurNotifier, bool>(
  GlassBlurNotifier.new,
);

class VuonNhaApp extends ConsumerWidget {
  const VuonNhaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final blur = ref.watch(glassBlurProvider);
    return MaterialApp.router(
      onGenerateTitle: (c) => AppLocalizations.of(c).appName,
      theme: AppTheme.light(),
      routerConfig: router,
      locale: ref.watch(localeProvider),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) =>
          GlassConfig(blur: blur, child: child ?? const SizedBox.shrink()),
    );
  }
}
