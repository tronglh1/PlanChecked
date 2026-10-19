import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vuon_nha/core/theme/tokens.dart';

void main() {
  test('primary gradient colors are #FFB070, #FF7F32, #F2600F', () {
    expect(AppGradients.primary.colors, const [
      Color(0xFFFFB070),
      Color(0xFFFF7F32),
      Color(0xFFF2600F),
    ]);
  });
}
