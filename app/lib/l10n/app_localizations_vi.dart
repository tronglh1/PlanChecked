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
  String get projectsTitle => 'Vườn của tôi';

  @override
  String projectsFilterActive(int count) {
    return 'Đang trồng · $count';
  }

  @override
  String projectsFilterDone(int count) {
    return 'Đã xong · $count';
  }

  @override
  String get projectsFilterArchived => 'Lưu trữ';

  @override
  String get projectsEmptyTitle => 'Chưa có cây nào';

  @override
  String get projectsEmptyMessage =>
      'Bắt đầu trồng cây đầu tiên, AI sẽ lập kế hoạch chăm sóc cho bạn.';

  @override
  String get projectsAddNew => 'Trồng cây mới';

  @override
  String get projectsLoadError => 'Không tải được danh sách. Thử lại nhé.';

  @override
  String projectsKindLine(String group, int pots, int day) {
    return '$group · $pots chậu · ngày $day';
  }

  @override
  String get projectsNoPlan => 'Chưa có kế hoạch';

  @override
  String get projectsPlanPending => 'Chờ duyệt kế hoạch';

  @override
  String get projectsStageBeforeStart => 'Sắp bắt đầu';

  @override
  String projectsTasksToday(int count) {
    return '$count việc hôm nay';
  }

  @override
  String projectsPhotoAgo(int days) {
    return 'Ảnh: $days ngày trước';
  }

  @override
  String get projectsPhotoToday => 'Ảnh: hôm nay';

  @override
  String get projectsNoPhoto => 'Chưa có ảnh';

  @override
  String get projectsLatestPhoto => 'Ảnh mới nhất';

  @override
  String get projectsContextEyebrow => 'Trồng cây mới · Bước 2/3';

  @override
  String projectsContextTitle(String plant) {
    return '$plant trồng ở đâu?';
  }

  @override
  String get projectsContextTitleNoPlant => 'Cây của bạn trồng ở đâu?';

  @override
  String get projectsFieldPlantGroup => 'Loại cây';

  @override
  String get projectsFieldName => 'Tên project';

  @override
  String get projectsFieldStartDate => 'Ngày bắt đầu';

  @override
  String get projectsFieldPots => 'Số chậu';

  @override
  String get projectsFieldStartStage => 'Bắt đầu từ';

  @override
  String get projectsStartSeed => 'Hạt giống';

  @override
  String get projectsStartSeedling => 'Cây con';

  @override
  String get projectsStartMature => 'Trưởng thành';

  @override
  String get projectsFieldSpace => 'Nơi trồng';

  @override
  String get projectsSpaceIndoor => 'Trong nhà';

  @override
  String get projectsSpaceBalcony => 'Ban công';

  @override
  String get projectsSpaceYard => 'Sân vườn';

  @override
  String get projectsSpaceRooftop => 'Sân thượng';

  @override
  String get projectsFieldSun => 'Nắng mỗi ngày';

  @override
  String get projectsSunLow => 'Dưới 3 giờ';

  @override
  String get projectsSunMedium => '3–6 giờ';

  @override
  String get projectsSunHigh => 'Trên 6 giờ';

  @override
  String get projectsFieldPot => 'Chậu / đất';

  @override
  String get projectsPotDefault => 'Chậu nhựa 20L, đất trộn';

  @override
  String get projectsFieldWatering => 'Cách tưới';

  @override
  String get projectsWateringManual => 'Tưới tay';

  @override
  String get projectsWateringAuto => 'Tự động';

  @override
  String get projectsCoverAdd => 'Thêm ảnh bìa (không bắt buộc)';

  @override
  String get projectsCoverAdded => 'Đã chọn ảnh bìa';

  @override
  String get projectsCreatePlan => 'Tạo kế hoạch chăm sóc';

  @override
  String get projectsNameRequired => 'Hãy đặt tên cho project';

  @override
  String get projectsCreateError => 'Không tạo được project. Thử lại nhé.';

  @override
  String projectsDefaultName(String plant, int month, int year) {
    return '$plant – $month/$year';
  }

  @override
  String get projectsPotsMinus => 'Giảm số chậu';

  @override
  String get projectsPotsPlus => 'Tăng số chậu';

  @override
  String get planGeneratingEyebrow => 'Trồng cây mới · Bước 3/3';

  @override
  String get planGeneratingTitle => 'Đang lập kế hoạch cho';

  @override
  String get planGeneratingHint => 'Thường mất dưới 20 giây';

  @override
  String get planGenStep1 => 'Đọc dữ liệu chuẩn của cây';

  @override
  String get planGenStep1Sub => 'Từ cơ sở dữ liệu cây Vườn Nhà';

  @override
  String get planGenStep2 => 'Tính khí hậu và mùa vụ';

  @override
  String get planGenStep2Sub => 'Theo vùng và tháng bạn bắt đầu';

  @override
  String get planGenStep3 => 'Chia giai đoạn và mốc';

  @override
  String get planGenStep3Sub => 'Từ lúc bắt đầu đến thu hoạch';

  @override
  String get planGenStep4 => 'Tạo việc chăm sóc hằng ngày';

  @override
  String get planGenStep4Sub => 'Theo khung giờ sáng sớm / chiều mát';

  @override
  String get planGeneratingFallbackNote =>
      'Nếu AI gặp sự cố, app dùng plan mẫu để bạn bắt đầu ngay.';

  @override
  String get planViewPlan => 'Xem kế hoạch';

  @override
  String get planGenFailedTitle => 'AI đang gặp sự cố';

  @override
  String get planGenFailedMessage =>
      'Chưa lập được kế hoạch. Hãy thử lại sau ít giây.';

  @override
  String get planUseTemplate => 'Dùng plan mẫu';

  @override
  String get planFallbackAiFailure =>
      'AI gặp sự cố nên app dùng plan mẫu cho bạn.';

  @override
  String get planFallbackQuota =>
      'Bạn đã dùng hết lượt AI hôm nay nên app dùng plan mẫu cho bạn.';

  @override
  String planReviewTitle(int days) {
    return 'Kế hoạch $days ngày';
  }

  @override
  String get planAiLabel => 'Gợi ý từ AI';

  @override
  String get planTemplateLabel => 'Plan mẫu';

  @override
  String planConfidenceHigh(int pct) {
    return 'Tin cậy cao · $pct%';
  }

  @override
  String planConfidenceMedium(int pct) {
    return 'Tin cậy trung bình · $pct%';
  }

  @override
  String planConfidenceLow(int pct) {
    return 'Tin cậy thấp · $pct%';
  }

  @override
  String planSources(String sources) {
    return 'Nguồn: $sources';
  }

  @override
  String get planSourcesDefault => 'CSDL cây Vườn Nhà';

  @override
  String get planSegStages => 'Giai đoạn';

  @override
  String get planSegCalendar => 'Lịch';

  @override
  String planStageDays(int from, int to) {
    return 'Ngày $from–$to';
  }

  @override
  String planStageMilestone(String milestone) {
    return 'Mốc: $milestone';
  }

  @override
  String planStageTaskCount(int count) {
    return '$count việc';
  }

  @override
  String get planAddTask => '+ Thêm việc';

  @override
  String get planStart => 'Bắt đầu trồng';

  @override
  String get planApproveError => 'Không duyệt được kế hoạch. Thử lại nhé.';

  @override
  String get planSafetyTitle => 'Lưu ý an toàn';

  @override
  String get planSafetyOrganic =>
      'Ưu tiên cách an toàn, hữu cơ. App không ghi liều lượng phân hay thuốc: hãy đọc nhãn sản phẩm.';

  @override
  String get planEmpty => 'Chưa có kế hoạch cho project này';

  @override
  String get planLoadError => 'Không tải được kế hoạch. Thử lại nhé.';

  @override
  String get planFreqOnce => 'Một lần';

  @override
  String get planFreqDaily => 'Hằng ngày';

  @override
  String planFreqEveryN(int n) {
    return '$n ngày/lần';
  }

  @override
  String planFreqFixedDay(int day) {
    return 'Ngày $day';
  }

  @override
  String planFreqFixedDate(String date) {
    return 'Ngày $date';
  }

  @override
  String get planWindowMorning => 'Sáng sớm · 6–8h';

  @override
  String get planWindowAfternoon => 'Chiều mát · 16–18h';

  @override
  String get planWindowAllDay => 'Cả ngày';

  @override
  String get planWindowMorningShort => 'Sáng sớm';

  @override
  String get planWindowAfternoonShort => 'Chiều mát';

  @override
  String get planTaskAddTitle => 'Thêm việc';

  @override
  String get planTaskEditTitle => 'Sửa việc';

  @override
  String get planTaskCode => 'Loại việc';

  @override
  String get planTaskWindow => 'Khung giờ';

  @override
  String get planTaskFrequency => 'Tần suất';

  @override
  String get planTaskInterval => 'Cách nhau (ngày)';

  @override
  String get planTaskFixedDay => 'Ngày thứ (của project)';

  @override
  String get planTaskReminder => 'Nhắc lúc';

  @override
  String get planTaskNoReminder => 'Không nhắc';

  @override
  String get planTaskStage => 'Giai đoạn';

  @override
  String get planTaskDelete => 'Xóa việc';

  @override
  String get planTaskSaveError => 'Không lưu được. Thử lại nhé.';

  @override
  String get planCalendarTitle => 'Lịch chăm sóc';

  @override
  String planWeekLabel(String from, String to) {
    return 'Tuần $from–$to';
  }

  @override
  String get planPrevWeek => 'Tuần trước';

  @override
  String get planNextWeek => 'Tuần sau';

  @override
  String get planDow1 => 'T2';

  @override
  String get planDow2 => 'T3';

  @override
  String get planDow3 => 'T4';

  @override
  String get planDow4 => 'T5';

  @override
  String get planDow5 => 'T6';

  @override
  String get planDow6 => 'T7';

  @override
  String get planDow7 => 'CN';

  @override
  String planDayTasks(int count) {
    return '$count việc';
  }

  @override
  String planStageBanner(int n, String name, int from, int to, int left) {
    return 'Giai đoạn $n · $name (ngày $from–$to) · còn $left ngày';
  }

  @override
  String get planOutsideStages => 'Ngoài các giai đoạn của kế hoạch';

  @override
  String planDayLabel(String dow, String date) {
    return '$dow, $date';
  }

  @override
  String get planNoTasksDay => 'Không có việc trong ngày này';

  @override
  String get planAddManual => '+ Thêm việc thủ công';

  @override
  String get planTimeline => 'Các giai đoạn';

  @override
  String get projectDetailTabOverview => 'Tổng quan';

  @override
  String get projectDetailTabPlan => 'Plan';

  @override
  String get projectDetailTabCalendar => 'Lịch';

  @override
  String get projectDetailTabPhotos => 'Ảnh';

  @override
  String get projectDetailTabMembers => 'Thành viên';

  @override
  String projectDetailMeta(String group, int pots, String space, String sun) {
    return '$group · $pots chậu · $space $sun';
  }

  @override
  String get projectDetailShared => 'Chia sẻ với gia đình';

  @override
  String projectDetailStageCard(int n, int total, String name) {
    return 'Giai đoạn $n/$total · $name';
  }

  @override
  String projectDetailDay(int day, int total) {
    return 'Ngày $day/$total';
  }

  @override
  String projectDetailNextMilestone(String milestone, String date) {
    return 'Mốc tiếp theo: $milestone, dự kiến khoảng $date';
  }

  @override
  String get projectDetailStatDone => 'Việc đã xong';

  @override
  String get projectDetailStatCheckins => 'Lần check-in';

  @override
  String get projectDetailStatMilestones => 'Mốc đã đạt';

  @override
  String get projectDetailPhotos => 'Ảnh tăng trưởng';

  @override
  String get projectDetailPhotosEmpty =>
      'Ảnh check-in sẽ xuất hiện ở đây theo thời gian.';

  @override
  String projectDetailPhotoCount(int count) {
    return '$count ảnh';
  }

  @override
  String get projectDetailHistory => 'Lịch sử việc';

  @override
  String get projectDetailHistoryEmpty => 'Chưa có việc nào được ghi nhận.';

  @override
  String projectDetailHistoryLine(String task, String action) {
    return '$task · $action';
  }

  @override
  String get projectDetailMembers => 'Thành viên được giao việc';

  @override
  String get projectDetailNoMembers => 'Chưa giao việc cho ai.';

  @override
  String projectDetailMemberTasks(int count) {
    return '$count việc';
  }

  @override
  String get projectDetailNoPlan => 'Project này chưa có kế hoạch được duyệt.';

  @override
  String get projectDetailReviewPlan => 'Duyệt kế hoạch';

  @override
  String get projectDetailOpenPlan => 'Xem kế hoạch';

  @override
  String get projectDetailOpenCalendar => 'Mở lịch';

  @override
  String get projectDetailLoadError => 'Không tải được project. Thử lại nhé.';
}
