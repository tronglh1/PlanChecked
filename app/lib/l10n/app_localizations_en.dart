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
  String get projectsTitle => 'My garden';

  @override
  String projectsFilterActive(int count) {
    return 'Growing · $count';
  }

  @override
  String projectsFilterDone(int count) {
    return 'Done · $count';
  }

  @override
  String get projectsFilterArchived => 'Archived';

  @override
  String get projectsEmptyTitle => 'No plants yet';

  @override
  String get projectsEmptyMessage =>
      'Start your first plant and AI will draft a care plan for you.';

  @override
  String get projectsAddNew => 'Plant something new';

  @override
  String get projectsLoadError =>
      'Couldn\'t load your garden. Please try again.';

  @override
  String projectsKindLine(String group, int pots, int day) {
    return '$group · $pots pots · day $day';
  }

  @override
  String get projectsNoPlan => 'No plan yet';

  @override
  String get projectsPlanPending => 'Plan awaiting review';

  @override
  String get projectsStageBeforeStart => 'Starting soon';

  @override
  String projectsTasksToday(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tasks today',
      one: '1 task today',
    );
    return '$_temp0';
  }

  @override
  String projectsPhotoAgo(int days) {
    return 'Photo: $days days ago';
  }

  @override
  String get projectsPhotoToday => 'Photo: today';

  @override
  String get projectsNoPhoto => 'No photo yet';

  @override
  String get projectsLatestPhoto => 'Latest photo';

  @override
  String get projectsContextEyebrow => 'New plant · Step 2/3';

  @override
  String projectsContextTitle(String plant) {
    return 'Where will you grow $plant?';
  }

  @override
  String get projectsContextTitleNoPlant => 'Where will you grow it?';

  @override
  String get projectsFieldName => 'Project name';

  @override
  String get projectsFieldStartDate => 'Start date';

  @override
  String get projectsFieldPots => 'Pots';

  @override
  String get projectsFieldStartStage => 'Starting from';

  @override
  String get projectsStartSeed => 'Seeds';

  @override
  String get projectsStartSeedling => 'Seedling';

  @override
  String get projectsStartMature => 'Mature plant';

  @override
  String get projectsFieldSpace => 'Where';

  @override
  String get projectsSpaceIndoor => 'Indoors';

  @override
  String get projectsSpaceBalcony => 'Balcony';

  @override
  String get projectsSpaceYard => 'Yard';

  @override
  String get projectsSpaceRooftop => 'Rooftop';

  @override
  String get projectsFieldSun => 'Sun per day';

  @override
  String get projectsSunLow => 'Under 3 hours';

  @override
  String get projectsSunMedium => '3–6 hours';

  @override
  String get projectsSunHigh => 'Over 6 hours';

  @override
  String get projectsFieldPot => 'Pot / soil';

  @override
  String get projectsPotDefault => '20L plastic pot, mixed soil';

  @override
  String get projectsFieldWatering => 'Watering';

  @override
  String get projectsWateringManual => 'By hand';

  @override
  String get projectsWateringAuto => 'Automatic';

  @override
  String get projectsCoverAdd => 'Add a cover photo (optional)';

  @override
  String get projectsCoverAdded => 'Cover photo selected';

  @override
  String get projectsCreatePlan => 'Create care plan';

  @override
  String get projectsNameRequired => 'Please name your project';

  @override
  String get projectsCreateError =>
      'Couldn\'t create the project. Please try again.';

  @override
  String projectsDefaultName(String plant, int month, int year) {
    return '$plant – $month/$year';
  }

  @override
  String get projectsPotsMinus => 'Fewer pots';

  @override
  String get projectsPotsPlus => 'More pots';

  @override
  String get planGeneratingEyebrow => 'New plant · Step 3/3';

  @override
  String get planGeneratingTitle => 'Building a plan for';

  @override
  String get planGeneratingHint => 'Usually takes under 20 seconds';

  @override
  String get planGenStep1 => 'Reading the plant\'s reference data';

  @override
  String get planGenStep1Sub => 'From the Vườn Nhà plant database';

  @override
  String get planGenStep2 => 'Checking climate and season';

  @override
  String get planGenStep2Sub => 'Based on your region and start month';

  @override
  String get planGenStep3 => 'Splitting stages and milestones';

  @override
  String get planGenStep3Sub => 'From start to harvest';

  @override
  String get planGenStep4 => 'Creating daily care tasks';

  @override
  String get planGenStep4Sub => 'Scheduled for early morning / cool afternoon';

  @override
  String get planGeneratingFallbackNote =>
      'If AI has a problem, the app uses a template plan so you can start right away.';

  @override
  String get planViewPlan => 'View plan';

  @override
  String get planGenFailedTitle => 'AI is having trouble';

  @override
  String get planGenFailedMessage =>
      'You can start with a template plan right away, or try again.';

  @override
  String get planUseTemplate => 'Use template plan';

  @override
  String get planFallbackAiFailure =>
      'AI had a problem, so the app used a template plan for you.';

  @override
  String get planFallbackQuota =>
      'You\'ve used today\'s AI limit, so the app used a template plan for you.';

  @override
  String planReviewTitle(int days) {
    return '$days-day plan';
  }

  @override
  String get planAiLabel => 'AI suggestion';

  @override
  String get planTemplateLabel => 'Template plan';

  @override
  String planConfidenceHigh(int pct) {
    return 'High confidence · $pct%';
  }

  @override
  String planConfidenceMedium(int pct) {
    return 'Medium confidence · $pct%';
  }

  @override
  String planConfidenceLow(int pct) {
    return 'Low confidence · $pct%';
  }

  @override
  String planSources(String sources) {
    return 'Sources: $sources';
  }

  @override
  String get planSourcesDefault => 'Vườn Nhà plant database';

  @override
  String get planSegStages => 'Stages';

  @override
  String get planSegCalendar => 'Calendar';

  @override
  String planStageDays(int from, int to) {
    return 'Day $from–$to';
  }

  @override
  String planStageMilestone(String milestone) {
    return 'Milestone: $milestone';
  }

  @override
  String planStageTaskCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tasks',
      one: '1 task',
    );
    return '$_temp0';
  }

  @override
  String get planAddTask => '+ Add task';

  @override
  String get planStart => 'Start growing';

  @override
  String get planApproveError =>
      'Couldn\'t approve the plan. Please try again.';

  @override
  String get planSafetyTitle => 'Safety notes';

  @override
  String get planSafetyOrganic =>
      'Safe, organic options come first. The app doesn\'t give fertilizer or pesticide doses: follow the product label.';

  @override
  String get planEmpty => 'This project has no plan yet';

  @override
  String get planLoadError => 'Couldn\'t load the plan. Please try again.';

  @override
  String get planFreqOnce => 'Once';

  @override
  String get planFreqDaily => 'Daily';

  @override
  String planFreqEveryN(int n) {
    return 'Every $n days';
  }

  @override
  String planFreqFixedDay(int day) {
    return 'Day $day';
  }

  @override
  String planFreqFixedDate(String date) {
    return 'On $date';
  }

  @override
  String get planWindowMorning => 'Early morning · 6–8am';

  @override
  String get planWindowAfternoon => 'Cool afternoon · 4–6pm';

  @override
  String get planWindowAllDay => 'All day';

  @override
  String get planWindowMorningShort => 'Morning';

  @override
  String get planWindowAfternoonShort => 'Afternoon';

  @override
  String get planTaskAddTitle => 'Add a task';

  @override
  String get planTaskEditTitle => 'Edit task';

  @override
  String get planTaskCode => 'Task';

  @override
  String get planTaskWindow => 'Time of day';

  @override
  String get planTaskFrequency => 'Frequency';

  @override
  String get planTaskInterval => 'Every (days)';

  @override
  String get planTaskFixedDay => 'Project day';

  @override
  String get planTaskReminder => 'Remind at';

  @override
  String get planTaskNoReminder => 'No reminder';

  @override
  String get planTaskStage => 'Stage';

  @override
  String get planTaskDelete => 'Delete task';

  @override
  String get planTaskSaveError => 'Couldn\'t save. Please try again.';

  @override
  String get planCalendarTitle => 'Care calendar';

  @override
  String planWeekLabel(String from, String to) {
    return 'Week $from–$to';
  }

  @override
  String get planPrevWeek => 'Previous week';

  @override
  String get planNextWeek => 'Next week';

  @override
  String get planDow1 => 'Mon';

  @override
  String get planDow2 => 'Tue';

  @override
  String get planDow3 => 'Wed';

  @override
  String get planDow4 => 'Thu';

  @override
  String get planDow5 => 'Fri';

  @override
  String get planDow6 => 'Sat';

  @override
  String get planDow7 => 'Sun';

  @override
  String planDayTasks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tasks',
      one: '1 task',
    );
    return '$_temp0';
  }

  @override
  String planStageBanner(int n, String name, int from, int to, int left) {
    return 'Stage $n · $name (day $from–$to) · $left days left';
  }

  @override
  String get planOutsideStages => 'Outside the plan\'s stages';

  @override
  String planDayLabel(String dow, String date) {
    return '$dow, $date';
  }

  @override
  String get planNoTasksDay => 'No tasks on this day';

  @override
  String get planAddManual => '+ Add a task manually';

  @override
  String get planTimeline => 'Stages';

  @override
  String get projectDetailTabOverview => 'Overview';

  @override
  String get projectDetailTabPlan => 'Plan';

  @override
  String get projectDetailTabCalendar => 'Calendar';

  @override
  String get projectDetailTabPhotos => 'Photos';

  @override
  String get projectDetailTabMembers => 'Members';

  @override
  String projectDetailMeta(String group, int pots, String space, String sun) {
    return '$group · $pots pots · $space $sun';
  }

  @override
  String get projectDetailShared => 'Shared with household';

  @override
  String projectDetailStageCard(int n, int total, String name) {
    return 'Stage $n/$total · $name';
  }

  @override
  String projectDetailDay(int day, int total) {
    return 'Day $day/$total';
  }

  @override
  String projectDetailNextMilestone(String milestone, String date) {
    return 'Next milestone: $milestone, around $date';
  }

  @override
  String get projectDetailStatDone => 'Tasks done';

  @override
  String get projectDetailStatCheckins => 'Check-ins';

  @override
  String get projectDetailStatMilestones => 'Milestones';

  @override
  String get projectDetailPhotos => 'Growth photos';

  @override
  String get projectDetailPhotosEmpty =>
      'Your check-in photos will appear here over time.';

  @override
  String projectDetailPhotoCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count photos',
      one: '1 photo',
    );
    return '$_temp0';
  }

  @override
  String get projectDetailHistory => 'Task history';

  @override
  String get projectDetailHistoryEmpty => 'No tasks logged yet.';

  @override
  String projectDetailHistoryLine(String task, String action) {
    return '$task · $action';
  }

  @override
  String get projectDetailMembers => 'Members with tasks';

  @override
  String get projectDetailNoMembers => 'No tasks assigned yet.';

  @override
  String projectDetailMemberTasks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tasks',
      one: '1 task',
    );
    return '$_temp0';
  }

  @override
  String get projectDetailNoPlan => 'This project has no approved plan yet.';

  @override
  String get projectDetailReviewPlan => 'Review plan';

  @override
  String get projectDetailOpenPlan => 'Open plan';

  @override
  String get projectDetailOpenCalendar => 'Open calendar';

  @override
  String get projectDetailLoadError =>
      'Couldn\'t load the project. Please try again.';
}
