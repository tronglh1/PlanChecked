import 'provinces.dart';
import 'user_profile.dart';

enum ProfileError { nameEmpty, nameTooLong, provinceMissing, langInvalid }

class ProfileValidation {
  const ProfileValidation._();

  static Set<ProfileError> validate({
    required String displayName,
    required String? provinceCode,
    required String lang,
  }) {
    final errors = <ProfileError>{};
    final name = displayName.trim();
    if (name.isEmpty) errors.add(ProfileError.nameEmpty);
    if (name.length > kMaxDisplayNameLength) {
      errors.add(ProfileError.nameTooLong);
    }
    if (provinceByCode(provinceCode) == null) {
      errors.add(ProfileError.provinceMissing);
    }
    if (lang != 'vi' && lang != 'en') errors.add(ProfileError.langInvalid);
    return errors;
  }
}
