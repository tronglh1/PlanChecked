import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vuon_nha/features/plants/presentation/plant_search_screen.dart';

import '../../helpers/fakes.dart';

void main() {
  testWidgets('typing "rau muong" finds "Rau muống"', (t) async {
    await pumpApp(t, const PlantSearchScreen());
    expect(find.text('Rau muống'), findsOneWidget);
    expect(find.text('Trầu bà'), findsOneWidget);

    await t.enterText(find.byKey(const Key('plant-search-field')), 'rau muong');
    await t.pumpAndSettle();
    expect(find.text('Rau muống'), findsOneWidget);
    expect(find.text('Ipomoea aquatica'), findsOneWidget);
    expect(find.text('Dễ'), findsOneWidget);
    expect(find.text('Thu hoạch ~30 ngày'), findsOneWidget);
    expect(find.text('Cà chua bi'), findsNothing);
    expect(find.text('1 kết quả cho “rau muong”'), findsOneWidget);
  });

  testWidgets('group filter hides other groups', (t) async {
    await pumpApp(t, const PlantSearchScreen());
    await t.tap(find.byKey(const Key('filter-ornamental')));
    await t.pumpAndSettle();
    expect(find.text('Trầu bà'), findsOneWidget);
    expect(find.text('Rau muống'), findsNothing);
  });

  testWidgets('typo shows "Có phải bạn muốn nói" suggestion', (t) async {
    await pumpApp(t, const PlantSearchScreen());
    await t.enterText(
      find.byKey(const Key('plant-search-field')),
      'ca chua tin',
    );
    await t.pumpAndSettle();
    expect(find.textContaining('Có phải bạn muốn nói'), findsOneWidget);
    expect(find.byKey(const Key('suggest-yes-p3')), findsOneWidget);
  });

  testWidgets('no match offers free-text fallback', (t) async {
    await pumpApp(t, const PlantSearchScreen());
    await t.enterText(find.byKey(const Key('plant-search-field')), 'xoai cat');
    await t.pumpAndSettle();
    expect(find.text('Không thấy cây bạn cần?'), findsOneWidget);
    expect(find.byKey(const Key('free-text-button')), findsOneWidget);
    expect(find.text('Dùng “xoai cat”'), findsOneWidget);
  });
}
