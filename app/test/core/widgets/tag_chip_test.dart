import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vuon_nha/core/theme/tokens.dart';
import 'package:vuon_nha/core/widgets/tag_chip.dart';

class _Host extends StatefulWidget {
  const _Host();

  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> {
  bool selected = false;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: TagChip(
            label: 'Rau & quả',
            selected: selected,
            onTap: () => setState(() => selected = !selected),
          ),
        ),
      ),
    );
  }
}

void main() {
  testWidgets('selected toggles the chip style and fires onTap', (t) async {
    await t.pumpWidget(const _Host());

    Text label() => t.widget<Text>(find.text('Rau & quả'));

    // Unselected: body text color, regular weight.
    expect(label().style?.color, AppColors.text);
    expect(label().style?.fontWeight, FontWeight.w500);

    await t.tap(find.text('Rau & quả'));
    await t.pump();

    // Selected: orange text (spec §1.2), semi-bold.
    expect(label().style?.color, AppColors.orangeText);
    expect(label().style?.fontWeight, FontWeight.w600);

    await t.tap(find.text('Rau & quả'));
    await t.pump();

    expect(label().style?.color, AppColors.text);
    expect(label().style?.fontWeight, FontWeight.w500);
  });
}
