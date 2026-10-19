// Guards against unreachable screens (QA round 2, B1: the milestone screen was
// routed but nothing navigated to it) and against navigation to paths that no
// route serves (B4: spec `/projects` vs `/garden`).
//
// 1. Every route registered in the real router has at least one caller in
//    `lib/`, unless it is an entry point by design (tab, deep link, auth
//    redirect target, spec alias) listed in [_entryPoints].
// 2. Every literal path passed to `context.go/push/pushReplacement` or
//    `router.go` matches a registered route.
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:vuon_nha/core/db/local_prefs.dart';
import 'package:vuon_nha/core/router/app_router.dart';

/// Routes that are entered without an in-app `go/push` call, and why.
const Map<String, String> _entryPoints = {
  // Bottom tab bar (shell.goBranch)
  '/today': 'tab',
  '/garden': 'tab',
  '/household': 'tab',
  '/achievements': 'tab',
  '/settings': 'tab',
  // Auth / onboarding redirects (authRedirect)
  '/login': 'auth redirect',
  '/config-error': 'auth redirect',
  '/onboarding/profile': 'auth redirect',
  '/onboarding/household': 'auth redirect',
  // Invite deep links vuonnha://join and https://.../i/<code>
  '/join': 'deep link',
  // Spec §2 names the Vườn tab /projects: redirects to /garden
  '/projects': 'spec alias',
};

class _Route {
  _Route(this.path);
  final String path;

  /// `/projects/:id/milestone/:code` -> matches `/projects/X/milestone/X`.
  late final RegExp matcher = RegExp(
    '^${path.split('/').map((s) => s.startsWith(':') ? '[^/]+' : RegExp.escape(s)).join('/')}\$',
  );
}

void _collect(List<RouteBase> routes, String parent, List<_Route> out) {
  for (final r in routes) {
    if (r is GoRoute) {
      final full = r.path.startsWith('/')
          ? r.path
          : '${parent == '/' ? '' : parent}/${r.path}';
      out.add(_Route(full));
      _collect(r.routes, full, out);
    } else if (r is StatefulShellRoute) {
      for (final b in r.branches) {
        _collect(b.routes, parent, out);
      }
    } else if (r is ShellRoute) {
      _collect(r.routes, parent, out);
    }
  }
}

/// One string literal that looks like an app path.
class _Literal {
  _Literal(this.file, this.line, this.text, this.source);
  final String file;
  final int line;
  final String text; // path with interpolations replaced by "X", query removed
  final String source; // the full source line
}

// `'/projects/$id/plan'` and `'$_base/checkin/retake'` (prefix built elsewhere).
final _strRe = RegExp(r"'((?:/|\$\{?\w+\}?/)[^'\s]*)'");

String _normalize(String literal) {
  var s = literal.split('?').first;
  s = s
      .replaceAll(RegExp(r'\$\{[^}]*\}'), 'X')
      .replaceAll(RegExp(r'\$\w+'), 'X');
  return s;
}

List<File> _libFiles() =>
    Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart') && !f.path.contains('/l10n/'))
        .toList();

