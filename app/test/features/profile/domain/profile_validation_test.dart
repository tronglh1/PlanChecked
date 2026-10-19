import 'package:flutter_test/flutter_test.dart';
import 'package:vuon_nha/features/auth/domain/auth_validation.dart';
import 'package:vuon_nha/features/profile/domain/profile_validation.dart';
import 'package:vuon_nha/features/profile/domain/provinces.dart';
import 'package:vuon_nha/features/profile/domain/user_profile.dart';

void main() {
  group('ProfileValidation', () {
    test('valid input has no errors', () {
      expect(
        ProfileValidation.validate(
          displayName: 'Minh',
          provinceCode: 'tp-hcm',
          lang: 'vi',
        ),
        isEmpty,
      );
    });

    test('empty / blank name', () {
      for (final n in ['', '   ']) {
        expect(
          ProfileValidation.validate(
            displayName: n,
            provinceCode: 'ha-noi',
            lang: 'en',
          ),
          {ProfileError.nameEmpty},
        );
      }
    });

    test('name too long', () {
      expect(
        ProfileValidation.validate(
          displayName: 'a' * (kMaxDisplayNameLength + 1),
          provinceCode: 'ha-noi',
          lang: 'vi',
        ),
        {ProfileError.nameTooLong},
      );
    });

    test('province required and must exist; lang must be vi/en', () {
      expect(
        ProfileValidation.validate(
          displayName: 'A',
          provinceCode: null,
          lang: 'fr',
        ),
        {ProfileError.provinceMissing, ProfileError.langInvalid},
      );
      expect(
        ProfileValidation.validate(
          displayName: 'A',
          provinceCode: 'atlantis',
          lang: 'vi',
        ),
        {ProfileError.provinceMissing},
      );
    });
  });

  group('provinces', () {
    test('34 unique provincial units', () {
      expect(kProvinces.length, 34);
      expect(kProvinces.map((p) => p.code).toSet().length, 34);
      expect(provinceByCode('tp-hcm')?.name, 'TP. Hồ Chí Minh');
    });
  });

  group('UserProfile', () {
    test('isComplete needs name and valid province', () {
      const base = UserProfile(id: 'u', displayName: 'A', provinceCode: 'hue');
      expect(base.isComplete, isTrue);
      expect(base.copyWith(displayName: ' ').isComplete, isFalse);
      expect(const UserProfile(id: 'u', displayName: 'A').isComplete, isFalse);
    });

    test('row round trip uses users column names', () {
      const p = UserProfile(
        id: 'u',
        displayName: ' Minh ',
        lang: 'en',
        provinceCode: 'ha-noi',
        experience: Experience.pro,
      );
      final row = p.toRow();
      expect(row['display_name'], 'Minh');
      expect(row['province_code'], 'ha-noi');
      expect(row['experience'], 'pro');
      expect(row['timezone'], 'Asia/Ho_Chi_Minh');
      final back = UserProfile.fromRow(row);
      expect(back.lang, 'en');
      expect(back.experience, Experience.pro);
    });
  });

  group('AuthValidation', () {
    test('email', () {
      expect(AuthValidation.isValidEmail('ban@email.com'), isTrue);
      expect(AuthValidation.isValidEmail(' ban@email.com '), isTrue);
      expect(AuthValidation.isValidEmail('ban@email'), isFalse);
      expect(AuthValidation.isValidEmail('ban email@x.com'), isFalse);
      expect(AuthValidation.isValidEmail(''), isFalse);
    });

    test('otp is exactly 6 digits', () {
      expect(AuthValidation.isValidOtp('123456'), isTrue);
      expect(AuthValidation.isValidOtp('12345'), isFalse);
      expect(AuthValidation.isValidOtp('1234567'), isFalse);
      expect(AuthValidation.isValidOtp('12a456'), isFalse);
    });
  });
}
