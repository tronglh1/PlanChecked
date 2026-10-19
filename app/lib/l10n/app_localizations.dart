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

  /// No description provided for @todayTitle.
  ///
  /// In vi, this message translates to:
  /// **'Hôm nay'**
  String get todayTitle;

  /// No description provided for @todayGreeting.
  ///
  /// In vi, this message translates to:
  /// **'Chào {name}'**
  String todayGreeting(String name);

  /// No description provided for @todayWd1.
  ///
  /// In vi, this message translates to:
  /// **'Thứ Hai'**
  String get todayWd1;

  /// No description provided for @todayWd2.
  ///
  /// In vi, this message translates to:
  /// **'Thứ Ba'**
  String get todayWd2;

  /// No description provided for @todayWd3.
  ///
  /// In vi, this message translates to:
  /// **'Thứ Tư'**
  String get todayWd3;

  /// No description provided for @todayWd4.
  ///
  /// In vi, this message translates to:
  /// **'Thứ Năm'**
  String get todayWd4;

  /// No description provided for @todayWd5.
  ///
  /// In vi, this message translates to:
  /// **'Thứ Sáu'**
  String get todayWd5;

  /// No description provided for @todayWd6.
  ///
  /// In vi, this message translates to:
  /// **'Thứ Bảy'**
  String get todayWd6;

  /// No description provided for @todayWd7.
  ///
  /// In vi, this message translates to:
  /// **'Chủ nhật'**
  String get todayWd7;

  /// No description provided for @todayProgress.
  ///
  /// In vi, this message translates to:
  /// **'Đã xong {done}/{total} việc'**
  String todayProgress(int done, int total);

  /// No description provided for @todayXpHint.
  ///
  /// In vi, this message translates to:
  /// **'+10 XP mỗi việc đúng hạn'**
  String get todayXpHint;

  /// No description provided for @todayXpChip.
  ///
  /// In vi, this message translates to:
  /// **'{xp} XP hôm nay'**
  String todayXpChip(int xp);

  /// No description provided for @todayGroupByWindow.
  ///
  /// In vi, this message translates to:
  /// **'Theo khung giờ'**
  String get todayGroupByWindow;

  /// No description provided for @todayGroupByProject.
  ///
  /// In vi, this message translates to:
  /// **'Theo project'**
  String get todayGroupByProject;

  /// No description provided for @todayWindowMorning.
  ///
  /// In vi, this message translates to:
  /// **'Sáng sớm · 6–8h'**
  String get todayWindowMorning;

  /// No description provided for @todayWindowAfternoon.
  ///
  /// In vi, this message translates to:
  /// **'Chiều mát · 16–18h'**
  String get todayWindowAfternoon;

  /// No description provided for @todayWindowAllDay.
  ///
  /// In vi, this message translates to:
  /// **'Cả ngày'**
  String get todayWindowAllDay;

  /// No description provided for @todayOverdue.
  ///
  /// In vi, this message translates to:
  /// **'Quá hạn'**
  String get todayOverdue;

  /// No description provided for @todayCheckinDueTitle.
  ///
  /// In vi, this message translates to:
  /// **'Đến hạn chụp ảnh check-in'**
  String get todayCheckinDueTitle;

  /// No description provided for @todayCheckinDueBody.
  ///
  /// In vi, this message translates to:
  /// **'{project} · +30 XP'**
  String todayCheckinDueBody(String project);

  /// No description provided for @todayEmptyTitle.
  ///
  /// In vi, this message translates to:
  /// **'Hôm nay chưa có việc'**
  String get todayEmptyTitle;

  /// No description provided for @todayEmptyBody.
  ///
  /// In vi, this message translates to:
  /// **'Trồng cây mới để nhận kế hoạch chăm sóc mỗi ngày.'**
  String get todayEmptyBody;

  /// No description provided for @todayLoadError.
  ///
  /// In vi, this message translates to:
  /// **'Không tải được việc hôm nay'**
  String get todayLoadError;

  /// No description provided for @todayOfflineBanner.
  ///
  /// In vi, this message translates to:
  /// **'Đang offline · {count} thay đổi sẽ đồng bộ khi có mạng'**
  String todayOfflineBanner(int count);

  /// No description provided for @todaySyncing.
  ///
  /// In vi, this message translates to:
  /// **'Đang đồng bộ...'**
  String get todaySyncing;

  /// No description provided for @todayPendingSync.
  ///
  /// In vi, this message translates to:
  /// **'Chờ đồng bộ'**
  String get todayPendingSync;

  /// No description provided for @todaySkippedLabel.
  ///
  /// In vi, this message translates to:
  /// **'Đã bỏ qua'**
  String get todaySkippedLabel;

  /// No description provided for @todayMarkDone.
  ///
  /// In vi, this message translates to:
  /// **'Đánh dấu xong'**
  String get todayMarkDone;

  /// No description provided for @todayMenu.
  ///
  /// In vi, this message translates to:
  /// **'Thêm tuỳ chọn'**
  String get todayMenu;

  /// No description provided for @todayXpToast.
  ///
  /// In vi, this message translates to:
  /// **'+{xp} XP'**
  String todayXpToast(int xp);

  /// No description provided for @todayXpToastLate.
  ///
  /// In vi, this message translates to:
  /// **'Đã xong · quá hạn nên không có XP'**
  String get todayXpToastLate;

  /// No description provided for @todayXpToastCap.
  ///
  /// In vi, this message translates to:
  /// **'Đã xong · hôm nay đã đủ 150 XP'**
  String get todayXpToastCap;

  /// No description provided for @todayActionError.
  ///
  /// In vi, this message translates to:
  /// **'Không lưu được thao tác'**
  String get todayActionError;

  /// No description provided for @todayPermTitle.
  ///
  /// In vi, this message translates to:
  /// **'Bật nhắc việc?'**
  String get todayPermTitle;

  /// No description provided for @todayPermBody.
  ///
  /// In vi, this message translates to:
  /// **'Vườn Nhà sẽ nhắc bạn đúng giờ chăm cây, kể cả khi không có mạng.'**
  String get todayPermBody;

  /// No description provided for @todayPermAllow.
  ///
  /// In vi, this message translates to:
  /// **'Bật nhắc việc'**
  String get todayPermAllow;

  /// No description provided for @todayPermLater.
  ///
  /// In vi, this message translates to:
  /// **'Để sau'**
  String get todayPermLater;

  /// No description provided for @todayNotifTitle.
  ///
  /// In vi, this message translates to:
  /// **'Đến giờ chăm cây · {window}'**
  String todayNotifTitle(String window);

  /// No description provided for @todayNotifMore.
  ///
  /// In vi, this message translates to:
  /// **'+{count} việc khác'**
  String todayNotifMore(int count);

  /// No description provided for @todayNotifDailyTitle.
  ///
  /// In vi, this message translates to:
  /// **'Hôm nay có {count} việc chăm cây'**
  String todayNotifDailyTitle(int count);

  /// No description provided for @todayNotifCheckinTitle.
  ///
  /// In vi, this message translates to:
  /// **'Đến hạn chụp ảnh check-in'**
  String get todayNotifCheckinTitle;

  /// No description provided for @todayNotifCheckinBody.
  ///
  /// In vi, this message translates to:
  /// **'Chụp ảnh {project} để cập nhật kế hoạch (+30 XP)'**
  String todayNotifCheckinBody(String project);

  /// No description provided for @taskSnooze.
  ///
  /// In vi, this message translates to:
  /// **'Dời lại'**
  String get taskSnooze;

  /// No description provided for @taskSkipTitle.
  ///
  /// In vi, this message translates to:
  /// **'Bỏ qua việc này?'**
  String get taskSkipTitle;

  /// No description provided for @taskSkipReasonHint.
  ///
  /// In vi, this message translates to:
  /// **'Lý do (không bắt buộc)'**
  String get taskSkipReasonHint;

  /// No description provided for @taskSkipReasonRain.
  ///
  /// In vi, this message translates to:
  /// **'Trời mưa'**
  String get taskSkipReasonRain;

  /// No description provided for @taskSkipReasonAway.
  ///
  /// In vi, this message translates to:
  /// **'Đang vắng nhà'**
  String get taskSkipReasonAway;

  /// No description provided for @taskSkipReasonNotNeeded.
  ///
  /// In vi, this message translates to:
  /// **'Cây chưa cần'**
  String get taskSkipReasonNotNeeded;

  /// No description provided for @taskSkipReasonOther.
  ///
  /// In vi, this message translates to:
  /// **'Khác'**
  String get taskSkipReasonOther;

  /// No description provided for @taskSkipConfirm.
  ///
  /// In vi, this message translates to:
  /// **'Bỏ qua'**
  String get taskSkipConfirm;

  /// No description provided for @taskSnoozeTitle.
  ///
  /// In vi, this message translates to:
  /// **'Dời lại đến khi nào?'**
  String get taskSnoozeTitle;

  /// No description provided for @taskSnoozeTomorrow.
  ///
  /// In vi, this message translates to:
  /// **'Ngày mai'**
  String get taskSnoozeTomorrow;

  /// No description provided for @taskSnooze2Days.
  ///
  /// In vi, this message translates to:
  /// **'2 ngày nữa'**
  String get taskSnooze2Days;

  /// No description provided for @taskSnoozeNextWeek.
  ///
  /// In vi, this message translates to:
  /// **'Tuần sau'**
  String get taskSnoozeNextWeek;

  /// No description provided for @taskTileWindow.
  ///
  /// In vi, this message translates to:
  /// **'Khung giờ'**
  String get taskTileWindow;

  /// No description provided for @taskTileFrequency.
  ///
  /// In vi, this message translates to:
  /// **'Lặp lại'**
  String get taskTileFrequency;

  /// No description provided for @taskTileReminder.
  ///
  /// In vi, this message translates to:
  /// **'Nhắc lúc'**
  String get taskTileReminder;

  /// No description provided for @taskFreqOnce.
  ///
  /// In vi, this message translates to:
  /// **'Một lần'**
  String get taskFreqOnce;

  /// No description provided for @taskFreqDaily.
  ///
  /// In vi, this message translates to:
  /// **'Hằng ngày'**
  String get taskFreqDaily;

  /// No description provided for @taskFreqEveryN.
  ///
  /// In vi, this message translates to:
  /// **'{n} ngày/lần'**
  String taskFreqEveryN(int n);

  /// No description provided for @taskFreqFixed.
  ///
  /// In vi, this message translates to:
  /// **'Ngày {n}'**
  String taskFreqFixed(int n);

  /// No description provided for @taskReminderByWindow.
  ///
  /// In vi, this message translates to:
  /// **'Theo khung giờ'**
  String get taskReminderByWindow;

  /// No description provided for @taskAssignedTo.
  ///
  /// In vi, this message translates to:
  /// **'Giao cho {name}'**
  String taskAssignedTo(String name);

  /// No description provided for @taskUnassigned.
  ///
  /// In vi, this message translates to:
  /// **'Chưa giao ai'**
  String get taskUnassigned;

  /// No description provided for @taskChange.
  ///
  /// In vi, this message translates to:
  /// **'Đổi'**
  String get taskChange;

  /// No description provided for @taskAssign.
  ///
  /// In vi, this message translates to:
  /// **'Giao việc'**
  String get taskAssign;

  /// No description provided for @taskHowTo.
  ///
  /// In vi, this message translates to:
  /// **'Cách làm'**
  String get taskHowTo;

  /// No description provided for @taskWhy.
  ///
  /// In vi, this message translates to:
  /// **'Vì sao?'**
  String get taskWhy;

  /// No description provided for @taskNoSteps.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có hướng dẫn chi tiết cho việc này.'**
  String get taskNoSteps;

  /// No description provided for @taskSafetyGeneric.
  ///
  /// In vi, this message translates to:
  /// **'Nếu dùng phân bón hoặc thuốc đóng gói, làm theo liều trên nhãn sản phẩm. App không đưa liều hóa chất cụ thể.'**
  String get taskSafetyGeneric;

  /// No description provided for @taskHistory.
  ///
  /// In vi, this message translates to:
  /// **'Lịch sử'**
  String get taskHistory;

  /// No description provided for @taskHistoryEmpty.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có lịch sử'**
  String get taskHistoryEmpty;

  /// No description provided for @taskHistoryDone.
  ///
  /// In vi, this message translates to:
  /// **'Xong'**
  String get taskHistoryDone;

  /// No description provided for @taskHistorySkip.
  ///
  /// In vi, this message translates to:
  /// **'Bỏ qua'**
  String get taskHistorySkip;

  /// No description provided for @taskHistorySnooze.
  ///
  /// In vi, this message translates to:
  /// **'Dời lại'**
  String get taskHistorySnooze;

  /// No description provided for @taskDoneButton.
  ///
  /// In vi, this message translates to:
  /// **'Xong · +{xp} XP'**
  String taskDoneButton(int xp);

  /// No description provided for @taskNotDueToday.
  ///
  /// In vi, this message translates to:
  /// **'Việc này không đến hạn hôm nay'**
  String get taskNotDueToday;

  /// No description provided for @taskNotFound.
  ///
  /// In vi, this message translates to:
  /// **'Không tìm thấy việc này'**
  String get taskNotFound;

  /// No description provided for @taskAssignPlaceholder.
  ///
  /// In vi, this message translates to:
  /// **'Giao việc cho thành viên sẽ có ở bản sau.'**
  String get taskAssignPlaceholder;

  /// No description provided for @taskCheckinPlaceholder.
  ///
  /// In vi, this message translates to:
  /// **'Chụp ảnh check-in sẽ có ở bản sau.'**
  String get taskCheckinPlaceholder;
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
