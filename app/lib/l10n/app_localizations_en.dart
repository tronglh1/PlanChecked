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
  String get todayTitle => 'Today';

  @override
  String todayGreeting(String name) {
    return 'Hi $name';
  }

  @override
  String get todayWd1 => 'Monday';

  @override
  String get todayWd2 => 'Tuesday';

  @override
  String get todayWd3 => 'Wednesday';

  @override
  String get todayWd4 => 'Thursday';

  @override
  String get todayWd5 => 'Friday';

  @override
  String get todayWd6 => 'Saturday';

  @override
  String get todayWd7 => 'Sunday';

  @override
  String todayProgress(int done, int total) {
    return '$done/$total tasks done';
  }

  @override
  String get todayXpHint => '+10 XP for each task done on time';

  @override
  String todayXpChip(int xp) {
    return '$xp XP today';
  }

  @override
  String get todayGroupByWindow => 'By time of day';

  @override
  String get todayGroupByProject => 'By project';

  @override
  String get todayWindowMorning => 'Early morning · 6–8am';

  @override
  String get todayWindowAfternoon => 'Cool afternoon · 4–6pm';

  @override
  String get todayWindowAllDay => 'All day';

  @override
  String get todayOverdue => 'Overdue';

  @override
  String get todayCheckinDueTitle => 'Photo check-in is due';

  @override
  String todayCheckinDueBody(String project) {
    return '$project · +30 XP';
  }

  @override
  String get todayEmptyTitle => 'Nothing to do today';

  @override
  String get todayEmptyBody => 'Start a new plant to get a daily care plan.';

  @override
  String get todayLoadError => 'Could not load today\'s tasks';

  @override
  String todayOfflineBanner(int count) {
    return 'Offline · $count changes will sync when you are back online';
  }

  @override
  String get todaySyncing => 'Syncing...';

  @override
  String get todayPendingSync => 'Waiting to sync';

  @override
  String get todaySkippedLabel => 'Skipped';

  @override
  String get todayMarkDone => 'Mark as done';

  @override
  String get todayMenu => 'More options';

  @override
  String todayXpToast(int xp) {
    return '+$xp XP';
  }

  @override
  String get todayXpToastLate => 'Done · late, so no XP';

  @override
  String get todayXpToastCap => 'Done · you reached today\'s 150 XP cap';

  @override
  String get todayActionError => 'Could not save that action';

  @override
  String get todayPermTitle => 'Turn on reminders?';

  @override
  String get todayPermBody =>
      'Vườn Nhà will remind you to care for your plants on time, even offline.';

  @override
  String get todayPermAllow => 'Turn on';

  @override
  String get todayPermLater => 'Not now';

  @override
  String todayNotifTitle(String window) {
    return 'Plant care time · $window';
  }

  @override
  String todayNotifMore(int count) {
    return '+$count more';
  }

  @override
  String todayNotifDailyTitle(int count) {
    return '$count plant tasks today';
  }

  @override
  String get todayNotifCheckinTitle => 'Photo check-in is due';

  @override
  String todayNotifCheckinBody(String project) {
    return 'Take a photo of $project to update the plan (+30 XP)';
  }

  @override
  String get taskSnooze => 'Snooze';

  @override
  String get taskSkipTitle => 'Skip this task?';

  @override
  String get taskSkipReasonHint => 'Reason (optional)';

  @override
  String get taskSkipReasonRain => 'Rainy';

  @override
  String get taskSkipReasonAway => 'Away from home';

  @override
  String get taskSkipReasonNotNeeded => 'Plant does not need it';

  @override
  String get taskSkipReasonOther => 'Other';

  @override
  String get taskSkipConfirm => 'Skip';

  @override
  String get taskSnoozeTitle => 'Snooze until when?';

  @override
  String get taskSnoozeTomorrow => 'Tomorrow';

  @override
  String get taskSnooze2Days => 'In 2 days';

  @override
  String get taskSnoozeNextWeek => 'Next week';

  @override
  String get taskTileWindow => 'Time of day';

  @override
  String get taskTileFrequency => 'Repeats';

  @override
  String get taskTileReminder => 'Remind at';

  @override
  String get taskFreqOnce => 'Once';

  @override
  String get taskFreqDaily => 'Daily';

  @override
  String taskFreqEveryN(int n) {
    return 'Every $n days';
  }

  @override
  String taskFreqFixed(int n) {
    return 'Day $n';
  }

  @override
  String get taskReminderByWindow => 'By time of day';

  @override
  String taskAssignedTo(String name) {
    return 'Assigned to $name';
  }

  @override
  String get taskUnassigned => 'Not assigned';

  @override
  String get taskChange => 'Change';

  @override
  String get taskAssign => 'Assign';

  @override
  String get taskHowTo => 'How to';

  @override
  String get taskWhy => 'Why?';

  @override
  String get taskNoSteps => 'No detailed instructions for this task yet.';

  @override
  String get taskSafetyGeneric =>
      'If you use packaged fertilizer or pesticide, follow the dose on the label. The app does not give specific chemical doses.';

  @override
  String get taskHistory => 'History';

  @override
  String get taskHistoryEmpty => 'No history yet';

  @override
  String get taskHistoryDone => 'Done';

  @override
  String get taskHistorySkip => 'Skipped';

  @override
  String get taskHistorySnooze => 'Snoozed';

  @override
  String taskDoneButton(int xp) {
    return 'Done · +$xp XP';
  }

  @override
  String get taskNotDueToday => 'This task is not due today';

  @override
  String get taskNotFound => 'Task not found';

  @override
  String get taskAssignPlaceholder =>
      'Assigning tasks will arrive in a later version.';

  @override
  String get taskCheckinPlaceholder =>
      'Photo check-ins will arrive in a later version.';
}
