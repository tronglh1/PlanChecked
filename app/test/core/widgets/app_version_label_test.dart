import 'package:flutter_test/flutter_test.dart';
import 'package:vuon_nha/core/widgets/app_version_label.dart';

void main() {
  test('version, build number and short commit', () {
    expect(
      AppVersionLabel.format('1.0.0', '12', 'abcdef1234567'),
      '1.0.0 (12) · abcdef1',
    );
  });

  test('local builds without a commit or build number', () {
    expect(AppVersionLabel.format('1.0.0', '', ''), '1.0.0');
  });
}
