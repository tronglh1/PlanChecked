import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_vi.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('vi'),
  ];

  /// No description provided for @appName.
  ///
  /// In vi, this message translates to:
  /// **'Vườn Nhà'**
  String get appName;

  /// No description provided for @tabToday.
  ///
  /// In vi, this message translates to:
  /// **'Hôm nay'**
  String get tabToday;

  /// No description provided for @tabGarden.
  ///
  /// In vi, this message translates to:
  /// **'Vườn'**
  String get tabGarden;

  /// No description provided for @tabFamily.
  ///
  /// In vi, this message translates to:
  /// **'Gia đình'**
  String get tabFamily;

  /// No description provided for @tabAchievements.
  ///
  /// In vi, this message translates to:
  /// **'Thành tích'**
  String get tabAchievements;

  /// No description provided for @tabSettings.
  ///
  /// In vi, this message translates to:
  /// **'Cài đặt'**
  String get tabSettings;

  /// No description provided for @commonDone.
  ///
  /// In vi, this message translates to:
  /// **'Xong'**
  String get commonDone;

  /// No description provided for @commonSkip.
  ///
  /// In vi, this message translates to:
  /// **'Bỏ qua'**
  String get commonSkip;

  /// No description provided for @commonSnooze.
  ///
  /// In vi, this message translates to:
  /// **'Hoãn'**
  String get commonSnooze;

  /// No description provided for @commonCancel.
  ///
  /// In vi, this message translates to:
  /// **'Huỷ'**
  String get commonCancel;

  /// No description provided for @commonSave.
  ///
  /// In vi, this message translates to:
  /// **'Lưu'**
  String get commonSave;

  /// No description provided for @commonContinue.
  ///
  /// In vi, this message translates to:
  /// **'Tiếp tục'**
  String get commonContinue;

  /// No description provided for @commonRetry.
  ///
  /// In vi, this message translates to:
  /// **'Thử lại'**
  String get commonRetry;

  /// No description provided for @commonLoading.
  ///
  /// In vi, this message translates to:
  /// **'Đang tải...'**
  String get commonLoading;

  /// No description provided for @commonError.
  ///
  /// In vi, this message translates to:
  /// **'Đã có lỗi xảy ra'**
  String get commonError;

  /// No description provided for @emptyTitle.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có gì ở đây'**
  String get emptyTitle;

  /// No description provided for @loginTitle.
  ///
  /// In vi, this message translates to:
  /// **'Đăng nhập'**
  String get loginTitle;

  /// No description provided for @configErrorTitle.
  ///
  /// In vi, this message translates to:
  /// **'Thiếu cấu hình'**
  String get configErrorTitle;

  /// No description provided for @configErrorMessage.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có SUPABASE_URL / SUPABASE_ANON_KEY. Chạy app với --dart-define-from-file=env/dev.json.'**
  String get configErrorMessage;

  /// No description provided for @placeholderComingSoon.
  ///
  /// In vi, this message translates to:
  /// **'Sắp ra mắt'**
  String get placeholderComingSoon;

  /// No description provided for @loginTagline.
  ///
  /// In vi, this message translates to:
  /// **'Kế hoạch chăm cây do AI lập riêng cho bạn, việc mỗi ngày rõ ràng, cả nhà cùng chăm.'**
  String get loginTagline;

  /// No description provided for @loginGoogle.
  ///
  /// In vi, this message translates to:
  /// **'Tiếp tục với Google'**
  String get loginGoogle;

  /// No description provided for @loginOr.
  ///
  /// In vi, this message translates to:
  /// **'hoặc'**
  String get loginOr;

  /// No description provided for @loginEmailLabel.
  ///
  /// In vi, this message translates to:
  /// **'Email'**
  String get loginEmailLabel;

  /// No description provided for @loginEmailHint.
  ///
  /// In vi, this message translates to:
  /// **'ban@email.com'**
  String get loginEmailHint;

  /// No description provided for @loginSendCode.
  ///
  /// In vi, this message translates to:
  /// **'Nhận mã đăng nhập'**
  String get loginSendCode;

  /// No description provided for @loginEmailInvalid.
  ///
  /// In vi, this message translates to:
  /// **'Email chưa hợp lệ'**
  String get loginEmailInvalid;

  /// No description provided for @loginOtpTitle.
  ///
  /// In vi, this message translates to:
  /// **'Nhập mã xác nhận'**
  String get loginOtpTitle;

  /// No description provided for @loginOtpSent.
  ///
  /// In vi, this message translates to:
  /// **'Chúng tôi đã gửi mã 6 số tới {email}'**
  String loginOtpSent(String email);

  /// No description provided for @loginOtpLabel.
  ///
  /// In vi, this message translates to:
  /// **'Mã 6 số'**
  String get loginOtpLabel;

  /// No description provided for @loginOtpVerify.
  ///
  /// In vi, this message translates to:
  /// **'Xác nhận'**
  String get loginOtpVerify;

  /// No description provided for @loginOtpInvalid.
  ///
  /// In vi, this message translates to:
  /// **'Mã gồm 6 chữ số'**
  String get loginOtpInvalid;

  /// No description provided for @loginOtpWrong.
  ///
  /// In vi, this message translates to:
  /// **'Mã không đúng hoặc đã hết hạn'**
  String get loginOtpWrong;

  /// No description provided for @loginResend.
  ///
  /// In vi, this message translates to:
  /// **'Gửi lại mã'**
  String get loginResend;

  /// No description provided for @loginChangeEmail.
  ///
  /// In vi, this message translates to:
  /// **'Đổi email'**
  String get loginChangeEmail;

  /// No description provided for @loginError.
  ///
  /// In vi, this message translates to:
  /// **'Không đăng nhập được. Vui lòng thử lại.'**
  String get loginError;

  /// No description provided for @loginTermsPrefix.
  ///
  /// In vi, this message translates to:
  /// **'Tiếp tục nghĩa là bạn đồng ý với '**
  String get loginTermsPrefix;

  /// No description provided for @loginTerms.
  ///
  /// In vi, this message translates to:
  /// **'Điều khoản'**
  String get loginTerms;

  /// No description provided for @loginTermsAnd.
  ///
  /// In vi, this message translates to:
  /// **' và '**
  String get loginTermsAnd;

  /// No description provided for @loginPrivacy.
  ///
  /// In vi, this message translates to:
  /// **'Chính sách dữ liệu'**
  String get loginPrivacy;

  /// No description provided for @loginTermsSuffix.
  ///
  /// In vi, this message translates to:
  /// **' (theo Nghị định 13/2023/NĐ-CP).'**
  String get loginTermsSuffix;

  /// No description provided for @profileStep.
  ///
  /// In vi, this message translates to:
  /// **'Bước 1/2'**
  String get profileStep;

  /// No description provided for @profileTitle.
  ///
  /// In vi, this message translates to:
  /// **'Giới thiệu một chút về bạn'**
  String get profileTitle;

  /// No description provided for @profileSub.
  ///
  /// In vi, this message translates to:
  /// **'Vị trí giúp AI tính khí hậu và mùa vụ. App chỉ lưu ở mức tỉnh/thành.'**
  String get profileSub;

  /// No description provided for @profileChangeAvatar.
  ///
  /// In vi, this message translates to:
  /// **'Đổi ảnh đại diện'**
  String get profileChangeAvatar;

  /// No description provided for @profileNameLabel.
  ///
  /// In vi, this message translates to:
  /// **'Tên hiển thị'**
  String get profileNameLabel;

  /// No description provided for @profileLocationLabel.
  ///
  /// In vi, this message translates to:
  /// **'Bạn trồng cây ở đâu?'**
  String get profileLocationLabel;

  /// No description provided for @profileLocationHint.
  ///
  /// In vi, this message translates to:
  /// **'Chọn tỉnh/thành'**
  String get profileLocationHint;

  /// No description provided for @profileProvinceSearch.
  ///
  /// In vi, this message translates to:
  /// **'Tìm tỉnh/thành'**
  String get profileProvinceSearch;

  /// No description provided for @regionHelperSouth.
  ///
  /// In vi, this message translates to:
  /// **'Khí hậu nhiệt đới, mùa mưa tháng 5–11'**
  String get regionHelperSouth;

  /// No description provided for @regionHelperNorth.
  ///
  /// In vi, this message translates to:
  /// **'Bốn mùa rõ rệt, mùa đông lạnh'**
  String get regionHelperNorth;

  /// No description provided for @regionHelperCentral.
  ///
  /// In vi, this message translates to:
  /// **'Nắng nóng, mưa nhiều vào cuối năm'**
  String get regionHelperCentral;

  /// No description provided for @profileExperience.
  ///
  /// In vi, this message translates to:
  /// **'Kinh nghiệm trồng cây'**
  String get profileExperience;

  /// No description provided for @expNew.
  ///
  /// In vi, this message translates to:
  /// **'Mới bắt đầu'**
  String get expNew;

  /// No description provided for @expMid.
  ///
  /// In vi, this message translates to:
  /// **'Trung bình'**
  String get expMid;

  /// No description provided for @expPro.
  ///
  /// In vi, this message translates to:
  /// **'Thành thạo'**
  String get expPro;

  /// No description provided for @profileLanguage.
  ///
  /// In vi, this message translates to:
  /// **'Ngôn ngữ'**
  String get profileLanguage;

  /// No description provided for @langVi.
  ///
  /// In vi, this message translates to:
  /// **'Tiếng Việt'**
  String get langVi;

  /// No description provided for @langEn.
  ///
  /// In vi, this message translates to:
  /// **'English'**
  String get langEn;

  /// No description provided for @errorNameEmpty.
  ///
  /// In vi, this message translates to:
  /// **'Hãy nhập tên hiển thị'**
  String get errorNameEmpty;

  /// No description provided for @errorNameTooLong.
  ///
  /// In vi, this message translates to:
  /// **'Tên tối đa 50 ký tự'**
  String get errorNameTooLong;

  /// No description provided for @errorProvince.
  ///
  /// In vi, this message translates to:
  /// **'Hãy chọn tỉnh/thành'**
  String get errorProvince;

  /// No description provided for @profileSaveError.
  ///
  /// In vi, this message translates to:
  /// **'Không lưu được hồ sơ. Vui lòng thử lại.'**
  String get profileSaveError;

  /// No description provided for @settingsEdit.
  ///
  /// In vi, this message translates to:
  /// **'Sửa'**
  String get settingsEdit;

  /// No description provided for @settingsNotifications.
  ///
  /// In vi, this message translates to:
  /// **'THÔNG BÁO'**
  String get settingsNotifications;

  /// No description provided for @notifTask.
  ///
  /// In vi, this message translates to:
  /// **'Nhắc việc chăm cây'**
  String get notifTask;

  /// No description provided for @notifCheckin.
  ///
  /// In vi, this message translates to:
  /// **'Nhắc chụp check-in'**
  String get notifCheckin;

  /// No description provided for @notifAssignment.
  ///
  /// In vi, this message translates to:
  /// **'Được giao việc'**
  String get notifAssignment;

  /// No description provided for @notifAchievement.
  ///
  /// In vi, this message translates to:
  /// **'Thành tích & huy hiệu'**
  String get notifAchievement;

  /// No description provided for @notifBundle.
  ///
  /// In vi, this message translates to:
  /// **'Gộp thông báo thành 1 lần/ngày'**
  String get notifBundle;

  /// No description provided for @settingsOther.
  ///
  /// In vi, this message translates to:
  /// **'KHÁC'**
  String get settingsOther;

  /// No description provided for @settingsLanguage.
  ///
  /// In vi, this message translates to:
  /// **'Ngôn ngữ'**
  String get settingsLanguage;

  /// No description provided for @settingsLeaveHousehold.
  ///
  /// In vi, this message translates to:
  /// **'Rời gia đình'**
  String get settingsLeaveHousehold;

  /// No description provided for @settingsSignOut.
  ///
  /// In vi, this message translates to:
  /// **'Đăng xuất'**
  String get settingsSignOut;

  /// No description provided for @settingsDeleteAccount.
  ///
  /// In vi, this message translates to:
  /// **'Xóa tài khoản và toàn bộ dữ liệu'**
  String get settingsDeleteAccount;

  /// No description provided for @deleteConfirm1Title.
  ///
  /// In vi, this message translates to:
  /// **'Xóa tài khoản?'**
  String get deleteConfirm1Title;

  /// No description provided for @deleteConfirm1Body.
  ///
  /// In vi, this message translates to:
  /// **'Toàn bộ dự án, check-in, ảnh và thành tích của bạn sẽ bị xóa.'**
  String get deleteConfirm1Body;

  /// No description provided for @deleteConfirm2Title.
  ///
  /// In vi, this message translates to:
  /// **'Bạn chắc chắn chứ?'**
  String get deleteConfirm2Title;

  /// No description provided for @deleteConfirm2Body.
  ///
  /// In vi, this message translates to:
  /// **'Hành động này không thể hoàn tác.'**
  String get deleteConfirm2Body;

  /// No description provided for @deleteConfirmAction.
  ///
  /// In vi, this message translates to:
  /// **'Xóa vĩnh viễn'**
  String get deleteConfirmAction;

  /// No description provided for @deleteError.
  ///
  /// In vi, this message translates to:
  /// **'Không xóa được tài khoản. Vui lòng thử lại.'**
  String get deleteError;

  /// No description provided for @searchEyebrow.
  ///
  /// In vi, this message translates to:
  /// **'Trồng cây mới · Bước 1/3'**
  String get searchEyebrow;

  /// No description provided for @searchTitle.
  ///
  /// In vi, this message translates to:
  /// **'Bạn muốn trồng cây gì?'**
  String get searchTitle;

  /// No description provided for @searchFieldLabel.
  ///
  /// In vi, this message translates to:
  /// **'Tên cây'**
  String get searchFieldLabel;

  /// No description provided for @filterAll.
  ///
  /// In vi, this message translates to:
  /// **'Tất cả'**
  String get filterAll;

  /// No description provided for @filterVeg.
  ///
  /// In vi, this message translates to:
  /// **'Rau & quả'**
  String get filterVeg;

  /// No description provided for @filterOrnamental.
  ///
  /// In vi, this message translates to:
  /// **'Cây cảnh trong nhà'**
  String get filterOrnamental;

  /// No description provided for @searchCount.
  ///
  /// In vi, this message translates to:
  /// **'{count} kết quả cho “{query}”'**
  String searchCount(int count, String query);

  /// No description provided for @searchCountAll.
  ///
  /// In vi, this message translates to:
  /// **'{count} loại cây'**
  String searchCountAll(int count);

  /// No description provided for @diffEasy.
  ///
  /// In vi, this message translates to:
  /// **'Dễ'**
  String get diffEasy;

  /// No description provided for @diffMedium.
  ///
  /// In vi, this message translates to:
  /// **'Trung bình'**
  String get diffMedium;

  /// No description provided for @diffHard.
  ///
  /// In vi, this message translates to:
  /// **'Khó'**
  String get diffHard;

  /// No description provided for @harvestDays.
  ///
  /// In vi, this message translates to:
  /// **'Thu hoạch ~{days} ngày'**
  String harvestDays(int days);

  /// No description provided for @searchNotFoundTitle.
  ///
  /// In vi, this message translates to:
  /// **'Không thấy cây bạn cần?'**
  String get searchNotFoundTitle;

  /// No description provided for @searchDidYouMean.
  ///
  /// In vi, this message translates to:
  /// **'Bạn gõ “{query}”. Có phải bạn muốn nói…?'**
  String searchDidYouMean(String query);

  /// No description provided for @searchYes.
  ///
  /// In vi, this message translates to:
  /// **'Đúng rồi'**
  String get searchYes;

  /// No description provided for @searchNo.
  ///
  /// In vi, this message translates to:
  /// **'Không phải'**
  String get searchNo;

  /// No description provided for @searchFreeText.
  ///
  /// In vi, this message translates to:
  /// **'Dùng “{query}”'**
  String searchFreeText(String query);

  /// No description provided for @searchFreeTextHint.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có trong danh sách? AI sẽ lập kế hoạch cho cây này ở bước sau.'**
  String get searchFreeTextHint;

  /// No description provided for @searchLoadError.
  ///
  /// In vi, this message translates to:
  /// **'Không tải được danh sách cây'**
  String get searchLoadError;

  /// No description provided for @contextTitle.
  ///
  /// In vi, this message translates to:
  /// **'Thông tin & bối cảnh trồng'**
  String get contextTitle;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'vi'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'vi':
      return AppLocalizationsVi();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
