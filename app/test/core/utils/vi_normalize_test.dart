import 'package:flutter_test/flutter_test.dart';
import 'package:vuon_nha/core/utils/vi_normalize.dart';

void main() {
  test('strips diacritics and lowercases', () {
    expect(viNormalize('Cây Lưỡi Hổ'), 'cay luoi ho');
    expect(viNormalize('Trầu Bà Đế Vương'), 'trau ba de vuong');
    expect(viNormalize('ĐƯỜNG'), 'duong');
    expect(viNormalize('đ'), 'd');
  });

  test('covers every vowel variant', () {
    expect(viNormalize('ắằẳẵặấầẩẫậ'), 'aaaaaaaaaa');
    expect(viNormalize('ếềểễệ'), 'eeeee');
    expect(viNormalize('ốồổỗộớờởỡợ'), 'oooooooooo');
    expect(viNormalize('ứừửữự'), 'uuuuu');
    expect(viNormalize('ýỳỷỹỵ'), 'yyyyy');
    expect(viNormalize('ỉĩịìí'), 'iiiii');
  });

  test('leaves ascii and empty untouched', () {
    expect(viNormalize('Monstera 123'), 'monstera 123');
    expect(viNormalize(''), '');
  });
}
