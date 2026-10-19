import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:vuon_nha/core/db/local_prefs.dart';
import 'package:vuon_nha/features/auth/data/auth_repository.dart';
import 'package:vuon_nha/features/auth/presentation/auth_state.dart';
import 'package:vuon_nha/features/plants/data/plant_repository.dart';
import 'package:vuon_nha/features/plants/domain/plant.dart';
import 'package:vuon_nha/features/plants/presentation/plant_providers.dart';
import 'package:vuon_nha/features/profile/data/profile_repository.dart';
import 'package:vuon_nha/features/profile/domain/user_profile.dart';
import 'package:vuon_nha/features/profile/presentation/profile_providers.dart';
import 'package:vuon_nha/features/settings/data/notification_prefs_repository.dart';
import 'package:vuon_nha/features/settings/domain/notification_settings.dart';
import 'package:vuon_nha/features/settings/presentation/locale_provider.dart';
import 'package:vuon_nha/features/settings/presentation/settings_providers.dart';
import 'package:vuon_nha/l10n/app_localizations.dart';

class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({this._userId});

  String? _userId;
  final _ctrl = StreamController<String?>.broadcast();
  final List<String> calls = [];
  bool failVerify = false;

  @override
  String? get currentUserId => _userId;

  @override
  Stream<String?> userIdChanges() => _ctrl.stream;

  @override
  Future<void> signInWithGoogle() async => calls.add('google');

  @override
  Future<void> sendEmailOtp(String email) async => calls.add('otp:$email');

  @override
  Future<void> verifyEmailOtp(String email, String code) async {
    calls.add('verify:$email:$code');
    if (failVerify) throw Exception('bad code');
    _userId = 'u1';
    _ctrl.add('u1');
  }

  @override
  Future<void> signOut() async {
    calls.add('signOut');
    _userId = null;
    _ctrl.add(null);
  }

  @override
  Future<void> deleteMyAccount() async {
    calls.add('delete');
    _userId = null;
    _ctrl.add(null);
  }
}

class FakeProfileRepository implements ProfileRepository {
  FakeProfileRepository([this.profile]);

  UserProfile? profile;
  final List<String> langUpdates = [];

  @override
  Future<UserProfile?> fetch() async => profile;

  @override
  Future<void> save(UserProfile p) async => profile = p;

  @override
  Future<void> updateLang(String lang) async => langUpdates.add(lang);

  @override
  Future<String> uploadAvatar(Uint8List bytes, {String ext = 'jpg'}) async =>
      'u1/avatar.$ext';
}

class FakeNotificationPrefsRepository implements NotificationPrefsRepository {
  NotificationSettings? saved;

  @override
  Future<void> save(NotificationSettings settings) async => saved = settings;
}

class FakePlantRepository implements PlantRepository {
  FakePlantRepository(this.plants);
  final List<Plant> plants;

  @override
  Future<List<Plant>> fetchPlants() async => plants;

  @override
  Future<List<TextTemplate>> fetchTextTemplates(
    String lang, {
    String? kind,
  }) async => const [];
}

const testPlants = <Plant>[
  Plant(
    id: 'p1',
    group: PlantGroup.rauQua,
    nameVi: 'Rau muống',
    nameEn: 'Water spinach',
    scientificName: 'Ipomoea aquatica',
    difficulty: 'easy',
    daysToHarvest: 30,
  ),
  Plant(
    id: 'p2',
    group: PlantGroup.rauQua,
    nameVi: 'Cà chua bi',
    nameEn: 'Cherry tomato',
    scientificName: 'Solanum lycopersicum var. cerasiforme',
    difficulty: 'easy',
    daysToHarvest: 75,
  ),
  Plant(
    id: 'p3',
    group: PlantGroup.rauQua,
    nameVi: 'Cà chua tím',
    nameEn: 'Indigo Rose tomato',
    scientificName: 'Solanum lycopersicum',
    difficulty: 'medium',
    daysToHarvest: 90,
  ),
  Plant(
    id: 'p4',
    group: PlantGroup.cayCanh,
    nameVi: 'Trầu bà',
    nameEn: 'Pothos',
    scientificName: 'Epipremnum aureum',
    difficulty: 'easy',
  ),
];

/// Pumps [child] inside a localized MaterialApp with fake repositories.
Future<void> pumpApp(
  WidgetTester tester,
  Widget child, {
  FakeAuthRepository? auth,
  FakeProfileRepository? profile,
  FakePlantRepository? plants,
  FakeNotificationPrefsRepository? notifPrefs,
  List<Override> extra = const [],
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        localPrefsProvider.overrideWithValue(MemoryLocalPrefs()),
        authRepositoryProvider.overrideWithValue(auth ?? FakeAuthRepository()),
        profileRepositoryProvider.overrideWithValue(
          profile ?? FakeProfileRepository(),
        ),
        plantRepositoryProvider.overrideWithValue(
          plants ?? FakePlantRepository(testPlants),
        ),
        notificationPrefsRepositoryProvider.overrideWithValue(
          notifPrefs ?? FakeNotificationPrefsRepository(),
        ),
        ...extra,
      ],
      child: Consumer(
        builder: (context, ref, _) => MaterialApp(
          locale: ref.watch(localeProvider),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: Scaffold(body: child),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}
