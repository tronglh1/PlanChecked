// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Vườn Nhà';

  @override
  String get tabToday => 'Today';

  @override
  String get tabGarden => 'Garden';

  @override
  String get tabFamily => 'Family';

  @override
  String get tabAchievements => 'Achievements';

  @override
  String get tabSettings => 'Settings';

  @override
  String get commonDone => 'Done';

  @override
  String get commonSkip => 'Skip';

  @override
  String get commonSnooze => 'Snooze';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonSave => 'Save';

  @override
  String get commonContinue => 'Continue';

  @override
  String get commonRetry => 'Retry';

  @override
  String get commonLoading => 'Loading...';

  @override
  String get commonError => 'Something went wrong';

  @override
  String get emptyTitle => 'Nothing here yet';

  @override
  String get loginTitle => 'Sign in';

  @override
  String get configErrorTitle => 'Missing configuration';

  @override
  String get configErrorMessage =>
      'SUPABASE_URL / SUPABASE_ANON_KEY are not set. Run the app with --dart-define-from-file=env/dev.json.';

  @override
  String get placeholderComingSoon => 'Coming soon';

  @override
  String get loginTagline =>
      'An AI care plan made just for you: clear daily tasks, the whole family helps.';

  @override
  String get loginGoogle => 'Continue with Google';

  @override
  String get loginOr => 'or';

  @override
  String get loginEmailLabel => 'Email';

  @override
  String get loginEmailHint => 'you@email.com';

  @override
  String get loginSendCode => 'Get sign-in code';

  @override
  String get loginEmailInvalid => 'Enter a valid email';

  @override
  String get loginOtpTitle => 'Enter the code';

  @override
  String loginOtpSent(String email) {
    return 'We sent a 6-digit code to $email';
  }

  @override
  String get loginOtpLabel => '6-digit code';

  @override
  String get loginOtpVerify => 'Verify';

  @override
  String get loginOtpInvalid => 'The code has 6 digits';

  @override
  String get loginOtpWrong => 'The code is wrong or has expired';

  @override
  String get loginResend => 'Resend code';

  @override
  String get loginChangeEmail => 'Change email';

  @override
  String get loginError => 'Could not sign in. Please try again.';

  @override
  String get loginTermsPrefix => 'By continuing you agree to the ';

  @override
  String get loginTerms => 'Terms';

  @override
  String get loginTermsAnd => ' and ';

  @override
  String get loginPrivacy => 'Data Policy';

  @override
  String get loginTermsSuffix => ' (per Decree 13/2023/ND-CP).';

  @override
  String get profileStep => 'Step 1/2';

  @override
  String get profileTitle => 'Tell us a little about you';

  @override
  String get profileSub =>
      'Location helps the AI work out climate and season. The app only stores the province/city.';

  @override
  String get profileChangeAvatar => 'Change avatar';

  @override
  String get profileNameLabel => 'Display name';

  @override
  String get profileLocationLabel => 'Where do you grow plants?';

  @override
  String get profileLocationHint => 'Choose province/city';

  @override
  String get profileProvinceSearch => 'Search province/city';

  @override
  String get regionHelperSouth => 'Tropical climate, rainy season May–November';

  @override
  String get regionHelperNorth => 'Four distinct seasons, cold winters';

  @override
  String get regionHelperCentral =>
      'Hot and sunny, heavy rain late in the year';

  @override
  String get profileExperience => 'Gardening experience';

  @override
  String get expNew => 'Beginner';

  @override
  String get expMid => 'Intermediate';

  @override
  String get expPro => 'Experienced';

  @override
  String get profileLanguage => 'Language';

  @override
  String get langVi => 'Tiếng Việt';

  @override
  String get langEn => 'English';

  @override
  String get errorNameEmpty => 'Enter a display name';

  @override
  String get errorNameTooLong => 'Name can be at most 50 characters';

  @override
  String get errorProvince => 'Choose a province/city';

  @override
  String get profileSaveError =>
      'Could not save your profile. Please try again.';

  @override
  String get settingsEdit => 'Edit';

  @override
  String get settingsNotifications => 'NOTIFICATIONS';

  @override
  String get notifTask => 'Care task reminders';

  @override
  String get notifCheckin => 'Check-in photo reminders';

  @override
  String get notifAssignment => 'Task assigned to me';

  @override
  String get notifAchievement => 'Achievements & badges';

  @override
  String get notifBundle => 'Bundle notifications once a day';

  @override
  String get settingsOther => 'OTHER';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsLeaveHousehold => 'Leave household';

  @override
  String get settingsSignOut => 'Sign out';

  @override
  String get settingsDeleteAccount => 'Delete account and all data';

  @override
  String get deleteConfirm1Title => 'Delete account?';

  @override
  String get deleteConfirm1Body =>
      'All your projects, check-ins, photos and achievements will be deleted.';

  @override
  String get deleteConfirm2Title => 'Are you absolutely sure?';

  @override
  String get deleteConfirm2Body => 'This cannot be undone.';

  @override
  String get deleteConfirmAction => 'Delete permanently';

  @override
  String get deleteError => 'Could not delete the account. Please try again.';

  @override
  String get searchEyebrow => 'New plant · Step 1/3';

  @override
  String get searchTitle => 'What do you want to grow?';

  @override
  String get searchFieldLabel => 'Plant name';

  @override
  String get filterAll => 'All';

  @override
  String get filterVeg => 'Vegetables & fruit';

  @override
  String get filterOrnamental => 'Indoor ornamentals';

  @override
  String searchCount(int count, String query) {
    return '$count results for “$query”';
  }

  @override
  String searchCountAll(int count) {
    return '$count plants';
  }

  @override
  String get diffEasy => 'Easy';

  @override
  String get diffMedium => 'Medium';

  @override
  String get diffHard => 'Hard';

  @override
  String harvestDays(int days) {
    return 'Harvest ~$days days';
  }

  @override
  String get searchNotFoundTitle => 'Can’t find your plant?';

  @override
  String searchDidYouMean(String query) {
    return 'You typed “$query”. Did you mean…?';
  }

  @override
  String get searchYes => 'Yes, that’s it';

  @override
  String get searchNo => 'No';

  @override
  String searchFreeText(String query) {
    return 'Use “$query”';
  }

  @override
  String get searchFreeTextHint =>
      'Not in the list? The AI will plan this plant in the next step.';

  @override
  String get searchLoadError => 'Could not load the plant list';

  @override
  String get contextTitle => 'Growing details & context';

  @override
  String get householdSetupStep => 'Step 2/2';

  @override
  String get householdSetupSkip => 'Skip';

  @override
  String get householdSetupTitle => 'Grow plants together?';

  @override
  String get householdSetupSub =>
      'Create a household to assign watering and feeding to each person and see who did what. You can do this later.';

  @override
  String get householdCreateTitle => 'Create a new household';

  @override
  String get householdCreateSub => 'You are the household Owner';

  @override
  String get householdJoinTitle => 'Join with an invite code';

  @override
  String get householdJoinSub => 'You will be a Member';

  @override
  String get householdJoinHint => 'e.g. VUON-4821';

  @override
  String get householdJoinAction => 'Join';

  @override
  String get householdSetupFooter =>
      'Each person can be in one household only. There are no public friend lists.';

  @override
  String get householdNameLabel => 'Household name';

  @override
  String get householdNameDefault => 'Our home';

  @override
  String get householdCreateAction => 'Create household';

  @override
  String get householdErrorGeneric => 'That did not work. Please try again.';

  @override
  String get householdErrorInvalidCode => 'Invalid invite code';

  @override
  String get householdErrorExpired => 'This invite has expired';

  @override
  String get householdErrorAlreadyIn => 'You are already in a household';

  @override
  String get householdErrorTooMany =>
      'Too many wrong attempts, try again in an hour';

  @override
  String get householdErrorCodeFormat => 'Codes look like VUON-1234';

  @override
  String get householdJoined => 'You joined the household';

  @override
  String householdEyebrow(int count) {
    return 'Household · $count people';
  }

  @override
  String get householdInvite => '+ Invite';

  @override
  String get householdRoleOwner => 'Owner';

  @override
  String get householdRoleMember => 'Member';

  @override
  String householdYou(String name) {
    return '$name (you)';
  }

  @override
  String householdTasksWeek(int count) {
    return '$count tasks this week';
  }

  @override
  String get householdAway => 'away';

  @override
  String get householdSharedProjects => 'Shared projects';

  @override
  String get householdNoShared => 'No shared projects yet';

  @override
  String get householdShareMore => '+ Share more';

  @override
  String get householdShareTitle => 'Share a project with the household';

  @override
  String get householdShare => 'Share';

  @override
  String get householdUnshare => 'Stop sharing';

  @override
  String get householdShareOwnerOnly => 'Only the Owner can share projects';

  @override
  String get householdShareNoProjects => 'You have no projects to share';

  @override
  String get householdActivity => 'Activity';

  @override
  String get householdActivityEmpty => 'No activity yet';

  @override
  String householdActTaskDone(String name) {
    return '$name completed a task';
  }

  @override
  String householdActCheckin(String name) {
    return '$name posted a check-in';
  }

  @override
  String householdActMilestone(String name) {
    return '$name reached a milestone';
  }

  @override
  String householdActJoined(String name) {
    return '$name joined the household';
  }

  @override
  String householdActLeft(String name) {
    return '$name left the household';
  }

  @override
  String householdActShared(String name, String project) {
    return '$name shared “$project”';
  }

  @override
  String householdActProject(String text, String project) {
    return '$text · $project';
  }

  @override
  String get householdSomeone => 'A member';

  @override
  String get householdRemoveMember => 'Remove from household';

  @override
  String householdRemoveTitle(String name) {
    return 'Remove $name?';
  }

  @override
  String get householdRemoveBody =>
      'Projects they shared become private again.';

  @override
  String get householdLoadError => 'Could not load the household';

  @override
  String get householdNoneTitle => 'You are not in a household';

  @override
  String get householdNoneSub =>
      'Create one or enter an invite code to grow together.';

  @override
  String get householdInviteTitle => 'Invite family';

  @override
  String householdInviteCodeLabel(String name) {
    return 'Invite code for $name';
  }

  @override
  String householdInviteExpires(int days) {
    return 'Expires in $days days';
  }

  @override
  String get householdInviteCopy => 'Copy code';

  @override
  String get householdInviteCopied => 'Code copied';

  @override
  String get householdInviteShareLink => 'Share invite link';

  @override
  String householdInviteShareText(
    String inviter,
    String name,
    String code,
    String link,
  ) {
    return '$inviter invites you to grow plants together in “$name” on Vườn Nhà. Code: $code. Open: $link';
  }

  @override
  String get householdInviteOr => 'or invite directly';

  @override
  String get householdInviteTargetLabel => 'Phone or email';

  @override
  String get householdInviteTargetHint => '09xx xxx xxx';

  @override
  String get householdInviteRole => 'Role';

  @override
  String get householdInviteRoleMemberDesc =>
      'Does assigned tasks, sees shared projects';

  @override
  String get householdInviteRoleOwnerDesc =>
      'Manages members, projects and assignments';

  @override
  String get householdInviteSend => 'Send invite';

  @override
  String householdInviteEmailSent(String target) {
    return 'Invite emailed to $target';
  }

  @override
  String get householdInviteEmailFailed =>
      'Email could not be sent. Use the share button instead.';

  @override
  String get householdInviteTargetInvalid =>
      'Enter a valid email or phone number';

  @override
  String get householdInviteOwnerOnly => 'Only the Owner can invite people';

  @override
  String get householdInviteLoading => 'Creating invite...';

  @override
  String get householdAssignTitle => 'Assign task';

  @override
  String get householdAssignHow => 'Assign how';

  @override
  String get householdModeOnce => 'Just once';

  @override
  String get householdModeSeries => 'Whole series';

  @override
  String get householdModeRotation => 'Rotate';

  @override
  String get householdAssignOrder => 'Rotation order';

  @override
  String get householdAssignTo => 'Assign to';

  @override
  String householdAssignAwayUntil(String date) {
    return 'Away until $date';
  }

  @override
  String householdAssignHintRotation(String names) {
    return 'Rotation: $names → repeat.';
  }

  @override
  String householdAssignHintSeries(String task, String name) {
    return 'Every upcoming “$task” goes to $name.';
  }

  @override
  String householdAssignHintOnce(String task, String name) {
    return 'Only the next “$task” goes to $name.';
  }

  @override
  String get householdAssignDone => 'Task assigned';

  @override
  String get householdAssignOwnerOnly => 'Only the Owner can assign tasks';

  @override
  String get householdAssignNeedHousehold =>
      'Create or join a household to assign tasks';

  @override
  String get householdAssignNoTask => 'Task not found';

  @override
  String get householdAssignRotationMin => 'Pick at least 2 people to rotate';

  @override
  String get householdAssignPickOne => 'Pick a person';

  @override
  String get householdWindowMorning => 'Early morning';

  @override
  String get householdWindowAfternoon => 'Cool afternoon';

  @override
  String get householdWindowAllDay => 'All day';

  @override
  String householdEveryDays(int n) {
    return 'every $n days';
  }

  @override
  String householdLeaveRow(String name) {
    return 'Leave household “$name”';
  }

  @override
  String get householdLeaveTitle => 'Leave the household?';

  @override
  String get householdLeaveBody =>
      'You will no longer see shared projects. Your own projects become private.';

  @override
  String householdLeaveOwnerBody(String name) {
    return 'Ownership passes to $name, the longest-standing member.';
  }

  @override
  String get householdLeaveLast =>
      'You are the last member, so the household will be deleted.';

  @override
  String get householdLeaveAction => 'Leave';

  @override
  String get householdLeft => 'You left the household';

  @override
  String get householdJoinScreenTitle => 'Join a household';

  @override
  String householdJoinLinkBody(String code) {
    return 'You were invited with code $code';
  }

  @override
  String get householdJoinConfirm => 'Join';

  @override
  String get gamTitle => 'Achievements';

  @override
  String get gamTotalXp => 'Total points';

  @override
  String gamXpUnit(String xp) {
    return '$xp XP';
  }

  @override
  String get gamLevelLabel => 'Level';

  @override
  String gamLevelLine(int level, String name) {
    return 'Level $level · $name';
  }

  @override
  String gamToNext(int xp, int level, String name) {
    return '$xp XP to Level $level · $name';
  }

  @override
  String get gamTopLevel => 'You reached the top level';

  @override
  String gamStreak(int days) {
    return '$days-day streak';
  }

  @override
  String get gamStreakNone => 'No streak yet';

  @override
  String get gamOnTime => 'On-time tasks';

  @override
  String get gamCheckin => 'Photo check-ins';

  @override
  String get gamMilestone => 'Milestones';

  @override
  String get gamToday => 'Today';

  @override
  String gamTodayCap(int xp, int cap) {
    return '$xp/$cap XP';
  }

  @override
  String gamAntiCheat(int cap) {
    return 'Up to $cap XP per day from regular tasks. Milestone points only count with a photo check-in as proof.';
  }

  @override
  String gamPendingPhoto(int count) {
    return '$count milestone(s) wait for a photo check-in and earn no XP yet.';
  }

  @override
  String gamBadges(int earned, int total) {
    return 'Badges · $earned/$total';
  }

  @override
  String get gamBadgesEmpty => 'No badges yet';

  @override
  String get gamBadgeLocked => 'Locked';

  @override
  String get gamLoadError => 'Could not load achievements';

  @override
  String get gamMilestoneEyebrow => 'NEW MILESTONE';

  @override
  String get gamMilestoneUnknown => 'New milestone';

  @override
  String gamMilestoneBody(String project) {
    return '$project passed a new milestone. A check-in photo confirmed it.';
  }

  @override
  String gamMilestoneBodyPending(String project) {
    return '$project logged this milestone, but no check-in photo has confirmed it yet.';
  }

  @override
  String gamRewardXp(int xp) {
    return '+$xp XP';
  }

  @override
  String get gamRewardPending => 'Needs photo';

  @override
  String get gamRewardMilestone => 'Milestone';

  @override
  String get gamRewardBadge => 'Badge';

  @override
  String get gamRewardNoBadge => 'None yet';

  @override
  String get gamPendingNote =>
      'Milestone XP is only awarded when a check-in photo confirms it. Post a photo check-in to earn it.';

  @override
  String get gamKeepsake => 'Keepsake';

  @override
  String get gamKeepsakeCard => 'Keepsake card';

  @override
  String get gamKeepsakeSub => 'Ready to share';

  @override
  String get gamShare => 'Share keepsake';

  @override
  String gamShareText(String project, String milestone) {
    return '$project just reached “$milestone” on Vườn Nhà!';
  }

  @override
  String get gamShareError => 'Could not share';

  @override
  String get gamViewAchievements => 'View achievements';
}
