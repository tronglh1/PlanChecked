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

  /// No description provided for @householdSetupStep.
  ///
  /// In vi, this message translates to:
  /// **'Bước 2/2'**
  String get householdSetupStep;

  /// No description provided for @householdSetupSkip.
  ///
  /// In vi, this message translates to:
  /// **'Bỏ qua'**
  String get householdSetupSkip;

  /// No description provided for @householdSetupTitle.
  ///
  /// In vi, this message translates to:
  /// **'Chăm cây cùng người nhà?'**
  String get householdSetupTitle;

  /// No description provided for @householdSetupSub.
  ///
  /// In vi, this message translates to:
  /// **'Tạo gia đình để giao việc tưới, bón cho từng người và xem ai đã làm gì. Bạn có thể làm việc này sau.'**
  String get householdSetupSub;

  /// No description provided for @householdCreateTitle.
  ///
  /// In vi, this message translates to:
  /// **'Tạo gia đình mới'**
  String get householdCreateTitle;

  /// No description provided for @householdCreateSub.
  ///
  /// In vi, this message translates to:
  /// **'Bạn là chủ nhà (Owner)'**
  String get householdCreateSub;

  /// No description provided for @householdJoinTitle.
  ///
  /// In vi, this message translates to:
  /// **'Tham gia bằng mã mời'**
  String get householdJoinTitle;

  /// No description provided for @householdJoinSub.
  ///
  /// In vi, this message translates to:
  /// **'Bạn sẽ là thành viên (Member)'**
  String get householdJoinSub;

  /// No description provided for @householdJoinHint.
  ///
  /// In vi, this message translates to:
  /// **'VD: VUON-4821'**
  String get householdJoinHint;

  /// No description provided for @householdJoinAction.
  ///
  /// In vi, this message translates to:
  /// **'Vào'**
  String get householdJoinAction;

  /// No description provided for @householdSetupFooter.
  ///
  /// In vi, this message translates to:
  /// **'Mỗi người chỉ ở trong một gia đình. App không có kết bạn công khai.'**
  String get householdSetupFooter;

  /// No description provided for @householdNameLabel.
  ///
  /// In vi, this message translates to:
  /// **'Tên gia đình'**
  String get householdNameLabel;

  /// No description provided for @householdNameDefault.
  ///
  /// In vi, this message translates to:
  /// **'Nhà mình'**
  String get householdNameDefault;

  /// No description provided for @householdCreateAction.
  ///
  /// In vi, this message translates to:
  /// **'Tạo gia đình'**
  String get householdCreateAction;

  /// No description provided for @householdErrorGeneric.
  ///
  /// In vi, this message translates to:
  /// **'Chưa thực hiện được. Thử lại nhé.'**
  String get householdErrorGeneric;

  /// No description provided for @householdErrorInvalidCode.
  ///
  /// In vi, this message translates to:
  /// **'Mã mời không đúng'**
  String get householdErrorInvalidCode;

  /// No description provided for @householdErrorExpired.
  ///
  /// In vi, this message translates to:
  /// **'Mã mời đã hết hạn'**
  String get householdErrorExpired;

  /// No description provided for @householdErrorAlreadyIn.
  ///
  /// In vi, this message translates to:
  /// **'Bạn đã ở trong một gia đình'**
  String get householdErrorAlreadyIn;

  /// No description provided for @householdErrorTooMany.
  ///
  /// In vi, this message translates to:
  /// **'Nhập sai quá nhiều lần, thử lại sau 1 giờ'**
  String get householdErrorTooMany;

  /// No description provided for @householdErrorCodeFormat.
  ///
  /// In vi, this message translates to:
  /// **'Mã có dạng VUON-1234'**
  String get householdErrorCodeFormat;

  /// No description provided for @householdJoined.
  ///
  /// In vi, this message translates to:
  /// **'Đã tham gia gia đình'**
  String get householdJoined;

  /// No description provided for @householdEyebrow.
  ///
  /// In vi, this message translates to:
  /// **'Gia đình · {count} người'**
  String householdEyebrow(int count);

  /// No description provided for @householdInvite.
  ///
  /// In vi, this message translates to:
  /// **'+ Mời'**
  String get householdInvite;

  /// No description provided for @householdRoleOwner.
  ///
  /// In vi, this message translates to:
  /// **'Owner'**
  String get householdRoleOwner;

  /// No description provided for @householdRoleMember.
  ///
  /// In vi, this message translates to:
  /// **'Member'**
  String get householdRoleMember;

  /// No description provided for @householdYou.
  ///
  /// In vi, this message translates to:
  /// **'{name} (bạn)'**
  String householdYou(String name);

  /// No description provided for @householdTasksWeek.
  ///
  /// In vi, this message translates to:
  /// **'{count} việc tuần này'**
  String householdTasksWeek(int count);

  /// No description provided for @householdAway.
  ///
  /// In vi, this message translates to:
  /// **'đang vắng nhà'**
  String get householdAway;

  /// No description provided for @householdSharedProjects.
  ///
  /// In vi, this message translates to:
  /// **'Project chia sẻ'**
  String get householdSharedProjects;

  /// No description provided for @householdNoShared.
  ///
  /// In vi, this message translates to:
  /// **'Chưa chia sẻ project nào'**
  String get householdNoShared;

  /// No description provided for @householdShareMore.
  ///
  /// In vi, this message translates to:
  /// **'+ Chia sẻ thêm'**
  String get householdShareMore;

  /// No description provided for @householdShareTitle.
  ///
  /// In vi, this message translates to:
  /// **'Chia sẻ project với gia đình'**
  String get householdShareTitle;

  /// No description provided for @householdShare.
  ///
  /// In vi, this message translates to:
  /// **'Chia sẻ'**
  String get householdShare;

  /// No description provided for @householdUnshare.
  ///
  /// In vi, this message translates to:
  /// **'Ngừng chia sẻ'**
  String get householdUnshare;

  /// No description provided for @householdShareOwnerOnly.
  ///
  /// In vi, this message translates to:
  /// **'Chỉ Owner mới chia sẻ được project'**
  String get householdShareOwnerOnly;

  /// No description provided for @householdShareNoProjects.
  ///
  /// In vi, this message translates to:
  /// **'Bạn chưa có project nào để chia sẻ'**
  String get householdShareNoProjects;

  /// No description provided for @householdActivity.
  ///
  /// In vi, this message translates to:
  /// **'Hoạt động'**
  String get householdActivity;

  /// No description provided for @householdActivityEmpty.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có hoạt động nào'**
  String get householdActivityEmpty;

  /// No description provided for @householdActTaskDone.
  ///
  /// In vi, this message translates to:
  /// **'{name} đã hoàn thành một việc'**
  String householdActTaskDone(String name);

  /// No description provided for @householdActCheckin.
  ///
  /// In vi, this message translates to:
  /// **'{name} đã check-in ảnh'**
  String householdActCheckin(String name);

  /// No description provided for @householdActMilestone.
  ///
  /// In vi, this message translates to:
  /// **'{name} đạt mốc mới'**
  String householdActMilestone(String name);

  /// No description provided for @householdActJoined.
  ///
  /// In vi, this message translates to:
  /// **'{name} đã tham gia gia đình'**
  String householdActJoined(String name);

  /// No description provided for @householdActLeft.
  ///
  /// In vi, this message translates to:
  /// **'{name} đã rời gia đình'**
  String householdActLeft(String name);

  /// No description provided for @householdActShared.
  ///
  /// In vi, this message translates to:
  /// **'{name} chia sẻ project “{project}”'**
  String householdActShared(String name, String project);

  /// No description provided for @householdActProject.
  ///
  /// In vi, this message translates to:
  /// **'{text} · {project}'**
  String householdActProject(String text, String project);

  /// No description provided for @householdSomeone.
  ///
  /// In vi, this message translates to:
  /// **'Một thành viên'**
  String get householdSomeone;

  /// No description provided for @householdRemoveMember.
  ///
  /// In vi, this message translates to:
  /// **'Xóa khỏi gia đình'**
  String get householdRemoveMember;

  /// No description provided for @householdRemoveTitle.
  ///
  /// In vi, this message translates to:
  /// **'Xóa {name} khỏi gia đình?'**
  String householdRemoveTitle(String name);

  /// No description provided for @householdRemoveBody.
  ///
  /// In vi, this message translates to:
  /// **'Project họ chia sẻ sẽ trở lại riêng tư.'**
  String get householdRemoveBody;

  /// No description provided for @householdLoadError.
  ///
  /// In vi, this message translates to:
  /// **'Không tải được gia đình'**
  String get householdLoadError;

  /// No description provided for @householdNoneTitle.
  ///
  /// In vi, this message translates to:
  /// **'Bạn chưa có gia đình'**
  String get householdNoneTitle;

  /// No description provided for @householdNoneSub.
  ///
  /// In vi, this message translates to:
  /// **'Tạo gia đình mới hoặc nhập mã mời để cùng chăm cây.'**
  String get householdNoneSub;

  /// No description provided for @householdInviteTitle.
  ///
  /// In vi, this message translates to:
  /// **'Mời người nhà'**
  String get householdInviteTitle;

  /// No description provided for @householdInviteCodeLabel.
  ///
  /// In vi, this message translates to:
  /// **'Mã mời của {name}'**
  String householdInviteCodeLabel(String name);

  /// No description provided for @householdInviteExpires.
  ///
  /// In vi, this message translates to:
  /// **'Hết hạn sau {days} ngày'**
  String householdInviteExpires(int days);

  /// No description provided for @householdInviteCopy.
  ///
  /// In vi, this message translates to:
  /// **'Sao chép mã'**
  String get householdInviteCopy;

  /// No description provided for @householdInviteCopied.
  ///
  /// In vi, this message translates to:
  /// **'Đã sao chép mã'**
  String get householdInviteCopied;

  /// No description provided for @householdInviteShareLink.
  ///
  /// In vi, this message translates to:
  /// **'Gửi link mời'**
  String get householdInviteShareLink;

  /// No description provided for @householdInviteShareText.
  ///
  /// In vi, this message translates to:
  /// **'{inviter} mời bạn cùng chăm cây trong “{name}” trên Vườn Nhà. Mã: {code}. Mở: {link}'**
  String householdInviteShareText(
    String inviter,
    String name,
    String code,
    String link,
  );

  /// No description provided for @householdInviteOr.
  ///
  /// In vi, this message translates to:
  /// **'hoặc mời trực tiếp'**
  String get householdInviteOr;

  /// No description provided for @householdInviteTargetLabel.
  ///
  /// In vi, this message translates to:
  /// **'Số điện thoại hoặc email'**
  String get householdInviteTargetLabel;

  /// No description provided for @householdInviteTargetHint.
  ///
  /// In vi, this message translates to:
  /// **'09xx xxx xxx'**
  String get householdInviteTargetHint;

  /// No description provided for @householdInviteRole.
  ///
  /// In vi, this message translates to:
  /// **'Vai trò'**
  String get householdInviteRole;

  /// No description provided for @householdInviteRoleMemberDesc.
  ///
  /// In vi, this message translates to:
  /// **'Làm việc được giao, xem project được chia sẻ'**
  String get householdInviteRoleMemberDesc;

  /// No description provided for @householdInviteRoleOwnerDesc.
  ///
  /// In vi, this message translates to:
  /// **'Quản lý thành viên, project và giao việc'**
  String get householdInviteRoleOwnerDesc;

  /// No description provided for @householdInviteSend.
  ///
  /// In vi, this message translates to:
  /// **'Gửi lời mời'**
  String get householdInviteSend;

  /// No description provided for @householdInviteEmailSent.
  ///
  /// In vi, this message translates to:
  /// **'Đã gửi email mời tới {target}'**
  String householdInviteEmailSent(String target);

  /// No description provided for @householdInviteEmailFailed.
  ///
  /// In vi, this message translates to:
  /// **'Chưa gửi được email. Hãy dùng nút gửi link.'**
  String get householdInviteEmailFailed;

  /// No description provided for @householdInviteTargetInvalid.
  ///
  /// In vi, this message translates to:
  /// **'Nhập email hợp lệ hoặc số điện thoại'**
  String get householdInviteTargetInvalid;

  /// No description provided for @householdInviteOwnerOnly.
  ///
  /// In vi, this message translates to:
  /// **'Chỉ Owner mới mời được người nhà'**
  String get householdInviteOwnerOnly;

  /// No description provided for @householdInviteLoading.
  ///
  /// In vi, this message translates to:
  /// **'Đang tạo mã mời...'**
  String get householdInviteLoading;

  /// No description provided for @householdAssignTitle.
  ///
  /// In vi, this message translates to:
  /// **'Giao việc'**
  String get householdAssignTitle;

  /// No description provided for @householdAssignHow.
  ///
  /// In vi, this message translates to:
  /// **'Cách giao'**
  String get householdAssignHow;

  /// No description provided for @householdModeOnce.
  ///
  /// In vi, this message translates to:
  /// **'Chỉ lần này'**
  String get householdModeOnce;

  /// No description provided for @householdModeSeries.
  ///
  /// In vi, this message translates to:
  /// **'Cả chuỗi lặp'**
  String get householdModeSeries;

  /// No description provided for @householdModeRotation.
  ///
  /// In vi, this message translates to:
  /// **'Xoay vòng'**
  String get householdModeRotation;

  /// No description provided for @householdAssignOrder.
  ///
  /// In vi, this message translates to:
  /// **'Thứ tự xoay vòng'**
  String get householdAssignOrder;

  /// No description provided for @householdAssignTo.
  ///
  /// In vi, this message translates to:
  /// **'Giao cho'**
  String get householdAssignTo;

  /// No description provided for @householdAssignAwayUntil.
  ///
  /// In vi, this message translates to:
  /// **'Vắng nhà đến {date}'**
  String householdAssignAwayUntil(String date);

  /// No description provided for @householdAssignHintRotation.
  ///
  /// In vi, this message translates to:
  /// **'Xoay vòng: {names} → lặp lại.'**
  String householdAssignHintRotation(String names);

  /// No description provided for @householdAssignHintSeries.
  ///
  /// In vi, this message translates to:
  /// **'Mọi lần “{task}” tiếp theo sẽ giao cho {name}.'**
  String householdAssignHintSeries(String task, String name);

  /// No description provided for @householdAssignHintOnce.
  ///
  /// In vi, this message translates to:
  /// **'Chỉ lần “{task}” tới giao cho {name}.'**
  String householdAssignHintOnce(String task, String name);

  /// No description provided for @householdAssignDone.
  ///
  /// In vi, this message translates to:
  /// **'Đã giao việc'**
  String get householdAssignDone;

  /// No description provided for @householdAssignOwnerOnly.
  ///
  /// In vi, this message translates to:
  /// **'Chỉ Owner mới giao được việc'**
  String get householdAssignOwnerOnly;

  /// No description provided for @householdAssignNeedHousehold.
  ///
  /// In vi, this message translates to:
  /// **'Hãy tạo hoặc tham gia gia đình để giao việc'**
  String get householdAssignNeedHousehold;

  /// No description provided for @householdAssignNoTask.
  ///
  /// In vi, this message translates to:
  /// **'Không tìm thấy việc này'**
  String get householdAssignNoTask;

  /// No description provided for @householdAssignRotationMin.
  ///
  /// In vi, this message translates to:
  /// **'Chọn ít nhất 2 người để xoay vòng'**
  String get householdAssignRotationMin;

  /// No description provided for @householdAssignPickOne.
  ///
  /// In vi, this message translates to:
  /// **'Chọn một người'**
  String get householdAssignPickOne;

  /// No description provided for @householdWindowMorning.
  ///
  /// In vi, this message translates to:
  /// **'Sáng sớm'**
  String get householdWindowMorning;

  /// No description provided for @householdWindowAfternoon.
  ///
  /// In vi, this message translates to:
  /// **'Chiều mát'**
  String get householdWindowAfternoon;

  /// No description provided for @householdWindowAllDay.
  ///
  /// In vi, this message translates to:
  /// **'Cả ngày'**
  String get householdWindowAllDay;

  /// No description provided for @householdEveryDays.
  ///
  /// In vi, this message translates to:
  /// **'{n} ngày/lần'**
  String householdEveryDays(int n);

  /// No description provided for @householdLeaveRow.
  ///
  /// In vi, this message translates to:
  /// **'Rời gia đình “{name}”'**
  String householdLeaveRow(String name);

  /// No description provided for @householdLeaveTitle.
  ///
  /// In vi, this message translates to:
  /// **'Rời gia đình?'**
  String get householdLeaveTitle;

  /// No description provided for @householdLeaveBody.
  ///
  /// In vi, this message translates to:
  /// **'Bạn sẽ không còn thấy project chia sẻ. Project của bạn trở lại riêng tư.'**
  String get householdLeaveBody;

  /// No description provided for @householdLeaveOwnerBody.
  ///
  /// In vi, this message translates to:
  /// **'Quyền Owner sẽ chuyển cho {name}, thành viên lâu nhất.'**
  String householdLeaveOwnerBody(String name);

  /// No description provided for @householdLeaveLast.
  ///
  /// In vi, this message translates to:
  /// **'Bạn là người cuối cùng, nên gia đình sẽ bị xóa.'**
  String get householdLeaveLast;

  /// No description provided for @householdLeaveAction.
  ///
  /// In vi, this message translates to:
  /// **'Rời gia đình'**
  String get householdLeaveAction;

  /// No description provided for @householdLeft.
  ///
  /// In vi, this message translates to:
  /// **'Đã rời gia đình'**
  String get householdLeft;

  /// No description provided for @householdJoinScreenTitle.
  ///
  /// In vi, this message translates to:
  /// **'Tham gia gia đình'**
  String get householdJoinScreenTitle;

  /// No description provided for @householdJoinLinkBody.
  ///
  /// In vi, this message translates to:
  /// **'Bạn được mời bằng mã {code}'**
  String householdJoinLinkBody(String code);

  /// No description provided for @householdJoinConfirm.
  ///
  /// In vi, this message translates to:
  /// **'Tham gia'**
  String get householdJoinConfirm;

  /// No description provided for @gamTitle.
  ///
  /// In vi, this message translates to:
  /// **'Thành tích'**
  String get gamTitle;

  /// No description provided for @gamTotalXp.
  ///
  /// In vi, this message translates to:
  /// **'Tổng điểm'**
  String get gamTotalXp;

  /// No description provided for @gamXpUnit.
  ///
  /// In vi, this message translates to:
  /// **'{xp} XP'**
  String gamXpUnit(String xp);

  /// No description provided for @gamLevelLabel.
  ///
  /// In vi, this message translates to:
  /// **'Level'**
  String get gamLevelLabel;

  /// No description provided for @gamLevelLine.
  ///
  /// In vi, this message translates to:
  /// **'Cấp {level} · {name}'**
  String gamLevelLine(int level, String name);

  /// No description provided for @gamToNext.
  ///
  /// In vi, this message translates to:
  /// **'Còn {xp} XP để lên Cấp {level} · {name}'**
  String gamToNext(int xp, int level, String name);

  /// No description provided for @gamTopLevel.
  ///
  /// In vi, this message translates to:
  /// **'Bạn đã đạt cấp cao nhất'**
  String get gamTopLevel;

  /// No description provided for @gamStreak.
  ///
  /// In vi, this message translates to:
  /// **'{days} ngày liên tục'**
  String gamStreak(int days);

  /// No description provided for @gamStreakNone.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có chuỗi ngày'**
  String get gamStreakNone;

  /// No description provided for @gamOnTime.
  ///
  /// In vi, this message translates to:
  /// **'Việc đúng hạn'**
  String get gamOnTime;

  /// No description provided for @gamCheckin.
  ///
  /// In vi, this message translates to:
  /// **'Check-in ảnh'**
  String get gamCheckin;

  /// No description provided for @gamMilestone.
  ///
  /// In vi, this message translates to:
  /// **'Đạt milestone'**
  String get gamMilestone;

  /// No description provided for @gamToday.
  ///
  /// In vi, this message translates to:
  /// **'Hôm nay'**
  String get gamToday;

  /// No description provided for @gamTodayCap.
  ///
  /// In vi, this message translates to:
  /// **'{xp}/{cap} XP'**
  String gamTodayCap(int xp, int cap);

  /// No description provided for @gamAntiCheat.
  ///
  /// In vi, this message translates to:
  /// **'Mỗi ngày tối đa {cap} XP từ việc thường. Điểm milestone chỉ cộng khi có ảnh check-in xác nhận.'**
  String gamAntiCheat(int cap);

  /// No description provided for @gamPendingPhoto.
  ///
  /// In vi, this message translates to:
  /// **'{count} mốc đang chờ ảnh check-in xác nhận, chưa tính XP.'**
  String gamPendingPhoto(int count);

  /// No description provided for @gamBadges.
  ///
  /// In vi, this message translates to:
  /// **'Huy hiệu · {earned}/{total}'**
  String gamBadges(int earned, int total);

  /// No description provided for @gamBadgesEmpty.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có huy hiệu nào'**
  String get gamBadgesEmpty;

  /// No description provided for @gamBadgeLocked.
  ///
  /// In vi, this message translates to:
  /// **'Chưa đạt'**
  String get gamBadgeLocked;

  /// No description provided for @gamLoadError.
  ///
  /// In vi, this message translates to:
  /// **'Không tải được thành tích'**
  String get gamLoadError;

  /// No description provided for @gamMilestoneEyebrow.
  ///
  /// In vi, this message translates to:
  /// **'ĐẠT MỐC MỚI'**
  String get gamMilestoneEyebrow;

  /// No description provided for @gamMilestoneUnknown.
  ///
  /// In vi, this message translates to:
  /// **'Mốc mới'**
  String get gamMilestoneUnknown;

  /// No description provided for @gamMilestoneBody.
  ///
  /// In vi, this message translates to:
  /// **'{project} đã qua một mốc mới. Ảnh check-in hôm nay đã xác nhận.'**
  String gamMilestoneBody(String project);

  /// No description provided for @gamMilestoneBodyPending.
  ///
  /// In vi, this message translates to:
  /// **'{project} ghi nhận mốc này, nhưng chưa có ảnh check-in xác nhận.'**
  String gamMilestoneBodyPending(String project);

  /// No description provided for @gamRewardXp.
  ///
  /// In vi, this message translates to:
  /// **'+{xp} XP'**
  String gamRewardXp(int xp);

  /// No description provided for @gamRewardPending.
  ///
  /// In vi, this message translates to:
  /// **'Chờ ảnh'**
  String get gamRewardPending;

  /// No description provided for @gamRewardMilestone.
  ///
  /// In vi, this message translates to:
  /// **'Milestone'**
  String get gamRewardMilestone;

  /// No description provided for @gamRewardBadge.
  ///
  /// In vi, this message translates to:
  /// **'Huy hiệu'**
  String get gamRewardBadge;

  /// No description provided for @gamRewardNoBadge.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có'**
  String get gamRewardNoBadge;

  /// No description provided for @gamPendingNote.
  ///
  /// In vi, this message translates to:
  /// **'Điểm milestone chỉ cộng khi có ảnh check-in xác nhận. Hãy check-in ảnh để nhận XP.'**
  String get gamPendingNote;

  /// No description provided for @gamKeepsake.
  ///
  /// In vi, this message translates to:
  /// **'Ảnh kỷ niệm'**
  String get gamKeepsake;

  /// No description provided for @gamKeepsakeCard.
  ///
  /// In vi, this message translates to:
  /// **'Thẻ kỷ niệm'**
  String get gamKeepsakeCard;

  /// No description provided for @gamKeepsakeSub.
  ///
  /// In vi, this message translates to:
  /// **'Có thể chia sẻ'**
  String get gamKeepsakeSub;

  /// No description provided for @gamShare.
  ///
  /// In vi, this message translates to:
  /// **'Chia sẻ ảnh kỷ niệm'**
  String get gamShare;

  /// No description provided for @gamShareText.
  ///
  /// In vi, this message translates to:
  /// **'{project} vừa đạt mốc “{milestone}” trên Vườn Nhà!'**
  String gamShareText(String project, String milestone);

  /// No description provided for @gamShareError.
  ///
  /// In vi, this message translates to:
  /// **'Chưa chia sẻ được'**
  String get gamShareError;

  /// No description provided for @gamViewAchievements.
  ///
  /// In vi, this message translates to:
  /// **'Xem thành tích'**
  String get gamViewAchievements;
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
