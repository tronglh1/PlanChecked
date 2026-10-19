import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vuon_nha/core/widgets/glow_button.dart';

Widget _host(Widget child) => MaterialApp(
  home: Scaffold(body: Center(child: child)),
);

void main() {
  testWidgets('renders the label', (t) async {
    await t.pumpWidget(
      _host(GlowButton(label: 'Tiếp tục', onPressed: () {})),
    );
    expect(find.text('Tiếp tục'), findsOneWidget);
  });

  testWidgets('primary variant uses white label text', (t) async {
    await t.pumpWidget(
      _host(GlowButton(label: 'Tiếp tục', onPressed: () {})),
    );
    final text = t.widget<Text>(find.text('Tiếp tục'));
    expect(text.style?.color, Colors.white);
  });

  testWidgets('onPressed fires on tap', (t) async {
    var taps = 0;
    await t.pumpWidget(
      _host(GlowButton(label: 'Lưu', onPressed: () => taps++)),
    );
    await t.tap(find.text('Lưu'));
    await t.pump();
    expect(taps, 1);
  });

  testWidgets('disabled button is dimmed and does not fire', (t) async {
    await t.pumpWidget(
      _host(const GlowButton(label: 'Lưu', onPressed: null)),
    );
    final opacity = t.widget<Opacity>(
      find.descendant(
        of: find.byType(GlowButton),
        matching: find.byType(Opacity),
      ),
    );
    expect(opacity.opacity, 0.5);
    // Tapping a disabled button must not throw or enable anything.
    await t.tap(find.text('Lưu'));
    await t.pump();
    expect(find.text('Lưu'), findsOneWidget);
  });
}
