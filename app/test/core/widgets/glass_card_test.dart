import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vuon_nha/core/widgets/glass_card.dart';

Widget _host(Widget child) => MaterialApp(
  home: Scaffold(body: Center(child: child)),
);

void main() {
  testWidgets('renders child with blur on (BackdropFilter present)', (t) async {
    await t.pumpWidget(
      _host(const GlassCard(blur: true, child: Text('nội dung'))),
    );
    expect(find.text('nội dung'), findsOneWidget);
    expect(find.byType(BackdropFilter), findsOneWidget);
    final filter = t.widget<BackdropFilter>(find.byType(BackdropFilter));
    expect(filter.filter, isA<ImageFilter>());
  });

  testWidgets('renders child with blur off (no BackdropFilter)', (t) async {
    await t.pumpWidget(
      _host(const GlassCard(blur: false, child: Text('nội dung'))),
    );
    expect(find.text('nội dung'), findsOneWidget);
    expect(find.byType(BackdropFilter), findsNothing);
  });
}
