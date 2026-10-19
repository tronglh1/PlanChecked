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

  /// No description provided for @projectsTitle.
  ///
  /// In vi, this message translates to:
  /// **'Vườn của tôi'**
  String get projectsTitle;

  /// No description provided for @projectsFilterActive.
  ///
  /// In vi, this message translates to:
  /// **'Đang trồng · {count}'**
  String projectsFilterActive(int count);

  /// No description provided for @projectsFilterDone.
  ///
  /// In vi, this message translates to:
  /// **'Đã xong · {count}'**
  String projectsFilterDone(int count);

  /// No description provided for @projectsFilterArchived.
  ///
  /// In vi, this message translates to:
  /// **'Lưu trữ'**
  String get projectsFilterArchived;

  /// No description provided for @projectsEmptyTitle.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có cây nào'**
  String get projectsEmptyTitle;

  /// No description provided for @projectsEmptyMessage.
  ///
  /// In vi, this message translates to:
  /// **'Bắt đầu trồng cây đầu tiên, AI sẽ lập kế hoạch chăm sóc cho bạn.'**
  String get projectsEmptyMessage;

  /// No description provided for @projectsAddNew.
  ///
  /// In vi, this message translates to:
  /// **'Trồng cây mới'**
  String get projectsAddNew;

  /// No description provided for @projectsLoadError.
  ///
  /// In vi, this message translates to:
  /// **'Không tải được danh sách. Thử lại nhé.'**
  String get projectsLoadError;

  /// No description provided for @projectsKindLine.
  ///
  /// In vi, this message translates to:
  /// **'{group} · {pots} chậu · ngày {day}'**
  String projectsKindLine(String group, int pots, int day);

  /// No description provided for @projectsNoPlan.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có kế hoạch'**
  String get projectsNoPlan;

  /// No description provided for @projectsPlanPending.
  ///
  /// In vi, this message translates to:
  /// **'Chờ duyệt kế hoạch'**
  String get projectsPlanPending;

  /// No description provided for @projectsStageBeforeStart.
  ///
  /// In vi, this message translates to:
  /// **'Sắp bắt đầu'**
  String get projectsStageBeforeStart;

  /// No description provided for @projectsTasksToday.
  ///
  /// In vi, this message translates to:
  /// **'{count} việc hôm nay'**
  String projectsTasksToday(int count);

  /// No description provided for @projectsPhotoAgo.
  ///
  /// In vi, this message translates to:
  /// **'Ảnh: {days} ngày trước'**
  String projectsPhotoAgo(int days);

  /// No description provided for @projectsPhotoToday.
  ///
  /// In vi, this message translates to:
  /// **'Ảnh: hôm nay'**
  String get projectsPhotoToday;

  /// No description provided for @projectsNoPhoto.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có ảnh'**
  String get projectsNoPhoto;

  /// No description provided for @projectsLatestPhoto.
  ///
  /// In vi, this message translates to:
  /// **'Ảnh mới nhất'**
  String get projectsLatestPhoto;

  /// No description provided for @projectsContextEyebrow.
  ///
  /// In vi, this message translates to:
  /// **'Trồng cây mới · Bước 2/3'**
  String get projectsContextEyebrow;

  /// No description provided for @projectsContextTitle.
  ///
  /// In vi, this message translates to:
  /// **'{plant} trồng ở đâu?'**
  String projectsContextTitle(String plant);

  /// No description provided for @projectsContextTitleNoPlant.
  ///
  /// In vi, this message translates to:
  /// **'Cây của bạn trồng ở đâu?'**
  String get projectsContextTitleNoPlant;

  /// No description provided for @projectsFieldPlantGroup.
  ///
  /// In vi, this message translates to:
  /// **'Loại cây'**
  String get projectsFieldPlantGroup;

  /// No description provided for @projectsFieldName.
  ///
  /// In vi, this message translates to:
  /// **'Tên project'**
  String get projectsFieldName;

  /// No description provided for @projectsFieldStartDate.
  ///
  /// In vi, this message translates to:
  /// **'Ngày bắt đầu'**
  String get projectsFieldStartDate;

  /// No description provided for @projectsFieldPots.
  ///
  /// In vi, this message translates to:
  /// **'Số chậu'**
  String get projectsFieldPots;

  /// No description provided for @projectsFieldStartStage.
  ///
  /// In vi, this message translates to:
  /// **'Bắt đầu từ'**
  String get projectsFieldStartStage;

  /// No description provided for @projectsStartSeed.
  ///
  /// In vi, this message translates to:
  /// **'Hạt giống'**
  String get projectsStartSeed;

  /// No description provided for @projectsStartSeedling.
  ///
  /// In vi, this message translates to:
  /// **'Cây con'**
  String get projectsStartSeedling;

  /// No description provided for @projectsStartMature.
  ///
  /// In vi, this message translates to:
  /// **'Trưởng thành'**
  String get projectsStartMature;

  /// No description provided for @projectsFieldSpace.
  ///
  /// In vi, this message translates to:
  /// **'Nơi trồng'**
  String get projectsFieldSpace;

  /// No description provided for @projectsSpaceIndoor.
  ///
  /// In vi, this message translates to:
  /// **'Trong nhà'**
  String get projectsSpaceIndoor;

  /// No description provided for @projectsSpaceBalcony.
  ///
  /// In vi, this message translates to:
  /// **'Ban công'**
  String get projectsSpaceBalcony;

  /// No description provided for @projectsSpaceYard.
  ///
  /// In vi, this message translates to:
  /// **'Sân vườn'**
  String get projectsSpaceYard;

  /// No description provided for @projectsSpaceRooftop.
  ///
  /// In vi, this message translates to:
  /// **'Sân thượng'**
  String get projectsSpaceRooftop;

  /// No description provided for @projectsFieldSun.
  ///
  /// In vi, this message translates to:
  /// **'Nắng mỗi ngày'**
  String get projectsFieldSun;

  /// No description provided for @projectsSunLow.
  ///
  /// In vi, this message translates to:
  /// **'Dưới 3 giờ'**
  String get projectsSunLow;

  /// No description provided for @projectsSunMedium.
  ///
  /// In vi, this message translates to:
  /// **'3–6 giờ'**
  String get projectsSunMedium;

  /// No description provided for @projectsSunHigh.
  ///
  /// In vi, this message translates to:
  /// **'Trên 6 giờ'**
  String get projectsSunHigh;

  /// No description provided for @projectsFieldPot.
  ///
  /// In vi, this message translates to:
  /// **'Chậu / đất'**
  String get projectsFieldPot;

  /// No description provided for @projectsPotDefault.
  ///
  /// In vi, this message translates to:
  /// **'Chậu nhựa 20L, đất trộn'**
  String get projectsPotDefault;

  /// No description provided for @projectsFieldWatering.
  ///
  /// In vi, this message translates to:
  /// **'Cách tưới'**
  String get projectsFieldWatering;

  /// No description provided for @projectsWateringManual.
  ///
  /// In vi, this message translates to:
  /// **'Tưới tay'**
  String get projectsWateringManual;

  /// No description provided for @projectsWateringAuto.
  ///
  /// In vi, this message translates to:
  /// **'Tự động'**
  String get projectsWateringAuto;

  /// No description provided for @projectsCoverAdd.
  ///
  /// In vi, this message translates to:
  /// **'Thêm ảnh bìa (không bắt buộc)'**
  String get projectsCoverAdd;

  /// No description provided for @projectsCoverAdded.
  ///
  /// In vi, this message translates to:
  /// **'Đã chọn ảnh bìa'**
  String get projectsCoverAdded;

  /// No description provided for @projectsCreatePlan.
  ///
  /// In vi, this message translates to:
  /// **'Tạo kế hoạch chăm sóc'**
  String get projectsCreatePlan;

  /// No description provided for @projectsNameRequired.
  ///
  /// In vi, this message translates to:
  /// **'Hãy đặt tên cho project'**
  String get projectsNameRequired;

  /// No description provided for @projectsCreateError.
  ///
  /// In vi, this message translates to:
  /// **'Không tạo được project. Thử lại nhé.'**
  String get projectsCreateError;

  /// No description provided for @projectsDefaultName.
  ///
  /// In vi, this message translates to:
  /// **'{plant} – {month}/{year}'**
  String projectsDefaultName(String plant, int month, int year);

  /// No description provided for @projectsPotsMinus.
  ///
  /// In vi, this message translates to:
  /// **'Giảm số chậu'**
  String get projectsPotsMinus;

  /// No description provided for @projectsPotsPlus.
  ///
  /// In vi, this message translates to:
  /// **'Tăng số chậu'**
  String get projectsPotsPlus;

  /// No description provided for @planGeneratingEyebrow.
  ///
  /// In vi, this message translates to:
  /// **'Trồng cây mới · Bước 3/3'**
  String get planGeneratingEyebrow;

  /// No description provided for @planGeneratingTitle.
  ///
  /// In vi, this message translates to:
  /// **'Đang lập kế hoạch cho'**
  String get planGeneratingTitle;

  /// No description provided for @planGeneratingHint.
  ///
  /// In vi, this message translates to:
  /// **'Thường mất dưới 20 giây'**
  String get planGeneratingHint;

  /// No description provided for @planGenStep1.
  ///
  /// In vi, this message translates to:
  /// **'Đọc dữ liệu chuẩn của cây'**
  String get planGenStep1;

  /// No description provided for @planGenStep1Sub.
  ///
  /// In vi, this message translates to:
  /// **'Từ cơ sở dữ liệu cây Vườn Nhà'**
  String get planGenStep1Sub;

  /// No description provided for @planGenStep2.
  ///
  /// In vi, this message translates to:
  /// **'Tính khí hậu và mùa vụ'**
  String get planGenStep2;

  /// No description provided for @planGenStep2Sub.
  ///
  /// In vi, this message translates to:
  /// **'Theo vùng và tháng bạn bắt đầu'**
  String get planGenStep2Sub;

  /// No description provided for @planGenStep3.
  ///
  /// In vi, this message translates to:
  /// **'Chia giai đoạn và mốc'**
  String get planGenStep3;

  /// No description provided for @planGenStep3Sub.
  ///
  /// In vi, this message translates to:
  /// **'Từ lúc bắt đầu đến thu hoạch'**
  String get planGenStep3Sub;

  /// No description provided for @planGenStep4.
  ///
  /// In vi, this message translates to:
  /// **'Tạo việc chăm sóc hằng ngày'**
  String get planGenStep4;

  /// No description provided for @planGenStep4Sub.
  ///
  /// In vi, this message translates to:
  /// **'Theo khung giờ sáng sớm / chiều mát'**
  String get planGenStep4Sub;

  /// No description provided for @planGeneratingFallbackNote.
  ///
  /// In vi, this message translates to:
  /// **'Nếu AI gặp sự cố, app dùng plan mẫu để bạn bắt đầu ngay.'**
  String get planGeneratingFallbackNote;

  /// No description provided for @planViewPlan.
  ///
  /// In vi, this message translates to:
  /// **'Xem kế hoạch'**
  String get planViewPlan;

  /// No description provided for @planGenFailedTitle.
  ///
  /// In vi, this message translates to:
  /// **'AI đang gặp sự cố'**
  String get planGenFailedTitle;

  /// No description provided for @planGenFailedMessage.
  ///
  /// In vi, this message translates to:
  /// **'Chưa lập được kế hoạch. Hãy thử lại sau ít giây.'**
  String get planGenFailedMessage;

  /// No description provided for @planUseTemplate.
  ///
  /// In vi, this message translates to:
  /// **'Dùng plan mẫu'**
  String get planUseTemplate;

  /// No description provided for @planFallbackAiFailure.
  ///
  /// In vi, this message translates to:
  /// **'AI gặp sự cố nên app dùng plan mẫu cho bạn.'**
  String get planFallbackAiFailure;

  /// No description provided for @planFallbackQuota.
  ///
  /// In vi, this message translates to:
  /// **'Bạn đã dùng hết lượt AI hôm nay nên app dùng plan mẫu cho bạn.'**
  String get planFallbackQuota;

  /// No description provided for @planReviewTitle.
  ///
  /// In vi, this message translates to:
  /// **'Kế hoạch {days} ngày'**
  String planReviewTitle(int days);

  /// No description provided for @planAiLabel.
  ///
  /// In vi, this message translates to:
  /// **'Gợi ý từ AI'**
  String get planAiLabel;

  /// No description provided for @planTemplateLabel.
  ///
  /// In vi, this message translates to:
  /// **'Plan mẫu'**
  String get planTemplateLabel;

  /// No description provided for @planConfidenceHigh.
  ///
  /// In vi, this message translates to:
  /// **'Tin cậy cao · {pct}%'**
  String planConfidenceHigh(int pct);

  /// No description provided for @planConfidenceMedium.
  ///
  /// In vi, this message translates to:
  /// **'Tin cậy trung bình · {pct}%'**
  String planConfidenceMedium(int pct);

  /// No description provided for @planConfidenceLow.
  ///
  /// In vi, this message translates to:
  /// **'Tin cậy thấp · {pct}%'**
  String planConfidenceLow(int pct);

  /// No description provided for @planSources.
  ///
  /// In vi, this message translates to:
  /// **'Nguồn: {sources}'**
  String planSources(String sources);

  /// No description provided for @planSourcesDefault.
  ///
  /// In vi, this message translates to:
  /// **'CSDL cây Vườn Nhà'**
  String get planSourcesDefault;

  /// No description provided for @planSegStages.
  ///
  /// In vi, this message translates to:
  /// **'Giai đoạn'**
  String get planSegStages;

  /// No description provided for @planSegCalendar.
  ///
  /// In vi, this message translates to:
  /// **'Lịch'**
  String get planSegCalendar;

  /// No description provided for @planStageDays.
  ///
  /// In vi, this message translates to:
  /// **'Ngày {from}–{to}'**
  String planStageDays(int from, int to);

  /// No description provided for @planStageMilestone.
  ///
  /// In vi, this message translates to:
  /// **'Mốc: {milestone}'**
  String planStageMilestone(String milestone);

  /// No description provided for @planStageTaskCount.
  ///
  /// In vi, this message translates to:
  /// **'{count} việc'**
  String planStageTaskCount(int count);

  /// No description provided for @planAddTask.
  ///
  /// In vi, this message translates to:
  /// **'+ Thêm việc'**
  String get planAddTask;

  /// No description provided for @planStart.
  ///
  /// In vi, this message translates to:
  /// **'Bắt đầu trồng'**
  String get planStart;

  /// No description provided for @planApproveError.
  ///
  /// In vi, this message translates to:
  /// **'Không duyệt được kế hoạch. Thử lại nhé.'**
  String get planApproveError;

  /// No description provided for @planSafetyTitle.
  ///
  /// In vi, this message translates to:
  /// **'Lưu ý an toàn'**
  String get planSafetyTitle;

  /// No description provided for @planSafetyOrganic.
  ///
  /// In vi, this message translates to:
  /// **'Ưu tiên cách an toàn, hữu cơ. App không ghi liều lượng phân hay thuốc: hãy đọc nhãn sản phẩm.'**
  String get planSafetyOrganic;

  /// No description provided for @planEmpty.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có kế hoạch cho project này'**
  String get planEmpty;

  /// No description provided for @planLoadError.
  ///
  /// In vi, this message translates to:
  /// **'Không tải được kế hoạch. Thử lại nhé.'**
  String get planLoadError;

  /// No description provided for @planFreqOnce.
  ///
  /// In vi, this message translates to:
  /// **'Một lần'**
  String get planFreqOnce;

  /// No description provided for @planFreqDaily.
  ///
  /// In vi, this message translates to:
  /// **'Hằng ngày'**
  String get planFreqDaily;

  /// No description provided for @planFreqEveryN.
  ///
  /// In vi, this message translates to:
  /// **'{n} ngày/lần'**
  String planFreqEveryN(int n);

  /// No description provided for @planFreqFixedDay.
  ///
  /// In vi, this message translates to:
  /// **'Ngày {day}'**
  String planFreqFixedDay(int day);

  /// No description provided for @planFreqFixedDate.
  ///
  /// In vi, this message translates to:
  /// **'Ngày {date}'**
  String planFreqFixedDate(String date);

  /// No description provided for @planWindowMorning.
  ///
  /// In vi, this message translates to:
  /// **'Sáng sớm · 6–8h'**
  String get planWindowMorning;

  /// No description provided for @planWindowAfternoon.
  ///
  /// In vi, this message translates to:
  /// **'Chiều mát · 16–18h'**
  String get planWindowAfternoon;

  /// No description provided for @planWindowAllDay.
  ///
  /// In vi, this message translates to:
  /// **'Cả ngày'**
  String get planWindowAllDay;

  /// No description provided for @planWindowMorningShort.
  ///
  /// In vi, this message translates to:
  /// **'Sáng sớm'**
  String get planWindowMorningShort;

  /// No description provided for @planWindowAfternoonShort.
  ///
  /// In vi, this message translates to:
  /// **'Chiều mát'**
  String get planWindowAfternoonShort;

  /// No description provided for @planTaskAddTitle.
  ///
  /// In vi, this message translates to:
  /// **'Thêm việc'**
  String get planTaskAddTitle;

  /// No description provided for @planTaskEditTitle.
  ///
  /// In vi, this message translates to:
  /// **'Sửa việc'**
  String get planTaskEditTitle;

  /// No description provided for @planTaskCode.
  ///
  /// In vi, this message translates to:
  /// **'Loại việc'**
  String get planTaskCode;

  /// No description provided for @planTaskWindow.
  ///
  /// In vi, this message translates to:
  /// **'Khung giờ'**
  String get planTaskWindow;

  /// No description provided for @planTaskFrequency.
  ///
  /// In vi, this message translates to:
  /// **'Tần suất'**
  String get planTaskFrequency;

  /// No description provided for @planTaskInterval.
  ///
  /// In vi, this message translates to:
  /// **'Cách nhau (ngày)'**
  String get planTaskInterval;

  /// No description provided for @planTaskFixedDay.
  ///
  /// In vi, this message translates to:
  /// **'Ngày thứ (của project)'**
  String get planTaskFixedDay;

  /// No description provided for @planTaskReminder.
  ///
  /// In vi, this message translates to:
  /// **'Nhắc lúc'**
  String get planTaskReminder;

  /// No description provided for @planTaskNoReminder.
  ///
  /// In vi, this message translates to:
  /// **'Không nhắc'**
  String get planTaskNoReminder;

  /// No description provided for @planTaskStage.
  ///
  /// In vi, this message translates to:
  /// **'Giai đoạn'**
  String get planTaskStage;

  /// No description provided for @planTaskDelete.
  ///
  /// In vi, this message translates to:
  /// **'Xóa việc'**
  String get planTaskDelete;

  /// No description provided for @planTaskSaveError.
  ///
  /// In vi, this message translates to:
  /// **'Không lưu được. Thử lại nhé.'**
  String get planTaskSaveError;

  /// No description provided for @planCalendarTitle.
  ///
  /// In vi, this message translates to:
  /// **'Lịch chăm sóc'**
  String get planCalendarTitle;

  /// No description provided for @planWeekLabel.
  ///
  /// In vi, this message translates to:
  /// **'Tuần {from}–{to}'**
  String planWeekLabel(String from, String to);

  /// No description provided for @planPrevWeek.
  ///
  /// In vi, this message translates to:
  /// **'Tuần trước'**
  String get planPrevWeek;

  /// No description provided for @planNextWeek.
  ///
  /// In vi, this message translates to:
  /// **'Tuần sau'**
  String get planNextWeek;

  /// No description provided for @planDow1.
  ///
  /// In vi, this message translates to:
  /// **'T2'**
  String get planDow1;

  /// No description provided for @planDow2.
  ///
  /// In vi, this message translates to:
  /// **'T3'**
  String get planDow2;

  /// No description provided for @planDow3.
  ///
  /// In vi, this message translates to:
  /// **'T4'**
  String get planDow3;

  /// No description provided for @planDow4.
  ///
  /// In vi, this message translates to:
  /// **'T5'**
  String get planDow4;

  /// No description provided for @planDow5.
  ///
  /// In vi, this message translates to:
  /// **'T6'**
  String get planDow5;

  /// No description provided for @planDow6.
  ///
  /// In vi, this message translates to:
  /// **'T7'**
  String get planDow6;

  /// No description provided for @planDow7.
  ///
  /// In vi, this message translates to:
  /// **'CN'**
  String get planDow7;

  /// No description provided for @planDayTasks.
  ///
  /// In vi, this message translates to:
  /// **'{count} việc'**
  String planDayTasks(int count);

  /// No description provided for @planStageBanner.
  ///
  /// In vi, this message translates to:
  /// **'Giai đoạn {n} · {name} (ngày {from}–{to}) · còn {left} ngày'**
  String planStageBanner(int n, String name, int from, int to, int left);

  /// No description provided for @planOutsideStages.
  ///
  /// In vi, this message translates to:
  /// **'Ngoài các giai đoạn của kế hoạch'**
  String get planOutsideStages;

  /// No description provided for @planDayLabel.
  ///
  /// In vi, this message translates to:
  /// **'{dow}, {date}'**
  String planDayLabel(String dow, String date);

  /// No description provided for @planNoTasksDay.
  ///
  /// In vi, this message translates to:
  /// **'Không có việc trong ngày này'**
  String get planNoTasksDay;

  /// No description provided for @planAddManual.
  ///
  /// In vi, this message translates to:
  /// **'+ Thêm việc thủ công'**
  String get planAddManual;

  /// No description provided for @planTimeline.
  ///
  /// In vi, this message translates to:
  /// **'Các giai đoạn'**
  String get planTimeline;

  /// No description provided for @projectDetailTabOverview.
  ///
  /// In vi, this message translates to:
  /// **'Tổng quan'**
  String get projectDetailTabOverview;

  /// No description provided for @projectDetailTabPlan.
  ///
  /// In vi, this message translates to:
  /// **'Plan'**
  String get projectDetailTabPlan;

  /// No description provided for @projectDetailTabCalendar.
  ///
  /// In vi, this message translates to:
  /// **'Lịch'**
  String get projectDetailTabCalendar;

  /// No description provided for @projectDetailTabPhotos.
  ///
  /// In vi, this message translates to:
  /// **'Ảnh'**
  String get projectDetailTabPhotos;

  /// No description provided for @projectDetailTabMembers.
  ///
  /// In vi, this message translates to:
  /// **'Thành viên'**
  String get projectDetailTabMembers;

  /// No description provided for @projectDetailMeta.
  ///
  /// In vi, this message translates to:
  /// **'{group} · {pots} chậu · {space} {sun}'**
  String projectDetailMeta(String group, int pots, String space, String sun);

  /// No description provided for @projectDetailShared.
  ///
  /// In vi, this message translates to:
  /// **'Chia sẻ với gia đình'**
  String get projectDetailShared;

  /// No description provided for @projectDetailStageCard.
  ///
  /// In vi, this message translates to:
  /// **'Giai đoạn {n}/{total} · {name}'**
  String projectDetailStageCard(int n, int total, String name);

  /// No description provided for @projectDetailDay.
  ///
  /// In vi, this message translates to:
  /// **'Ngày {day}/{total}'**
  String projectDetailDay(int day, int total);

  /// No description provided for @projectDetailNextMilestone.
  ///
  /// In vi, this message translates to:
  /// **'Mốc tiếp theo: {milestone}, dự kiến khoảng {date}'**
  String projectDetailNextMilestone(String milestone, String date);

  /// No description provided for @projectDetailStatDone.
  ///
  /// In vi, this message translates to:
  /// **'Việc đã xong'**
  String get projectDetailStatDone;

  /// No description provided for @projectDetailStatCheckins.
  ///
  /// In vi, this message translates to:
  /// **'Lần check-in'**
  String get projectDetailStatCheckins;

  /// No description provided for @projectDetailStatMilestones.
  ///
  /// In vi, this message translates to:
  /// **'Mốc đã đạt'**
  String get projectDetailStatMilestones;

  /// No description provided for @projectDetailPhotos.
  ///
  /// In vi, this message translates to:
  /// **'Ảnh tăng trưởng'**
  String get projectDetailPhotos;

  /// No description provided for @projectDetailPhotosEmpty.
  ///
  /// In vi, this message translates to:
  /// **'Ảnh check-in sẽ xuất hiện ở đây theo thời gian.'**
  String get projectDetailPhotosEmpty;

  /// No description provided for @projectDetailPhotoCount.
  ///
  /// In vi, this message translates to:
  /// **'{count} ảnh'**
  String projectDetailPhotoCount(int count);

  /// No description provided for @projectDetailHistory.
  ///
  /// In vi, this message translates to:
  /// **'Lịch sử việc'**
  String get projectDetailHistory;

  /// No description provided for @projectDetailHistoryEmpty.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có việc nào được ghi nhận.'**
  String get projectDetailHistoryEmpty;

  /// No description provided for @projectDetailHistoryLine.
  ///
  /// In vi, this message translates to:
  /// **'{task} · {action}'**
  String projectDetailHistoryLine(String task, String action);

  /// No description provided for @projectDetailMembers.
  ///
  /// In vi, this message translates to:
  /// **'Thành viên được giao việc'**
  String get projectDetailMembers;

  /// No description provided for @projectDetailNoMembers.
  ///
  /// In vi, this message translates to:
  /// **'Chưa giao việc cho ai.'**
  String get projectDetailNoMembers;

  /// No description provided for @projectDetailMemberTasks.
  ///
  /// In vi, this message translates to:
  /// **'{count} việc'**
  String projectDetailMemberTasks(int count);

  /// No description provided for @projectDetailNoPlan.
  ///
  /// In vi, this message translates to:
  /// **'Project này chưa có kế hoạch được duyệt.'**
  String get projectDetailNoPlan;

  /// No description provided for @projectDetailReviewPlan.
  ///
  /// In vi, this message translates to:
  /// **'Duyệt kế hoạch'**
  String get projectDetailReviewPlan;

  /// No description provided for @projectDetailOpenPlan.
  ///
  /// In vi, this message translates to:
  /// **'Xem kế hoạch'**
  String get projectDetailOpenPlan;

  /// No description provided for @projectDetailOpenCalendar.
  ///
  /// In vi, this message translates to:
  /// **'Mở lịch'**
  String get projectDetailOpenCalendar;

  /// No description provided for @projectDetailLoadError.
  ///
  /// In vi, this message translates to:
  /// **'Không tải được project. Thử lại nhé.'**
  String get projectDetailLoadError;

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