void main() {
  late List<_Route> routes;
  late List<_Literal> literals;
  late Map<String, List<String>> lines; // file -> lines

  setUpAll(() {
    final container = ProviderContainer(
      overrides: [localPrefsProvider.overrideWithValue(MemoryLocalPrefs())],
    );
    addTearDown(container.dispose);
    final router = container.read(appRouterProvider);
    routes = [];
    _collect(router.configuration.routes, '/', routes);

    literals = [];
    lines = {};
    for (final f in _libFiles()) {
      final ls = f.readAsLinesSync();
      lines[f.path] = ls;
      for (var i = 0; i < ls.length; i++) {
        for (final m in _strRe.allMatches(ls[i])) {
          literals.add(_Literal(f.path, i + 1, _normalize(m.group(1)!), ls[i]));
        }
      }
    }
  });

  bool matches(_Route r, String target) {
    if (target.startsWith('/')) return r.matcher.hasMatch(target);
    // "X/checkin/retake": the prefix was interpolated, so compare the tail.
    // Needs at least one static segment so "$a/$b" never matches.
    final tail = target.split('/').skip(1).toList();
    if (tail.every((t) => t == 'X')) return false;
    final segs = r.path.split('/').skip(1).toList();
    if (segs.length <= tail.length) return false;
    final end = segs.sublist(segs.length - tail.length);
    for (var i = 0; i < tail.length; i++) {
      if (tail[i] != 'X' && tail[i] != end[i]) return false;
      if (tail[i] == 'X' && !end[i].startsWith(':')) return false;
    }
    return true;
  }

  test('the router registers the expected screens', () {
    final paths = routes.map((r) => r.path).toSet();
    expect(
      paths,
      containsAll([
        '/today',
        '/garden',
        '/projects',
        '/projects/:id',
        '/projects/:id/milestone/:code',
        '/join',
      ]),
    );
  });

  test('every registered route has a caller or is an entry point', () {
    final unreachable = <String>[];
    for (final r in routes) {
      if (_entryPoints.containsKey(r.path)) continue;
      var callers = 0;
      for (final lit in literals) {
        if (!matches(r, lit.text)) continue;
        final src = lit.source.trim();
        if (src.startsWith('path:')) continue; // the route definition
        final decl = _staticDecl(lit.file, lit.line);
        if (decl != null) {
          // A path constant / builder: callers are the references to it.
          final name = decl.group(1)!;
          final cls = _enclosingClass(lit.file, lit.line);
          final ref = RegExp('\\b$cls\\.$name\\b');
          final used = lines.entries.any(
            (e) => e.value.any((l) => ref.hasMatch(l)),
          );
          if (used) callers++;
        } else {
          callers++;
        }
      }
      // `'${Class.name}?code=…'` style references to a path constant.
      for (final e in lines.entries) {
        for (final l in e.value) {
          for (final m in RegExp(r'\$\{(\w+)\.(\w+)\}').allMatches(l)) {
            final constant = _constantValue(m.group(1)!, m.group(2)!);
            if (constant != null && matches(r, constant)) callers++;
          }
        }
      }
      if (callers == 0) unreachable.add(r.path);
    }
    expect(
      unreachable,
      isEmpty,
      reason:
          'No caller found for these routes. Navigate to them from the UI, or '
          'list them in _entryPoints with the reason they need no caller.',
    );
  });

  test('every literal navigation target matches a registered route', () {
    final call = RegExp(
      r"(?:\.go|\.push|\.pushReplacement)\(\s*'((?:/|\$\{?\w+\}?/)[^']*)'",
      multiLine: true,
    );
    final missing = <String>[];
    var checked = 0;
    for (final f in _libFiles()) {
      final src = f.readAsStringSync();
      for (final m in call.allMatches(src)) {
        final target = _normalize(m.group(1)!);
        checked++;
        if (!routes.any((r) => matches(r, target))) {
          missing.add('${f.path}: ${m.group(1)}');
        }
      }
    }
    expect(checked, greaterThan(10), reason: 'scanner found no calls');
    expect(missing, isEmpty);
  });

  test('every entry point is a registered route (no stale entries)', () {
    final paths = routes.map((r) => r.path).toSet();
    expect(
      _entryPoints.keys.where((k) => !paths.contains(k)),
      isEmpty,
      reason: 'remove entries for routes that no longer exist',
    );
  });

  test('the scanner would catch an uncalled route', () {
    // Self-check: a made-up route with no literal anywhere has no callers.
    final r = _Route('/definitely/unused/:id');
    expect(literals.where((l) => matches(r, l.text)), isEmpty);
  });
}

/// `static const name = '/x';` or `static String name(...) =>\n '/x'`: the
/// declaration (within two lines above) that the literal at [line] belongs to.
RegExpMatch? _staticDecl(String file, int line) {
  final ls = File(file).readAsLinesSync();
  final re = RegExp(
    r'static\s+(?:const\s+|final\s+)?(?:String\s+)?(\w+)\s*[=(]',
  );
  for (var k = 0; k < 3 && line - 1 - k >= 0; k++) {
    final l = ls[line - 1 - k];
    if (k > 0 && l.trimRight().endsWith(';')) return null;
    final m = re.firstMatch(l);
    if (m != null) return m;
  }
  return null;
}

String _enclosingClass(String file, int line) {
  final ls = File(file).readAsLinesSync();
  for (var i = line - 1; i >= 0; i--) {
    final m = RegExp(r'^\s*(?:abstract\s+)?class\s+(\w+)').firstMatch(ls[i]);
    if (m != null) return m.group(1)!;
  }
  return '';
}

/// Value of `static const name = '/path';` in class [cls], or null.
String? _constantValue(String cls, String name) {
  for (final f in _libFiles()) {
    final s = f.readAsStringSync();
    if (!s.contains('class $cls')) continue;
    final m = RegExp("static const (?:String )?$name = '([^']*)'")
        .firstMatch(s);
    if (m != null) return _normalize(m.group(1)!);
  }
  return null;
}
