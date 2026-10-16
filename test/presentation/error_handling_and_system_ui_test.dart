import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:popaya_assessment/core/di/injection.dart';
import 'package:popaya_assessment/core/error/app_exception.dart';
import 'package:popaya_assessment/core/error/error_reporting.dart';
import 'package:popaya_assessment/data/datasources/mock_data.dart';
import 'package:popaya_assessment/data/repositories/repository_implementations.dart';
import 'package:popaya_assessment/main.dart';
import 'package:popaya_assessment/presentation/widgets/task_card.dart';

import '../fakes.dart';

void main() {
  late InMemoryTaskRepository tasks;
  const screen = Size(414, 870);
  const navigationBarHeight = 48.0;

  setUpAll(loadMontserrat);

  setUp(() {
    Get.testMode = true;
    tasks = InMemoryTaskRepository(MockData.tasks(fixedNow));
    registerDependencies(
      tasks: tasks,
      team: InMemoryTeamRepository(),
      portfolio: const MockPortfolioRepository(),
      auth: InMemoryAuthRepository(),
      clock: FixedClock(),
    );
  });

  tearDown(Get.reset);

  Future<void> pumpApp(
    WidgetTester tester, {
    bool navigationBar = false,
  }) async {
    tester.view.devicePixelRatio = 3;
    tester.view.physicalSize = screen * 3;
    if (navigationBar) {
      tester.view.padding = const FakeViewPadding(
        top: 24 * 3,
        bottom: navigationBarHeight * 3,
      );
      tester.view.viewPadding = const FakeViewPadding(
        top: 24 * 3,
        bottom: navigationBarHeight * 3,
      );
    }
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();
  }

  Future<void> waitForSnackbarToClose(WidgetTester tester) async {
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
  }

  group('error handling', () {
    testWidgets('an unexpected error shows the error screen, not a spinner', (
      tester,
    ) async {
      tasks.throwUnexpectedError = true;
      await pumpApp(tester);

      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text(genericErrorMessage), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);

      tasks.throwUnexpectedError = false;
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();
      expect(find.text('Dashboard'), findsOneWidget);
    });

    testWidgets('an unexpected save failure shows an error snackbar', (
      tester,
    ) async {
      await pumpApp(tester);
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(TaskCard).first);
      await tester.pumpAndSettle();

      tasks.throwUnexpectedError = true;
      await tester.tap(find.text('Mark as closed'));
      await tester.pumpAndSettle();

      expect(find.text('Update failed'), findsOneWidget);
      expect(find.text(genericErrorMessage), findsOneWidget);
      await waitForSnackbarToClose(tester);
    });

    testWidgets('a widget that fails to build shows a friendly fallback', (
      tester,
    ) async {
      final originalBuilder = ErrorWidget.builder;
      ErrorWidget.builder = (details) => BuildErrorFallback(details: details);
      try {
        await tester.pumpWidget(
          MaterialApp(home: Builder(builder: (_) => throw StateError('boom'))),
        );
        expect(tester.takeException(), isA<StateError>());
        expect(
          find.text('This section could not be displayed.'),
          findsOneWidget,
        );
      } finally {
        // The test binding requires the builder restored before the test ends.
        ErrorWidget.builder = originalBuilder;
      }
    });

    testWidgets('uncaught async errors are handled and shown to the user', (
      tester,
    ) async {
      await pumpApp(tester);

      expect(handleUncaughtError(StateError('x'), StackTrace.empty), isTrue);
      await tester.pumpAndSettle();
      expect(find.text(genericErrorMessage), findsOneWidget);
      await waitForSnackbarToClose(tester);

      handleUncaughtError(
        const AppException('Could not save the task.'),
        StackTrace.empty,
      );
      await tester.pumpAndSettle();
      expect(find.text('Could not save the task.'), findsOneWidget);
      await waitForSnackbarToClose(tester);
    });

    test('user-facing messages hide internal details', () {
      expect(userFacingMessageFor(StateError('db')), genericErrorMessage);
      expect(
        userFacingMessageFor(const AppException('Could not load tasks.')),
        'Could not load tasks.',
      );
    });
  });

  group('system bars and safe areas', () {
    testWidgets('status and navigation bars are transparent with dark icons', (
      tester,
    ) async {
      await pumpApp(tester);
      final regions = tester.widgetList<AnnotatedRegion<SystemUiOverlayStyle>>(
        find.byType(AnnotatedRegion<SystemUiOverlayStyle>),
      );
      expect(regions, isNotEmpty);
      final style = regions.first.value;
      expect(style.statusBarColor, Colors.transparent);
      expect(style.statusBarIconBrightness, Brightness.dark);
      expect(style.statusBarBrightness, Brightness.light);
      expect(style.systemNavigationBarColor, Colors.transparent);
      expect(style.systemNavigationBarIconBrightness, Brightness.dark);
      expect(style.systemNavigationBarContrastEnforced, isFalse);
    });

    testWidgets('headers sit below the status bar', (tester) async {
      await pumpApp(tester, navigationBar: true);
      expect(tester.getTopLeft(find.text('Dashboard')).dy, greaterThan(24));
      expect(tester.getTopLeft(find.byType(Image).first).dy, greaterThan(24));
    });

    Future<void> expectLastItemClearsNavigationBar(
      WidgetTester tester,
      Finder lastItem,
    ) async {
      await tester.fling(
        find.byType(Scrollable).last,
        const Offset(0, -5000),
        5000,
      );
      await tester.pumpAndSettle();
      expect(
        tester.getRect(lastItem).bottom,
        lessThanOrEqualTo(screen.height - navigationBarHeight),
      );
    }

    testWidgets('dashboard content scrolls clear of the navigation bar', (
      tester,
    ) async {
      await pumpApp(tester, navigationBar: true);
      await expectLastItemClearsNavigationBar(
        tester,
        find.text('To lease-out'),
      );
      // The Add Task button sits above the navigation bar too.
      expect(
        tester.getRect(find.byType(FloatingActionButton)).bottom,
        lessThanOrEqualTo(screen.height - navigationBarHeight),
      );
    });

    testWidgets('team performance list scrolls clear of the navigation bar', (
      tester,
    ) async {
      await pumpApp(tester, navigationBar: true);
      await tester.tap(find.text('VIEW TEAM PERFORMANCE'));
      await tester.pumpAndSettle();
      await expectLastItemClearsNavigationBar(
        tester,
        find.text('View tasks').last,
      );
    });

    testWidgets('task list scrolls clear of the navigation bar', (
      tester,
    ) async {
      await pumpApp(tester, navigationBar: true);
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      await expectLastItemClearsNavigationBar(
        tester,
        find.byType(TaskCard).last,
      );
    });
  });
}
