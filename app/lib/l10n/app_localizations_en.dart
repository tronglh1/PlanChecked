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
    return 'Email sent to $email. Tap its link or enter the code.';
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
  String appVersion(String version) {
    return 'Version $version';
  }

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
  String get projectsFieldPlantGroup => 'Plant type';

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
      'We couldn\'t build a plan yet. Please try again in a moment.';

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
    return 'Day $day of the month';
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
  String get planTaskFixedDay => 'Day of month (1-31)';

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
    return 'Day $n of the month';
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
  String get householdJoinHint => 'e.g. VUON-K7M2QX';

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
  String get householdErrorCodeFormat => 'Codes look like VUON-K7M2QX';

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

  @override
  String get checkinEntryButton => 'Photo check-in';

  @override
  String checkinTitle(String plant) {
    return 'Check-in · $plant';
  }

  @override
  String checkinShotProgress(int n, int total, String shot) {
    return 'Photo $n/$total · $shot';
  }

  @override
  String get checkinShotWhole => 'Whole plant';

  @override
  String get checkinShotLeaf => 'Close-up leaf';

  @override
  String get checkinShotUnder => 'Underside of leaf';

  @override
  String get checkinFrameHint => 'Keep the whole plant in frame';

  @override
  String checkinShotsTaken(int count, int max) {
    return '$count/$max photos taken';
  }

  @override
  String get checkinTakePhoto => 'Take photo';

  @override
  String get checkinRetakeShot => 'Retake this photo';

  @override
  String get checkinGallery => 'Choose from gallery';

  @override
  String get checkinTips => 'Photo tips';

  @override
  String get checkinClose => 'Close';

  @override
  String get checkinQuickTags => 'Quick condition';

  @override
  String get checkinTagLeafYellow => 'Yellow leaves';

  @override
  String get checkinTagWilt => 'Wilting';

  @override
  String get checkinTagPests => 'Pests';

  @override
  String get checkinTagSpots => 'Spots';

  @override
  String get checkinNoteHint => 'Short note (optional)';

  @override
  String get checkinAnalyze => 'Analyze photos';

  @override
  String get checkinProcessing => 'Processing photo...';

  @override
  String get checkinAnalyzingTitle => 'AI is looking at your photos';

  @override
  String get checkinAnalyzingSub => 'Usually takes about 15 seconds';

  @override
  String get checkinStepUpload => 'Uploading photos';

  @override
  String get checkinStepAnalyze => 'Analyzing the plant';

  @override
  String get checkinQuotaTitle => 'Today\'s analyses are used up';

  @override
  String checkinQuotaBody(int used, int cap) {
    return 'You\'ve used $used/$cap AI analyses today. Your photos are saved in the timeline; try again tomorrow.';
  }

  @override
  String get checkinQuotaBodyPlain =>
      'You\'ve used all of today\'s AI analyses. Your photos are saved in the timeline; try again tomorrow.';

  @override
  String get checkinAiDownTitle => 'AI couldn\'t answer right now';

  @override
  String get checkinAiDownBody =>
      'Your plan is unchanged and no analysis was used. Please try again in a few minutes.';

  @override
  String get checkinSkippedTitle => 'This plant was just analyzed';

  @override
  String get checkinSkippedBody =>
      'This project already has a result from the last 24 hours. Pick a condition tag if you see something new.';

  @override
  String get checkinSkippedView => 'View previous result';

  @override
  String get checkinFailedTitle => 'Couldn\'t send the photos';

  @override
  String get checkinFailedBody =>
      'Check your connection and try again. Your photos are kept.';

  @override
  String get checkinBackToCapture => 'Back to camera';

  @override
  String get checkinRetakeTitle => 'Retake needed';

  @override
  String get checkinRetakeReasonBlur => 'The photo is blurry';

  @override
  String get checkinRetakeReasonDark => 'The photo is too dark';

  @override
  String get checkinRetakeReasonFar => 'The plant isn\'t clearly visible';

  @override
  String get checkinRetakeReasonNotPlant => 'No plant in the photo';

  @override
  String get checkinRetakeReasonUnreadable => 'The photo couldn\'t be read';

  @override
  String get checkinRetakeHeadline => 'AI doesn\'t have enough information';

  @override
  String get checkinRetakeBody =>
      'To avoid guessing wrong, please retake it. This attempt doesn\'t count toward today\'s analyses.';

  @override
  String get checkinRetakeTipsTitle => 'Tips for a clear photo';

  @override
  String get checkinRetakeTip1 => 'Shoot in daylight, avoid backlight';

  @override
  String get checkinRetakeTip2 =>
      'Hold the phone 40–60 cm from the plant, tap to focus';

  @override
  String get checkinRetakeTip3 => 'Add a close-up of any odd-looking leaf';

  @override
  String get checkinRetakeCta => 'Retake';

  @override
  String get checkinResultTitle => 'Check-in result';

  @override
  String checkinXpChip(int xp) {
    return '+$xp XP';
  }

  @override
  String get checkinAiLabel => 'AI suggestion';

  @override
  String checkinStageLine(String stage, int pct) {
    return 'Stage: $stage ($pct%)';
  }

  @override
  String checkinStageEarly(String name) {
    return 'early $name';
  }

  @override
  String checkinStageMid(String name) {
    return 'mid $name';
  }

  @override
  String checkinStageLate(String name) {
    return 'late $name';
  }

  @override
  String checkinHealthLine(String health) {
    return 'Health: $health';
  }

  @override
  String get checkinHealthGood => 'Good';

  @override
  String get checkinHealthFair => 'Fair';

  @override
  String get checkinHealthPoor => 'Poor';

  @override
  String get checkinIssuesTitle => 'Suspected problems';

  @override
  String get checkinNoIssues => 'No unusual signs spotted.';

  @override
  String get checkinSafeActions => 'Safe things to do (organic first)';

  @override
  String checkinMilestoneNote(String name) {
    return 'The photo confirms the milestone: $name';
  }

  @override
  String get checkinChangesTitle => 'Suggested plan changes';

  @override
  String get checkinNoChanges => 'AI suggests no changes to your plan.';

  @override
  String get checkinKindAdd => 'ADD TASK';

  @override
  String get checkinKindFreq => 'CHANGE FREQUENCY';

  @override
  String get checkinKindShift => 'MOVE MILESTONE';

  @override
  String get checkinKindRemove => 'REMOVE TASK';

  @override
  String checkinChangeFreq(String task, String from, String to) {
    return '$task: $from → $to';
  }

  @override
  String checkinChangeFreqTo(String task, String to) {
    return '$task: $to';
  }

  @override
  String checkinChangeShift(String milestone, String date) {
    return '$milestone: moved to $date';
  }

  @override
  String get checkinChangeApprove => 'Apply';

  @override
  String get checkinChangeSkip => 'Skip';

  @override
  String get checkinLowConfTitle => 'AI isn\'t very sure';

  @override
  String get checkinLowConfBody =>
      'Bring the photo or a leaf sample to a local agricultural store and ask. Follow the product label for any treatment and amount.';

  @override
  String get checkinLater => 'Later';

  @override
  String checkinApply(int count) {
    return 'Apply $count changes';
  }

  @override
  String get checkinSkipAll => 'Skip all';

  @override
  String get checkinDone => 'Done';

  @override
  String get checkinApplyError =>
      'Couldn\'t apply the changes. Please try again.';

  @override
  String checkinApplied(int count) {
    return 'Applied $count changes';
  }

  @override
  String get checkinAlreadyAnswered =>
      'You\'ve already answered these suggestions.';

  @override
  String get checkinResultLoadError => 'Couldn\'t load the check-in result.';

  @override
  String get notifChannelTaskName => 'Plant care reminders';

  @override
  String get notifChannelTaskDescription =>
      'Reminders for plant care tasks by time of day';

  @override
  String get notifChannelCheckinName => 'Check-in reminders';

  @override
  String get notifChannelCheckinDescription =>
      'Reminders to take a check-in photo of your plants';

  @override
  String get householdJoinAlreadyTitle => 'You\'re already in a household';

  @override
  String householdJoinAlreadyBody(String code) {
    return 'You can only be in one household at a time, so the code $code can\'t be used. To join another one, leave your current household in Settings first.';
  }

  @override
  String get householdJoinAlreadyAction => 'Go to Household';

  @override
  String gamXpGain(String xp) {
    return '+$xp XP';
  }
}
