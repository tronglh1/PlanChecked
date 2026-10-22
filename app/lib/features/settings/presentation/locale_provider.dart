import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/local_prefs.dart';

const String kLocalePrefKey = 'locale';

/// App locale. Defaults to Vietnamese, restored from local prefs, and
/// changing it rebuilds MaterialApp live.
class LocaleNotifier extends Notifier<Locale> {
  @override
  Locale build() {
    _restore();
    return const Locale('vi');
  }

  Future<void> _restore() async {
    try {
      final saved = await ref.read(localPrefsProvider).get(kLocalePrefKey);
      if (saved == 'en' || saved == 'vi') state = Locale(saved!);
    } catch (_) {
      // Local store unavailable: keep default.
    }
  }

  Future<void> set(String lang) async {
    state = Locale(lang);
    try {
      await ref.read(localPrefsProvider).set(kLocalePrefKey, lang);
    } catch (_) {}
  }
}

final localeProvider = NotifierProvider<LocaleNotifier, Locale>(
  LocaleNotifier.new,
);
