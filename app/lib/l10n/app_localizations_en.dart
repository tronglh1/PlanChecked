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
}
