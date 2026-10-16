import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:popaya_assessment/core/di/injection.dart';
import 'package:popaya_assessment/data/datasources/mock_data.dart';
import 'package:popaya_assessment/data/repositories/repository_implementations.dart';
import 'package:popaya_assessment/domain/entities/task.dart';
import 'package:popaya_assessment/main.dart';
import 'package:popaya_assessment/presentation/controllers/dashboard_controller.dart';
import 'package:popaya_assessment/presentation/controllers/session_controller.dart';
import 'package:popaya_assessment/presentation/screens/add_task/add_task_sheet.dart';
import 'package:popaya_assessment/presentation/widgets/task_card.dart';

import '../fakes.dart';

void main() {
  late InMemoryTaskRepository tasks;
  late InMemoryTeamRepository team;
  late InMemoryAuthRepository auth;

  setUpAll(loadMontserrat);

  setUp(() {
    Get.testMode = true;
    tasks = InMemoryTaskRepository(MockData.tasks(fixedNow));
    team = InMemoryTeamRepository();
    auth = InMemoryAuthRepository();
    registerDependencies(
      tasks: tasks,
      team: team,
      portfolio: const MockPortfolioRepository(),
      auth: auth,
      clock: FixedClock(),
    );
  });

  tearDown(Get.reset);

  Future<void> pumpApp(WidgetTester tester, Size size) async {
    tester.view.devicePixelRatio = 3;
    tester.view.physicalSize = size * 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const ResideApp());
    await tester.pumpAndSettle();
  }

  int expectedCount(TaskDisplayStatus status) =>
      MockData.tasks(fixedNow).where((t) {
        final today = DateTime(2026, 10, 16);
        final ref = (t.isClosed ? t.completedAt : t.dueAt) ?? t.createdAt;
        final inToday =
            !ref.isBefore(today) && ref.isBefore(DateTime(2026, 10, 17));
        final b = t.isClosed
            ? TaskDisplayStatus.closed
            : (t.dueAt != null && t.dueAt!.isBefore(fixedNow))
            ? TaskDisplayStatus.overdue
            : TaskDisplayStatus.open;
        return inToday && b == status;
      }).length;

  const sizes = {
    'small (320x568)': Size(320, 568),
    'design (414x870)': Size(414, 870),
    'large (480x1000)': Size(480, 1000),
  };

  for (final MapEntry(key: name, value: size) in sizes.entries) {
    testWidgets('all screens render without overflow on $name', (tester) async {
      await pumpApp(tester, size);
      expect(find.text('Dashboard'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.scrollUntilVisible(find.text('VIEW TEAM PERFORMANCE'), 200);
      await tester.tap(find.text('VIEW TEAM PERFORMANCE'));
      await tester.pumpAndSettle();
      expect(find.text('Team Performance'), findsOneWidget);
      expect(tester.takeException(), isNull);

      Get.back<void>();
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Overdue'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Overdue'));
      await tester.pumpAndSettle();
      expect(find.text('Team’s Task'), findsOneWidget);
      expect(tester.takeException(), isNull);

      // Scroll through the list to lay out every card.
      await tester.fling(
        find.byType(Scrollable).last,
        const Offset(0, -2000),
        3000,
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
    'dashboard counts come from task data and open the matching tab',
    (tester) async {
      await pumpApp(tester, const Size(414, 870));

      expect(
        find.text('${expectedCount(TaskDisplayStatus.open)}'),
        findsWidgets,
      );
      expect(
        find.text('${expectedCount(TaskDisplayStatus.overdue)}'),
        findsWidgets,
      );

      await tester.tap(find.text('Closed'));
      await tester.pumpAndSettle();
      final tabBar = tester.widget<TabBar>(find.byType(TabBar));
      final controller = DefaultTabController.of(
        tester.element(find.byWidget(tabBar)),
      );
      expect(controller.index, TaskDisplayStatus.closed.index);
      expect(find.text('Closed'), findsWidgets);
    },
  );

  testWidgets('closing a task moves it to the Closed tab', (tester) async {
    await pumpApp(tester, const Size(414, 870));
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    final before = expectedCount(TaskDisplayStatus.open);
    expect(before, greaterThan(0));
    await tester.tap(find.byType(TaskCard).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mark as closed'));
    await tester.pumpAndSettle();

    final all = await tasks.getTasks();
    expect(
      all.where((t) => t.isClosed && t.completedAt == fixedNow),
      hasLength(1),
    );
  });

  testWidgets('switching member updates My Tasks counts and persists choice', (
    tester,
  ) async {
    await pumpApp(tester, const Size(414, 870));
    await tester.tap(find.text('My Tasks'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Select team member'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Deepak Singh').last);
    await tester.pumpAndSettle();
    expect(team.selected, 'm03');
  });

  testWidgets('shows error state with retry when loading fails', (
    tester,
  ) async {
    tasks.fail = true;
    await pumpApp(tester, const Size(414, 870));
    expect(find.text('Could not load tasks.'), findsOneWidget);

    tasks.fail = false;
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.text('Could not load tasks.'), findsNothing);
    expect(find.text('Tasks'), findsOneWidget);
  });

  group('admin-only Add Task', () {
    Finder addTaskButton() => find.widgetWithText(FilledButton, 'Add Task');

    testWidgets('team members never see the Add Task button', (tester) async {
      await pumpApp(tester, const Size(414, 870));
      expect(find.byType(FloatingActionButton), findsOneWidget);

      // Switch to a team-member login through the session (demo switcher).
      await Get.find<SessionController>().switchToUser(
        MockData.users.firstWhere((u) => !u.isAdmin),
      );
      await tester.pumpAndSettle();
      expect(find.byType(FloatingActionButton), findsNothing);

      // Calling the flow directly is still refused.
      final context = tester.element(find.text('Dashboard'));
      showAddTaskSheet(context);
      await tester.pumpAndSettle();
      expect(addTaskButton(), findsNothing);
      expect(
        find.text('Only admins can create and assign tasks.'),
        findsOneWidget,
      );
      await tester.pump(const Duration(seconds: 4));
      await tester.pumpAndSettle();
    });

    testWidgets('admin sees the button on Dashboard and Team’s Task', (
      tester,
    ) async {
      await pumpApp(tester, const Size(414, 870));
      expect(find.byType(FloatingActionButton), findsOneWidget);
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(find.byType(FloatingActionButton), findsOneWidget);
    });

    testWidgets('validates, then creates an open task and updates counts', (
      tester,
    ) async {
      await pumpApp(tester, const Size(414, 870));
      final dashboard = Get.find<DashboardController>();
      final openBefore = dashboard.taskCounts.value.open;
      final countBefore = tasks.all.length;

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      // Empty submit: messages shown, nothing saved, sheet stays open.
      await tester.tap(addTaskButton());
      await tester.pumpAndSettle();
      expect(find.text('Select a team member.'), findsOneWidget);
      expect(
        find.text('Enter a task title or pick a template.'),
        findsOneWidget,
      );
      expect(find.text('Select a due date and time.'), findsOneWidget);
      expect(tasks.all, hasLength(countBefore));

      await tester.tap(find.text('Select team member'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Bilal Shaikh').last);
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextField, 'e.g. Schedule a site visit'),
        'Share the new floor plan',
      );
      await tester.tap(find.text('Select date & time'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK')); // date: today
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK')); // time: 1:00 PM (now + 1h)
      await tester.pumpAndSettle();

      await tester.tap(addTaskButton());
      await tester.pumpAndSettle();

      final created = tasks.all.where(
        (t) => t.title == 'Share the new floor plan',
      );
      expect(created, hasLength(1));
      final task = created.single;
      expect(task.assigneeId, 'm02');
      expect(task.status, TaskStatus.open);
      expect(task.dueAt, DateTime(2026, 10, 16, 13));

      expect(addTaskButton(), findsNothing, reason: 'sheet closes on success');
      expect(find.text('Task added'), findsOneWidget);
      expect(dashboard.taskCounts.value.open, openBefore + 1);

      await tester.pump(const Duration(seconds: 4));
      await tester.pumpAndSettle();
    });

    testWidgets('keeps the sheet open and shows the error if saving fails', (
      tester,
    ) async {
      await pumpApp(tester, const Size(414, 870));
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Select team member'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Akhil Bisht').last);
      await tester.pumpAndSettle();
      // Template pre-fills the title.
      await tester.tap(find.text('Custom task'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Verify ownership documents').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Select date & time'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      tasks.failSave = true;
      await tester.tap(addTaskButton());
      await tester.pumpAndSettle();
      expect(find.text('Could not save the task.'), findsOneWidget);
      expect(addTaskButton(), findsOneWidget);
    });
  });

  group('bottom sheets stay above the system navigation bar', () {
    // A 48 px gesture / 3-button navigation bar at the bottom of the screen.
    const navigationBarHeight = 48.0;
    const screen = Size(414, 870);

    Future<void> pumpWithNavigationBar(WidgetTester tester) async {
      tester.view.padding = const FakeViewPadding(
        bottom: navigationBarHeight * 3,
      );
      tester.view.viewPadding = const FakeViewPadding(
        bottom: navigationBarHeight * 3,
      );
      addTearDown(tester.view.resetPadding);
      addTearDown(tester.view.resetViewPadding);
      await pumpApp(tester, screen);
    }

    void expectAboveNavigationBar(WidgetTester tester, Finder button) {
      expect(button, findsOneWidget);
      final bottom = tester.getRect(button).bottom;
      expect(
        bottom,
        lessThanOrEqualTo(screen.height - navigationBarHeight),
        reason: 'button bottom $bottom is hidden behind the navigation bar',
      );
    }

    testWidgets('Add Task sheet buttons', (tester) async {
      await pumpWithNavigationBar(tester);
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();
      final scrollable = find.descendant(
        of: find.byType(BottomSheet),
        matching: find.byType(Scrollable),
      );
      await tester.drag(scrollable.first, const Offset(0, -1000));
      await tester.pumpAndSettle();
      expectAboveNavigationBar(
        tester,
        find.widgetWithText(OutlinedButton, 'Cancel'),
      );
      expectAboveNavigationBar(
        tester,
        find.widgetWithText(FilledButton, 'Add Task'),
      );
    });

    testWidgets('Filters sheet buttons', (tester) async {
      await pumpWithNavigationBar(tester);
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Filters'));
      await tester.pumpAndSettle();
      expectAboveNavigationBar(
        tester,
        find.widgetWithText(OutlinedButton, 'Reset'),
      );
      expectAboveNavigationBar(
        tester,
        find.widgetWithText(FilledButton, 'Apply'),
      );
    });

    testWidgets('Task details sheet button', (tester) async {
      await pumpWithNavigationBar(tester);
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(TaskCard).first);
      await tester.pumpAndSettle();
      expectAboveNavigationBar(
        tester,
        find.widgetWithText(FilledButton, 'Mark as closed'),
      );
    });
  });
}
