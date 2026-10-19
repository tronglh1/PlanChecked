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
  String get configErrorTitle => 'Thiếu cấu hình';

  @override
  String get configErrorMessage =>
      'Chưa có SUPABASE_URL / SUPABASE_ANON_KEY. Chạy app với --dart-define-from-file=env/dev.json.';

  @override
  String get placeholderComingSoon => 'Sắp ra mắt';

  @override
  String get loginTagline =>
      'Kế hoạch chăm cây do AI lập riêng cho bạn, việc mỗi ngày rõ ràng, cả nhà cùng chăm.';

  @override
  String get loginGoogle => 'Tiếp tục với Google';

  @override
  String get loginOr => 'hoặc';

  @override
  String get loginEmailLabel => 'Email';

  @override
  String get loginEmailHint => 'ban@email.com';

  @override
  String get loginSendCode => 'Nhận mã đăng nhập';

  @override
  String get loginEmailInvalid => 'Email chưa hợp lệ';

  @override
  String get loginOtpTitle => 'Nhập mã xác nhận';

  @override
  String loginOtpSent(String email) {
    return 'Chúng tôi đã gửi mã 6 số tới $email';
  }

  @override
  String get loginOtpLabel => 'Mã 6 số';

  @override
  String get loginOtpVerify => 'Xác nhận';

  @override
  String get loginOtpInvalid => 'Mã gồm 6 chữ số';

  @override
  String get loginOtpWrong => 'Mã không đúng hoặc đã hết hạn';

  @override
  String get loginResend => 'Gửi lại mã';

  @override
  String get loginChangeEmail => 'Đổi email';

  @override
  String get loginError => 'Không đăng nhập được. Vui lòng thử lại.';

  @override
  String get loginTermsPrefix => 'Tiếp tục nghĩa là bạn đồng ý với ';

  @override
  String get loginTerms => 'Điều khoản';

  @override
  String get loginTermsAnd => ' và ';

  @override
  String get loginPrivacy => 'Chính sách dữ liệu';

  @override
  String get loginTermsSuffix => ' (theo Nghị định 13/2023/NĐ-CP).';

  @override
  String get profileStep => 'Bước 1/2';

  @override
  String get profileTitle => 'Giới thiệu một chút về bạn';

  @override
  String get profileSub =>
      'Vị trí giúp AI tính khí hậu và mùa vụ. App chỉ lưu ở mức tỉnh/thành.';

  @override
  String get profileChangeAvatar => 'Đổi ảnh đại diện';

  @override
  String get profileNameLabel => 'Tên hiển thị';

  @override
  String get profileLocationLabel => 'Bạn trồng cây ở đâu?';

  @override
  String get profileLocationHint => 'Chọn tỉnh/thành';

  @override
  String get profileProvinceSearch => 'Tìm tỉnh/thành';

  @override
  String get regionHelperSouth => 'Khí hậu nhiệt đới, mùa mưa tháng 5–11';

  @override
  String get regionHelperNorth => 'Bốn mùa rõ rệt, mùa đông lạnh';

  @override
  String get regionHelperCentral => 'Nắng nóng, mưa nhiều vào cuối năm';

  @override
  String get profileExperience => 'Kinh nghiệm trồng cây';

  @override
  String get expNew => 'Mới bắt đầu';

  @override
  String get expMid => 'Trung bình';

  @override
  String get expPro => 'Thành thạo';

  @override
  String get profileLanguage => 'Ngôn ngữ';

  @override
  String get langVi => 'Tiếng Việt';

  @override
  String get langEn => 'English';

  @override
  String get errorNameEmpty => 'Hãy nhập tên hiển thị';

  @override
  String get errorNameTooLong => 'Tên tối đa 50 ký tự';

  @override
  String get errorProvince => 'Hãy chọn tỉnh/thành';

  @override
  String get profileSaveError => 'Không lưu được hồ sơ. Vui lòng thử lại.';

  @override
  String get settingsEdit => 'Sửa';

  @override
  String get settingsNotifications => 'THÔNG BÁO';

  @override
  String get notifTask => 'Nhắc việc chăm cây';

  @override
  String get notifCheckin => 'Nhắc chụp check-in';

  @override
  String get notifAssignment => 'Được giao việc';

  @override
  String get notifAchievement => 'Thành tích & huy hiệu';

  @override
  String get notifBundle => 'Gộp thông báo thành 1 lần/ngày';

  @override
  String get settingsOther => 'KHÁC';

  @override
  String get settingsLanguage => 'Ngôn ngữ';

  @override
  String get settingsLeaveHousehold => 'Rời gia đình';

  @override
  String get settingsSignOut => 'Đăng xuất';

  @override
  String get settingsDeleteAccount => 'Xóa tài khoản và toàn bộ dữ liệu';

  @override
  String get deleteConfirm1Title => 'Xóa tài khoản?';

  @override
  String get deleteConfirm1Body =>
      'Toàn bộ dự án, check-in, ảnh và thành tích của bạn sẽ bị xóa.';

  @override
  String get deleteConfirm2Title => 'Bạn chắc chắn chứ?';

  @override
  String get deleteConfirm2Body => 'Hành động này không thể hoàn tác.';

  @override
  String get deleteConfirmAction => 'Xóa vĩnh viễn';

  @override
  String get deleteError => 'Không xóa được tài khoản. Vui lòng thử lại.';

  @override
  String get searchEyebrow => 'Trồng cây mới · Bước 1/3';

  @override
  String get searchTitle => 'Bạn muốn trồng cây gì?';

  @override
  String get searchFieldLabel => 'Tên cây';

  @override
  String get filterAll => 'Tất cả';

  @override
  String get filterVeg => 'Rau & quả';

  @override
  String get filterOrnamental => 'Cây cảnh trong nhà';

  @override
  String searchCount(int count, String query) {
    return '$count kết quả cho “$query”';
  }

  @override
  String searchCountAll(int count) {
    return '$count loại cây';
  }

  @override
  String get diffEasy => 'Dễ';

  @override
  String get diffMedium => 'Trung bình';

  @override
  String get diffHard => 'Khó';

  @override
  String harvestDays(int days) {
    return 'Thu hoạch ~$days ngày';
  }

  @override
  String get searchNotFoundTitle => 'Không thấy cây bạn cần?';

  @override
  String searchDidYouMean(String query) {
    return 'Bạn gõ “$query”. Có phải bạn muốn nói…?';
  }

  @override
  String get searchYes => 'Đúng rồi';

  @override
  String get searchNo => 'Không phải';

  @override
  String searchFreeText(String query) {
    return 'Dùng “$query”';
  }

  @override
  String get searchFreeTextHint =>
      'Chưa có trong danh sách? AI sẽ lập kế hoạch cho cây này ở bước sau.';

  @override
  String get searchLoadError => 'Không tải được danh sách cây';

  @override
  String get contextTitle => 'Thông tin & bối cảnh trồng';

  @override
  String get todayTitle => 'Hôm nay';

  @override
  String todayGreeting(String name) {
    return 'Chào $name';
  }

  @override
  String get todayWd1 => 'Thứ Hai';

  @override
  String get todayWd2 => 'Thứ Ba';

  @override
  String get todayWd3 => 'Thứ Tư';

  @override
  String get todayWd4 => 'Thứ Năm';

  @override
  String get todayWd5 => 'Thứ Sáu';

  @override
  String get todayWd6 => 'Thứ Bảy';

  @override
  String get todayWd7 => 'Chủ nhật';

  @override
  String todayProgress(int done, int total) {
    return 'Đã xong $done/$total việc';
  }

  @override
  String get todayXpHint => '+10 XP mỗi việc đúng hạn';

  @override
  String todayXpChip(int xp) {
    return '$xp XP hôm nay';
  }

  @override
  String get todayGroupByWindow => 'Theo khung giờ';

  @override
  String get todayGroupByProject => 'Theo project';

  @override
  String get todayWindowMorning => 'Sáng sớm · 6–8h';

  @override
  String get todayWindowAfternoon => 'Chiều mát · 16–18h';

  @override
  String get todayWindowAllDay => 'Cả ngày';

  @override
  String get todayOverdue => 'Quá hạn';

  @override
  String get todayCheckinDueTitle => 'Đến hạn chụp ảnh check-in';

  @override
  String todayCheckinDueBody(String project) {
    return '$project · +30 XP';
  }

  @override
  String get todayEmptyTitle => 'Hôm nay chưa có việc';

  @override
  String get todayEmptyBody =>
      'Trồng cây mới để nhận kế hoạch chăm sóc mỗi ngày.';

  @override
  String get todayLoadError => 'Không tải được việc hôm nay';

  @override
  String todayOfflineBanner(int count) {
    return 'Đang offline · $count thay đổi sẽ đồng bộ khi có mạng';
  }

  @override
  String get todaySyncing => 'Đang đồng bộ...';

  @override
  String get todayPendingSync => 'Chờ đồng bộ';

  @override
  String get todaySkippedLabel => 'Đã bỏ qua';

  @override
  String get todayMarkDone => 'Đánh dấu xong';

  @override
  String get todayMenu => 'Thêm tuỳ chọn';

  @override
  String todayXpToast(int xp) {
    return '+$xp XP';
  }

  @override
  String get todayXpToastLate => 'Đã xong · quá hạn nên không có XP';

  @override
  String get todayXpToastCap => 'Đã xong · hôm nay đã đủ 150 XP';

  @override
  String get todayActionError => 'Không lưu được thao tác';

  @override
  String get todayPermTitle => 'Bật nhắc việc?';

  @override
  String get todayPermBody =>
      'Vườn Nhà sẽ nhắc bạn đúng giờ chăm cây, kể cả khi không có mạng.';

  @override
  String get todayPermAllow => 'Bật nhắc việc';

  @override
  String get todayPermLater => 'Để sau';

  @override
  String todayNotifTitle(String window) {
    return 'Đến giờ chăm cây · $window';
  }

  @override
  String todayNotifMore(int count) {
    return '+$count việc khác';
  }

  @override
  String todayNotifDailyTitle(int count) {
    return 'Hôm nay có $count việc chăm cây';
  }

  @override
  String get todayNotifCheckinTitle => 'Đến hạn chụp ảnh check-in';

  @override
  String todayNotifCheckinBody(String project) {
    return 'Chụp ảnh $project để cập nhật kế hoạch (+30 XP)';
  }

  @override
  String get taskSnooze => 'Dời lại';

  @override
  String get taskSkipTitle => 'Bỏ qua việc này?';

  @override
  String get taskSkipReasonHint => 'Lý do (không bắt buộc)';

  @override
  String get taskSkipReasonRain => 'Trời mưa';

  @override
  String get taskSkipReasonAway => 'Đang vắng nhà';

  @override
  String get taskSkipReasonNotNeeded => 'Cây chưa cần';

  @override
  String get taskSkipReasonOther => 'Khác';

  @override
  String get taskSkipConfirm => 'Bỏ qua';

  @override
  String get taskSnoozeTitle => 'Dời lại đến khi nào?';

  @override
  String get taskSnoozeTomorrow => 'Ngày mai';

  @override
  String get taskSnooze2Days => '2 ngày nữa';

  @override
  String get taskSnoozeNextWeek => 'Tuần sau';

  @override
  String get taskTileWindow => 'Khung giờ';

  @override
  String get taskTileFrequency => 'Lặp lại';

  @override
  String get taskTileReminder => 'Nhắc lúc';

  @override
  String get taskFreqOnce => 'Một lần';

  @override
  String get taskFreqDaily => 'Hằng ngày';

  @override
  String taskFreqEveryN(int n) {
    return '$n ngày/lần';
  }

  @override
  String taskFreqFixed(int n) {
    return 'Ngày $n';
  }

  @override
  String get taskReminderByWindow => 'Theo khung giờ';

  @override
  String taskAssignedTo(String name) {
    return 'Giao cho $name';
  }

  @override
  String get taskUnassigned => 'Chưa giao ai';

  @override
  String get taskChange => 'Đổi';

  @override
  String get taskAssign => 'Giao việc';

  @override
  String get taskHowTo => 'Cách làm';

  @override
  String get taskWhy => 'Vì sao?';

  @override
  String get taskNoSteps => 'Chưa có hướng dẫn chi tiết cho việc này.';

  @override
  String get taskSafetyGeneric =>
      'Nếu dùng phân bón hoặc thuốc đóng gói, làm theo liều trên nhãn sản phẩm. App không đưa liều hóa chất cụ thể.';

  @override
  String get taskHistory => 'Lịch sử';

  @override
  String get taskHistoryEmpty => 'Chưa có lịch sử';

  @override
  String get taskHistoryDone => 'Xong';

  @override
  String get taskHistorySkip => 'Bỏ qua';

  @override
  String get taskHistorySnooze => 'Dời lại';

  @override
  String taskDoneButton(int xp) {
    return 'Xong · +$xp XP';
  }

  @override
  String get taskNotDueToday => 'Việc này không đến hạn hôm nay';

  @override
  String get taskNotFound => 'Không tìm thấy việc này';

  @override
  String get taskAssignPlaceholder =>
      'Giao việc cho thành viên sẽ có ở bản sau.';

  @override
  String get taskCheckinPlaceholder => 'Chụp ảnh check-in sẽ có ở bản sau.';
}
