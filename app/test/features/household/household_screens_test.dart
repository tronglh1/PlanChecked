import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vuon_nha/core/db/local_prefs.dart';
import 'package:vuon_nha/features/household/domain/household_models.dart';
import 'package:vuon_nha/features/household/presentation/household_providers.dart';
import 'package:vuon_nha/features/profile/domain/user_profile.dart';
import 'package:vuon_nha/features/settings/presentation/settings_screen.dart';

import '../../helpers/fakes.dart';
import '../../helpers/household_fakes.dart';

const _projects = [
  ShareableProject(
    id: 'p1',
    name: 'Cà chua bi',
    ownerId: 'u1',
    sharedWithHousehold: true,
  ),
  ShareableProject(
    id: 'p2',
    name: 'Húng quế',
    ownerId: 'u1',
    sharedWithHousehold: false,
  ),
];

void main() {
  group('Gia đình tab (17)', () {
    testWidgets('owner sees members, roles, invite, share and remove', (
      t,
    ) async {
      final repo = FakeHouseholdRepository(household: sampleHousehold())
        ..projects = _projects;
      await pumpRouted(t, location: '/household', household: repo);

      expect(find.text('Gia đình · 3 người'), findsOneWidget);
      expect(find.text('Minh (bạn)'), findsOneWidget);
      expect(find.text('Lan'), findsOneWidget);
      expect(find.text('5 việc tuần này'), findsOneWidget);
      expect(find.text('Owner'), findsOneWidget);
      expect(find.text('Member'), findsNWidgets(2));
      expect(find.byKey(const Key('invite-button')), findsOneWidget);
      expect(find.byKey(const Key('share-more')), findsOneWidget);
      expect(find.byKey(const Key('member-menu-u2')), findsOneWidget);
      // Own row has no remove menu.
      expect(find.byKey(const Key('member-menu-u1')), findsNothing);
      // Shared project chip.
      expect(find.text('Cà chua bi'), findsOneWidget);
      expect(find.text('Húng quế'), findsNothing);
    });

    testWidgets('member has no invite, share or remove controls', (t) async {
      final repo = FakeHouseholdRepository(household: sampleHousehold(me: 'u2'))
        ..projects = _projects;
      await pumpRouted(
        t,
        location: '/household',
        household: repo,
        userId: 'u2',
      );
      expect(find.text('Lan (bạn)'), findsOneWidget);
      expect(find.byKey(const Key('invite-button')), findsNothing);
      expect(find.byKey(const Key('share-more')), findsNothing);
      expect(find.byType(PopupMenuButton<String>), findsNothing);
    });

    testWidgets('owner shares and unshares a project (HSH-03)', (t) async {
      final repo = FakeHouseholdRepository(household: sampleHousehold())
        ..projects = _projects;
      await pumpRouted(t, location: '/household', household: repo);
      await t.tap(find.byKey(const Key('share-more')));
      await t.pumpAndSettle();

      await t.tap(find.byKey(const Key('share-p2')));
      await t.pumpAndSettle();
      expect(repo.shares.last, (project: 'p2', household: 'h1'));

      await t.tap(find.byKey(const Key('share-p1')));
      await t.pumpAndSettle();
      expect(repo.shares.last, (project: 'p1', household: null));
    });

    testWidgets('owner removes a member after confirming', (t) async {
      final repo = FakeHouseholdRepository(household: sampleHousehold());
      await pumpRouted(t, location: '/household', household: repo);
      await t.tap(find.byKey(const Key('member-menu-u3')));
      await t.pumpAndSettle();
      await t.tap(find.text('Xóa khỏi gia đình'));
      await t.pumpAndSettle();
      expect(find.text('Xóa Hùng khỏi gia đình?'), findsOneWidget);
      await t.tap(find.byKey(const Key('remove-confirm')));
      await t.pumpAndSettle();
      expect(repo.removed, ['u3']);
      expect(find.text('Gia đình · 2 người'), findsOneWidget);
    });

    testWidgets('activity feed updates in realtime', (t) async {
      final repo = FakeHouseholdRepository(household: sampleHousehold())
        ..projects = _projects;
      await pumpRouted(t, location: '/household', household: repo);
      expect(find.text('Chưa có hoạt động nào'), findsOneWidget);

      repo.activity.add([
        ActivityItem(
          id: 'a1',
          kind: 'task_done',
          actorId: 'u2',
          projectId: 'p1',
          createdAt: DateTime.now(),
        ),
        ActivityItem(
          id: 'a2',
          kind: 'member_joined',
          actorId: 'u3',
          createdAt: DateTime.now(),
        ),
      ]);
      await t.pumpAndSettle();
      expect(
        find.text('Lan đã hoàn thành một việc · Cà chua bi'),
        findsOneWidget,
      );
      expect(find.text('Hùng đã tham gia gia đình'), findsOneWidget);

      repo.activity.add([
        ActivityItem(
          id: 'a3',
          kind: 'milestone',
          actorId: 'u1',
          projectId: 'p1',
          createdAt: DateTime.now(),
        ),
      ]);
      await t.pumpAndSettle();
      expect(find.text('Minh đạt mốc mới · Cà chua bi'), findsOneWidget);
    });

    testWidgets('no household shows create and join', (t) async {
      await pumpRouted(
        t,
        location: '/household',
        household: FakeHouseholdRepository(),
      );
      expect(find.text('Bạn chưa có gia đình'), findsOneWidget);
      expect(find.byKey(const Key('create-household')), findsOneWidget);
      expect(find.byKey(const Key('join-household')), findsOneWidget);
    });
  });

  group('Mời thành viên (18)', () {
    testWidgets('shows the code and shares it through the share sheet', (
      t,
    ) async {
      final repo = FakeHouseholdRepository(household: sampleHousehold());
      final share = FakeShareService();
      await pumpRouted(
        t,
        location: '/household/invite',
        household: repo,
        share: share,
      );
      expect(find.text('VUON-4821'), findsOneWidget);
      expect(find.text('Hết hạn sau 7 ngày'), findsOneWidget);
      expect(repo.invites.single.channel, 'code');
      expect(repo.invites.single.role, HouseholdRole.member);

      await t.tap(find.byKey(const Key('invite-share')));
      await t.pumpAndSettle();
      expect(share.texts, hasLength(1));
      expect(share.texts.single, contains('VUON-4821'));
      expect(share.texts.single, contains('https://vuonnha.app/i/VUON-4821'));
      expect(share.texts.single, contains('Minh'));
    });

    testWidgets('email invite goes through the invite function with role', (
      t,
    ) async {
      final repo = FakeHouseholdRepository(household: sampleHousehold())
        ..emailSent = true;
      final share = FakeShareService();
      await pumpRouted(
        t,
        location: '/household/invite',
        household: repo,
        share: share,
      );
      await t.enterText(find.byKey(const Key('invite-target')), 'lan@mail.com');
      await t.tap(find.byKey(const Key('role-owner')));
      await t.pumpAndSettle();
      await t.ensureVisible(find.byKey(const Key('invite-send')));
      await t.tap(find.byKey(const Key('invite-send')));
      await t.pumpAndSettle();
      final inv = repo.invites.last;
      expect(inv.channel, 'email');
      expect(inv.target, 'lan@mail.com');
      expect(inv.role, HouseholdRole.owner);
      expect(find.text('Đã gửi email mời tới lan@mail.com'), findsOneWidget);
      expect(share.texts, isEmpty);
    });

    testWidgets('phone invite falls back to the share sheet; junk rejected', (
      t,
    ) async {
      final repo = FakeHouseholdRepository(household: sampleHousehold());
      final share = FakeShareService();
      await pumpRouted(
        t,
        location: '/household/invite',
        household: repo,
        share: share,
      );
      await t.enterText(find.byKey(const Key('invite-target')), 'abc');
      await t.ensureVisible(find.byKey(const Key('invite-send')));
      await t.tap(find.byKey(const Key('invite-send')));
      await t.pumpAndSettle();
      expect(find.text('Nhập email hợp lệ hoặc số điện thoại'), findsOneWidget);
      expect(repo.invites.length, 1); // only the code card

      await t.enterText(find.byKey(const Key('invite-target')), '0912 345 678');
      await t.tap(find.byKey(const Key('invite-send')));
      await t.pumpAndSettle();
      expect(repo.invites.last.channel, 'phone');
      expect(share.texts, hasLength(1));
    });

    testWidgets('members cannot invite', (t) async {
      final repo = FakeHouseholdRepository(
        household: sampleHousehold(me: 'u2'),
      );
      await pumpRouted(
        t,
        location: '/household/invite',
        household: repo,
        userId: 'u2',
      );
      expect(find.byKey(const Key('invite-owner-only')), findsOneWidget);
      expect(find.byKey(const Key('invite-code')), findsNothing);
      expect(repo.invites, isEmpty);
    });
  });

  group('Giao việc (19)', () {
    testWidgets('rotation is the default and keeps member order', (t) async {
      final repo = FakeHouseholdRepository(
        household: sampleHousehold(),
        task: sampleTask,
      );
      await pumpRouted(t, location: '/task/t1/assign', household: repo);
      expect(find.text('Tưới gốc'), findsOneWidget);
      expect(
        find.text('Cà chua bi ban công · Sáng sớm · 2 ngày/lần'),
        findsOneWidget,
      );
      expect(find.text('Thứ tự xoay vòng'), findsOneWidget);
      expect(
        find.text('Xoay vòng: Minh → Lan → Hùng → lặp lại.'),
        findsOneWidget,
      );
      await t.tap(find.byKey(const Key('assign-submit')));
      await t.pumpAndSettle();
      final a = repo.assigned.single;
      expect(a.mode, AssignMode.rotation);
      expect(a.order, ['u1', 'u2', 'u3']);
      expect(a.assignee, isNull);
      // Back on the Gia đình tab (17).
      expect(find.text('Gia đình · 3 người'), findsOneWidget);
    });

    testWidgets('rotation order follows taps; needs 2 people', (t) async {
      final repo = FakeHouseholdRepository(
        household: sampleHousehold(),
        task: sampleTask,
      );
      await pumpRouted(t, location: '/task/t1/assign', household: repo);
      // Drop Minh and Lan, then re-add Lan: order becomes Hùng, Lan.
      await t.tap(find.byKey(const Key('person-u1')));
      await t.tap(find.byKey(const Key('person-u2')));
      await t.pumpAndSettle();
      await t.tap(find.byKey(const Key('assign-submit')));
      await t.pumpAndSettle();
      expect(find.text('Chọn ít nhất 2 người để xoay vòng'), findsOneWidget);
      expect(repo.assigned, isEmpty);

      await t.tap(find.byKey(const Key('person-u2')));
      await t.pumpAndSettle();
      expect(find.text('Xoay vòng: Hùng → Lan → lặp lại.'), findsOneWidget);
      await t.tap(find.byKey(const Key('assign-submit')));
      await t.pumpAndSettle();
      expect(repo.assigned.single.order, ['u3', 'u2']);
    });

    testWidgets('series assigns the whole chain to one person', (t) async {
      final repo = FakeHouseholdRepository(
        household: sampleHousehold(),
        task: sampleTask,
      );
      await pumpRouted(t, location: '/task/t1/assign', household: repo);
      await t.tap(find.byKey(const Key('mode-series')));
      await t.pumpAndSettle();
      expect(find.text('Giao cho'), findsOneWidget);
      await t.tap(find.byKey(const Key('person-u2')));
      await t.pumpAndSettle();
      expect(
        find.text('Mọi lần “Tưới gốc” tiếp theo sẽ giao cho Lan.'),
        findsOneWidget,
      );
      await t.tap(find.byKey(const Key('assign-submit')));
      await t.pumpAndSettle();
      final a = repo.assigned.single;
      expect(a.mode, AssignMode.series);
      expect(a.assignee, 'u2');
      expect(a.order, isEmpty);
    });

    testWidgets('once assigns a single occurrence mode', (t) async {
      final repo = FakeHouseholdRepository(
        household: sampleHousehold(),
        task: sampleTask,
      );
      await pumpRouted(t, location: '/task/t1/assign', household: repo);
      await t.tap(find.byKey(const Key('mode-once')));
      await t.pumpAndSettle();
      await t.tap(find.byKey(const Key('person-u3')));
      await t.pumpAndSettle();
      expect(
        find.text('Chỉ lần “Tưới gốc” tới giao cho Hùng.'),
        findsOneWidget,
      );
      await t.tap(find.byKey(const Key('assign-submit')));
      await t.pumpAndSettle();
      final a = repo.assigned.single;
      expect(a.mode, AssignMode.once);
      expect(a.assignee, 'u3');
    });

    testWidgets('members cannot assign', (t) async {
      final repo = FakeHouseholdRepository(
        household: sampleHousehold(me: 'u2'),
        task: sampleTask,
      );
      await pumpRouted(
        t,
        location: '/task/t1/assign',
        household: repo,
        userId: 'u2',
      );
      expect(find.byKey(const Key('assign-owner-only')), findsOneWidget);
      expect(find.byKey(const Key('assign-submit')), findsNothing);
    });
  });

  group('Rời gia đình (HSH-09)', () {
    const profile = UserProfile(
      id: 'u1',
      displayName: 'Minh',
      provinceCode: 'tp-hcm',
    );

    Future<FakeHouseholdRepository> pumpSettings(
      WidgetTester t,
      Household? h, {
      String uid = 'u1',
    }) async {
      final repo = FakeHouseholdRepository(household: h);
      await pumpApp(
        t,
        const SettingsScreen(),
        auth: FakeAuthRepository(userId: uid),
        profile: FakeProfileRepository(profile),
        extra: [householdRepositoryProvider.overrideWithValue(repo)],
      );
      await t.scrollUntilVisible(
        find.byKey(const Key('sign-out')),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      return repo;
    }

    testWidgets('row is hidden without a household', (t) async {
      await pumpSettings(t, null);
      expect(find.byKey(const Key('leave-household')), findsNothing);
    });

    testWidgets('owner is told who inherits, then leaves', (t) async {
      final repo = await pumpSettings(t, sampleHousehold());
      expect(find.text('Rời gia đình “Nhà mình”'), findsOneWidget);
      await t.tap(find.byKey(const Key('leave-household')));
      await t.pumpAndSettle();
      expect(find.text('Rời gia đình?'), findsOneWidget);
      // Lan joined before Hùng: she inherits.
      expect(
        find.text('Quyền Owner sẽ chuyển cho Lan, thành viên lâu nhất.'),
        findsOneWidget,
      );
      await t.tap(find.byKey(const Key('leave-confirm')));
      await t.pumpAndSettle();
      expect(repo.leaves, 1);
      final container = ProviderScope.containerOf(
        t.element(find.byType(SettingsScreen)),
      );
      expect(
        await container.read(localPrefsProvider).get(kHouseholdSkipKey),
        '1',
      );
      expect(find.byKey(const Key('leave-household')), findsNothing);
    });

    testWidgets('cancel does not leave', (t) async {
      final repo = await pumpSettings(t, sampleHousehold());
      await t.tap(find.byKey(const Key('leave-household')));
      await t.pumpAndSettle();
      await t.tap(find.text('Huỷ'));
      await t.pumpAndSettle();
      expect(repo.leaves, 0);
    });

    testWidgets('last owner is warned the household will be deleted', (
      t,
    ) async {
      final solo = Household(
        id: 'h1',
        name: 'Nhà mình',
        ownerId: 'u1',
        myUserId: 'u1',
        members: [member('u1', 'Minh', role: HouseholdRole.owner)],
      );
      await pumpSettings(t, solo);
      await t.tap(find.byKey(const Key('leave-household')));
      await t.pumpAndSettle();
      expect(
        find.text('Bạn là người cuối cùng, nên gia đình sẽ bị xóa.'),
        findsOneWidget,
      );
    });

    testWidgets('plain member sees no ownership note', (t) async {
      final repo = await pumpSettings(t, sampleHousehold(me: 'u2'), uid: 'u2');
      await t.tap(find.byKey(const Key('leave-household')));
      await t.pumpAndSettle();
      expect(find.byKey(const Key('leave-owner-note')), findsNothing);
      await t.tap(find.byKey(const Key('leave-confirm')));
      await t.pumpAndSettle();
      expect(repo.leaves, 1);
    });
  });
}
