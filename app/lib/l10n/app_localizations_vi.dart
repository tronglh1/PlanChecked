// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Vietnamese (`vi`).
class AppLocalizationsVi extends AppLocalizations {
  AppLocalizationsVi([String locale = 'vi']) : super(locale);

  @override
  String get appName => 'Vườn Nhà';

  @override
  String get tabToday => 'Hôm nay';

  @override
  String get tabGarden => 'Vườn';

  @override
  String get tabFamily => 'Gia đình';

  @override
  String get tabAchievements => 'Thành tích';

  @override
  String get tabSettings => 'Cài đặt';

  @override
  String get commonDone => 'Xong';

  @override
  String get commonSkip => 'Bỏ qua';

  @override
  String get commonSnooze => 'Hoãn';

  @override
  String get commonCancel => 'Huỷ';

  @override
  String get commonSave => 'Lưu';

  @override
  String get commonContinue => 'Tiếp tục';

  @override
  String get commonRetry => 'Thử lại';

  @override
  String get commonLoading => 'Đang tải...';

  @override
  String get commonError => 'Đã có lỗi xảy ra';

  @override
  String get emptyTitle => 'Chưa có gì ở đây';

  @override
  String get loginTitle => 'Đăng nhập';

  @override
  String get loginPlaceholder => 'Màn hình đăng nhập sẽ sớm có mặt.';

  @override
  String get onboardingTitle => 'Chào mừng đến Vườn Nhà';

  @override
  String get onboardingPlaceholder => 'Hướng dẫn làm quen sẽ sớm có mặt.';

  @override
  String get configErrorTitle => 'Thiếu cấu hình';

  @override
  String get configErrorMessage =>
      'Chưa có SUPABASE_URL / SUPABASE_ANON_KEY. Chạy app với --dart-define-from-file=env/dev.json.';

  @override
  String get placeholderComingSoon => 'Sắp ra mắt';
}
