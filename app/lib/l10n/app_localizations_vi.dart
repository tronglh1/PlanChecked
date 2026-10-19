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
  String get householdSetupStep => 'Bước 2/2';

  @override
  String get householdSetupSkip => 'Bỏ qua';

  @override
  String get householdSetupTitle => 'Chăm cây cùng người nhà?';

  @override
  String get householdSetupSub =>
      'Tạo gia đình để giao việc tưới, bón cho từng người và xem ai đã làm gì. Bạn có thể làm việc này sau.';

  @override
  String get householdCreateTitle => 'Tạo gia đình mới';

  @override
  String get householdCreateSub => 'Bạn là chủ nhà (Owner)';

  @override
  String get householdJoinTitle => 'Tham gia bằng mã mời';

  @override
  String get householdJoinSub => 'Bạn sẽ là thành viên (Member)';

  @override
  String get householdJoinHint => 'VD: VUON-4821';

  @override
  String get householdJoinAction => 'Vào';

  @override
  String get householdSetupFooter =>
      'Mỗi người chỉ ở trong một gia đình. App không có kết bạn công khai.';

  @override
  String get householdNameLabel => 'Tên gia đình';

  @override
  String get householdNameDefault => 'Nhà mình';

  @override
  String get householdCreateAction => 'Tạo gia đình';

  @override
  String get householdErrorGeneric => 'Chưa thực hiện được. Thử lại nhé.';

  @override
  String get householdErrorInvalidCode => 'Mã mời không đúng';

  @override
  String get householdErrorExpired => 'Mã mời đã hết hạn';

  @override
  String get householdErrorAlreadyIn => 'Bạn đã ở trong một gia đình';

  @override
  String get householdErrorTooMany =>
      'Nhập sai quá nhiều lần, thử lại sau 1 giờ';

  @override
  String get householdErrorCodeFormat => 'Mã có dạng VUON-1234';

  @override
  String get householdJoined => 'Đã tham gia gia đình';

  @override
  String householdEyebrow(int count) {
    return 'Gia đình · $count người';
  }

  @override
  String get householdInvite => '+ Mời';

  @override
  String get householdRoleOwner => 'Owner';

  @override
  String get householdRoleMember => 'Member';

  @override
  String householdYou(String name) {
    return '$name (bạn)';
  }

  @override
  String householdTasksWeek(int count) {
    return '$count việc tuần này';
  }

  @override
  String get householdAway => 'đang vắng nhà';

  @override
  String get householdSharedProjects => 'Project chia sẻ';

  @override
  String get householdNoShared => 'Chưa chia sẻ project nào';

  @override
  String get householdShareMore => '+ Chia sẻ thêm';

  @override
  String get householdShareTitle => 'Chia sẻ project với gia đình';

  @override
  String get householdShare => 'Chia sẻ';

  @override
  String get householdUnshare => 'Ngừng chia sẻ';

  @override
  String get householdShareOwnerOnly => 'Chỉ Owner mới chia sẻ được project';

  @override
  String get householdShareNoProjects => 'Bạn chưa có project nào để chia sẻ';

  @override
  String get householdActivity => 'Hoạt động';

  @override
  String get householdActivityEmpty => 'Chưa có hoạt động nào';

  @override
  String householdActTaskDone(String name) {
    return '$name đã hoàn thành một việc';
  }

  @override
  String householdActCheckin(String name) {
    return '$name đã check-in ảnh';
  }

  @override
  String householdActMilestone(String name) {
    return '$name đạt mốc mới';
  }

  @override
  String householdActJoined(String name) {
    return '$name đã tham gia gia đình';
  }

  @override
  String householdActLeft(String name) {
    return '$name đã rời gia đình';
  }

  @override
  String householdActShared(String name, String project) {
    return '$name chia sẻ project “$project”';
  }

  @override
  String householdActProject(String text, String project) {
    return '$text · $project';
  }

  @override
  String get householdSomeone => 'Một thành viên';

  @override
  String get householdRemoveMember => 'Xóa khỏi gia đình';

  @override
  String householdRemoveTitle(String name) {
    return 'Xóa $name khỏi gia đình?';
  }

  @override
  String get householdRemoveBody => 'Project họ chia sẻ sẽ trở lại riêng tư.';

  @override
  String get householdLoadError => 'Không tải được gia đình';

  @override
  String get householdNoneTitle => 'Bạn chưa có gia đình';

  @override
  String get householdNoneSub =>
      'Tạo gia đình mới hoặc nhập mã mời để cùng chăm cây.';

  @override
  String get householdInviteTitle => 'Mời người nhà';

  @override
  String householdInviteCodeLabel(String name) {
    return 'Mã mời của $name';
  }

  @override
  String householdInviteExpires(int days) {
    return 'Hết hạn sau $days ngày';
  }

  @override
  String get householdInviteCopy => 'Sao chép mã';

  @override
  String get householdInviteCopied => 'Đã sao chép mã';

  @override
  String get householdInviteShareLink => 'Gửi link mời';

  @override
  String householdInviteShareText(
    String inviter,
    String name,
    String code,
    String link,
  ) {
    return '$inviter mời bạn cùng chăm cây trong “$name” trên Vườn Nhà. Mã: $code. Mở: $link';
  }

  @override
  String get householdInviteOr => 'hoặc mời trực tiếp';

  @override
  String get householdInviteTargetLabel => 'Số điện thoại hoặc email';

  @override
  String get householdInviteTargetHint => '09xx xxx xxx';

  @override
  String get householdInviteRole => 'Vai trò';

  @override
  String get householdInviteRoleMemberDesc =>
      'Làm việc được giao, xem project được chia sẻ';

  @override
  String get householdInviteRoleOwnerDesc =>
      'Quản lý thành viên, project và giao việc';

  @override
  String get householdInviteSend => 'Gửi lời mời';

  @override
  String householdInviteEmailSent(String target) {
    return 'Đã gửi email mời tới $target';
  }

  @override
  String get householdInviteEmailFailed =>
      'Chưa gửi được email. Hãy dùng nút gửi link.';

  @override
  String get householdInviteTargetInvalid =>
      'Nhập email hợp lệ hoặc số điện thoại';

  @override
  String get householdInviteOwnerOnly => 'Chỉ Owner mới mời được người nhà';

  @override
  String get householdInviteLoading => 'Đang tạo mã mời...';

  @override
  String get householdAssignTitle => 'Giao việc';

  @override
  String get householdAssignHow => 'Cách giao';

  @override
  String get householdModeOnce => 'Chỉ lần này';

  @override
  String get householdModeSeries => 'Cả chuỗi lặp';

  @override
  String get householdModeRotation => 'Xoay vòng';

  @override
  String get householdAssignOrder => 'Thứ tự xoay vòng';

  @override
  String get householdAssignTo => 'Giao cho';

  @override
  String householdAssignAwayUntil(String date) {
    return 'Vắng nhà đến $date';
  }

  @override
  String householdAssignHintRotation(String names) {
    return 'Xoay vòng: $names → lặp lại.';
  }

  @override
  String householdAssignHintSeries(String task, String name) {
    return 'Mọi lần “$task” tiếp theo sẽ giao cho $name.';
  }

  @override
  String householdAssignHintOnce(String task, String name) {
    return 'Chỉ lần “$task” tới giao cho $name.';
  }

  @override
  String get householdAssignDone => 'Đã giao việc';

  @override
  String get householdAssignOwnerOnly => 'Chỉ Owner mới giao được việc';

  @override
  String get householdAssignNeedHousehold =>
      'Hãy tạo hoặc tham gia gia đình để giao việc';

  @override
  String get householdAssignNoTask => 'Không tìm thấy việc này';

  @override
  String get householdAssignRotationMin => 'Chọn ít nhất 2 người để xoay vòng';

  @override
  String get householdAssignPickOne => 'Chọn một người';

  @override
  String get householdWindowMorning => 'Sáng sớm';

  @override
  String get householdWindowAfternoon => 'Chiều mát';

  @override
  String get householdWindowAllDay => 'Cả ngày';

  @override
  String householdEveryDays(int n) {
    return '$n ngày/lần';
  }

  @override
  String householdLeaveRow(String name) {
    return 'Rời gia đình “$name”';
  }

  @override
  String get householdLeaveTitle => 'Rời gia đình?';

  @override
  String get householdLeaveBody =>
      'Bạn sẽ không còn thấy project chia sẻ. Project của bạn trở lại riêng tư.';

  @override
  String householdLeaveOwnerBody(String name) {
    return 'Quyền Owner sẽ chuyển cho $name, thành viên lâu nhất.';
  }

  @override
  String get householdLeaveLast =>
      'Bạn là người cuối cùng, nên gia đình sẽ bị xóa.';

  @override
  String get householdLeaveAction => 'Rời gia đình';

  @override
  String get householdLeft => 'Đã rời gia đình';

  @override
  String get householdJoinScreenTitle => 'Tham gia gia đình';

  @override
  String householdJoinLinkBody(String code) {
    return 'Bạn được mời bằng mã $code';
  }

  @override
  String get householdJoinConfirm => 'Tham gia';

  @override
  String get gamTitle => 'Thành tích';

  @override
  String get gamTotalXp => 'Tổng điểm';

  @override
  String gamXpUnit(String xp) {
    return '$xp XP';
  }

  @override
  String get gamLevelLabel => 'Level';

  @override
  String gamLevelLine(int level, String name) {
    return 'Cấp $level · $name';
  }

  @override
  String gamToNext(int xp, int level, String name) {
    return 'Còn $xp XP để lên Cấp $level · $name';
  }

  @override
  String get gamTopLevel => 'Bạn đã đạt cấp cao nhất';

  @override
  String gamStreak(int days) {
    return '$days ngày liên tục';
  }

  @override
  String get gamStreakNone => 'Chưa có chuỗi ngày';

  @override
  String get gamOnTime => 'Việc đúng hạn';

  @override
  String get gamCheckin => 'Check-in ảnh';

  @override
  String get gamMilestone => 'Đạt milestone';

  @override
  String get gamToday => 'Hôm nay';

  @override
  String gamTodayCap(int xp, int cap) {
    return '$xp/$cap XP';
  }

  @override
  String gamAntiCheat(int cap) {
    return 'Mỗi ngày tối đa $cap XP từ việc thường. Điểm milestone chỉ cộng khi có ảnh check-in xác nhận.';
  }

  @override
  String gamPendingPhoto(int count) {
    return '$count mốc đang chờ ảnh check-in xác nhận, chưa tính XP.';
  }

  @override
  String gamBadges(int earned, int total) {
    return 'Huy hiệu · $earned/$total';
  }

  @override
  String get gamBadgesEmpty => 'Chưa có huy hiệu nào';

  @override
  String get gamBadgeLocked => 'Chưa đạt';

  @override
  String get gamLoadError => 'Không tải được thành tích';

  @override
  String get gamMilestoneEyebrow => 'ĐẠT MỐC MỚI';

  @override
  String get gamMilestoneUnknown => 'Mốc mới';

  @override
  String gamMilestoneBody(String project) {
    return '$project đã qua một mốc mới. Ảnh check-in hôm nay đã xác nhận.';
  }

  @override
  String gamMilestoneBodyPending(String project) {
    return '$project ghi nhận mốc này, nhưng chưa có ảnh check-in xác nhận.';
  }

  @override
  String gamRewardXp(int xp) {
    return '+$xp XP';
  }

  @override
  String get gamRewardPending => 'Chờ ảnh';

  @override
  String get gamRewardMilestone => 'Milestone';

  @override
  String get gamRewardBadge => 'Huy hiệu';

  @override
  String get gamRewardNoBadge => 'Chưa có';

  @override
  String get gamPendingNote =>
      'Điểm milestone chỉ cộng khi có ảnh check-in xác nhận. Hãy check-in ảnh để nhận XP.';

  @override
  String get gamKeepsake => 'Ảnh kỷ niệm';

  @override
  String get gamKeepsakeCard => 'Thẻ kỷ niệm';

  @override
  String get gamKeepsakeSub => 'Có thể chia sẻ';

  @override
  String get gamShare => 'Chia sẻ ảnh kỷ niệm';

  @override
  String gamShareText(String project, String milestone) {
    return '$project vừa đạt mốc “$milestone” trên Vườn Nhà!';
  }

  @override
  String get gamShareError => 'Chưa chia sẻ được';

  @override
  String get gamViewAchievements => 'Xem thành tích';
}
