import 'provinces.dart';

/// `experience` enum (spec §4.1).
enum Experience {
  beginner('new'),
  intermediate('mid'),
  pro('pro');

  const Experience(this.code);
  final String code;

  static Experience fromCode(String? code) => Experience.values.firstWhere(
    (e) => e.code == code,
    orElse: () => Experience.beginner,
  );
}

const String kDefaultTimezone = 'Asia/Ho_Chi_Minh';
const int kMaxDisplayNameLength = 50;

/// Row of the public `users` table (only the columns the app edits).
class UserProfile {
  const UserProfile({
    required this.id,
    required this.displayName,
    this.avatarPath,
    this.lang = 'vi',
    this.timezone = kDefaultTimezone,
    this.provinceCode,
    this.experience = Experience.beginner,
  });

  final String id;
  final String displayName;
  final String? avatarPath;
  final String lang; // `lang` enum: vi | en
  final String timezone;
  final String? provinceCode;
  final Experience experience;

  /// A profile is complete once it has a name and a province.
  bool get isComplete =>
      displayName.trim().isNotEmpty && provinceByCode(provinceCode) != null;

  UserProfile copyWith({
    String? displayName,
    String? avatarPath,
    String? lang,
    String? timezone,
    String? provinceCode,
    Experience? experience,
  }) => UserProfile(
    id: id,
    displayName: displayName ?? this.displayName,
    avatarPath: avatarPath ?? this.avatarPath,
    lang: lang ?? this.lang,
    timezone: timezone ?? this.timezone,
    provinceCode: provinceCode ?? this.provinceCode,
    experience: experience ?? this.experience,
  );

  factory UserProfile.fromRow(Map<String, dynamic> row) => UserProfile(
    id: row['id'] as String,
    displayName: (row['display_name'] as String?) ?? '',
    avatarPath: row['avatar_path'] as String?,
    lang: (row['lang'] as String?) == 'en' ? 'en' : 'vi',
    timezone: (row['timezone'] as String?) ?? kDefaultTimezone,
    provinceCode: row['province_code'] as String?,
    experience: Experience.fromCode(row['experience'] as String?),
  );

  Map<String, dynamic> toRow() => {
    'id': id,
    'display_name': displayName.trim(),
    'avatar_path': avatarPath,
    'lang': lang,
    'timezone': timezone,
    'province_code': provinceCode,
    'experience': experience.code,
  };
}
