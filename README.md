# Reside — Manager's Team Dashboard

Package: `popaya_assessment` (Android application ID `com.example.popaya_assessment`; iOS bundle ID `com.example.popayaAssessment`).

A Flutter app for the Reside team-management screens: **Manager's Team View**, **Team Performance**, and **Team's Task** (Open / Overdue / Closed). It is built with GetX, Clean Architecture and Hive. All data is stored on the device. There is no backend yet.

## Features

- **Dashboard**
  - Pick a team member from the avatar dropdown. The choice is saved across restarts.
  - Switch between **My Tasks** (the selected member's tasks) and **Teams** (everyone's tasks).
  - Open / Overdue / Closed counts, with a duration selector.
  - Properties and Opportunities cards.
  - Tap a count to open Team's Task on that tab.
- **Duration options:** Today, Week, Month, Quarter, Annual, Till Date, and Date Range. Date Range opens a range picker, and cancelling keeps the previous choice.
- **Team Performance**
  - One card per member with a segmented donut (`fl_chart` `PieChart`) and a legend. Members with no tasks show a neutral ring.
  - Has its own duration filter.
  - Tap a card to see that member's tasks.
- **Team's Task**
  - One reusable list for all three tabs.
  - **Filters** (duration, assignee, has / no due date) and **Sort** (due date, created date, title).
  - Tap a task to see its details and **Mark as closed** or **Reopen** it. The change is saved to Hive and every count updates.
- **Admin-only Add Task**:
  - An "Add Task" floating button appears on Dashboard and Team's Task only for the **Admin** role.
  - It opens a bottom sheet where you choose the assignee, an optional template or your own title, an optional description, and a due date and time.
  - Each field is checked, with a message next to it. Double taps are ignored, and the sheet closes only after the task is saved.
  - New tasks are saved as **Open** in Hive.
  - The dashboard counts, Team Performance and task lists all refresh straight away.
- **Roles** come from a mock setup: one Admin (the manager) plus a Team Member login for each member. Tap the menu icon on the dashboard to switch accounts. The choice is saved across restarts.
  - Team members can't add tasks.
  - Their dashboard is locked to their own tasks.
  - The admin check runs in the sheet, in `SessionController`, and in the `CreateTask` use case.
- Loading, empty and error states (with retry), plus pull-to-refresh on every list.
- Responsive layout based on a 414 × 870 design with `flutter_screenutil`, `Expanded`/`Flexible`, `FittedBox` and scrolling. Tests check for overflow at 320×568, 414×870 and 480×1000.

## Architecture

```
lib/
├── core/          theme (colors, text styles, ThemeData incl. inputs/FAB), routes (named GetPages + typed args),
│                  di (composition root), error (AppException), utils (date helpers)
├── domain/        pure Dart — no Flutter, Hive or GetX
│   ├── entities/      Task, TeamMember, AppUser/UserRole, TaskDraft/TaskTemplate, DurationFilter,
│   │                  TaskStats, TaskFilter/TaskSortOrder, PortfolioSummary
│   ├── repositories/  TaskRepository, TeamRepository, PortfolioRepository, AuthRepository (abstract)
│   ├── services/      TaskStatusRules (derived overdue), DurationDateRangeResolver,
│   │                  TaskListQueryService, TaskStatsCalculator, TaskDraftValidator, Clock
│   └── usecases/      GetTaskCountsByStatus, GetTeamPerformance, GetFilteredTasksGroupedByStatus,
│                      UpdateTaskClosedStatus, CreateTask,
│                      WatchTaskChanges, member/portfolio/session use cases
├── data/
│   ├── models/        Hive models + hand-written TypeAdapters
│   ├── datasources/   HiveLocalDataSource (boxes, one-time seeding), MockData
│   └── repositories/  Hive-backed implementations; MockPortfolioRepository, MockAuthRepository
└── presentation/
    ├── controllers/   Dashboard, TeamPerformance, TeamTasks, AddTask and Session (app-wide) controllers
    ├── bindings/      one GetX Binding per route
    ├── screens/       dashboard/ (+ account switcher), team_performance/, team_tasks/ (+ filter / sort /
    │                  action sheets), add_task/ (sheet + admin-only FAB)
    └── widgets/       CountSummaryCard, DurationFilterDropdown, TeamMemberDropdownSelector,
                       TaskStatusDonutChart, TaskCard, …
```

### Key decisions

- **Overdue is derived, never stored.** `Task.status` is only `open` or `closed`. A task is *overdue* when it is open and its `dueAt` is before now (`TaskStatusRules.displayStatusAt`). The three statuses never overlap.
- **One source of truth.** Dashboard counts, Team Performance and the task lists all use the same `TaskListQueryService` and `TaskStatsCalculator`, so their numbers always agree.
- **Duration window.** A task belongs to a period based on the date returned by `dateUsedForDurationFilter`:
  - closed tasks use the completion date;
  - open tasks use the due date;
  - tasks with neither use the creation date.

  Presets mean the current calendar period, and weeks start on Monday. Till Date covers everything up to the end of today.
- **Controllers never touch Hive.** Controllers depend on use cases, and use cases depend on repository interfaces. To switch to a REST or Firebase backend, add new `*Repository` implementations and register them in `core/di/injection.dart`. No UI or business-logic changes are needed.
- **Testable time.** A `Clock` is injected everywhere "now" matters, and tests use a fixed clock.
- **Seeding.** Mock data is written only when the stored `seed_version` doesn't match. After that, data is never reseeded, so changes survive restarts. Seed dates are relative to the first launch, so every duration shows data. Increase `HiveLocalDataSource.seedVersion` to reseed.
- **Live updates.** `TaskRepository.watchTaskChanges()` (built on Hive's `box.watch()`) sends an event whenever a task is created, closed or reopened. Each screen controller listens to it, so every screen stays in sync without manual refreshes.
- **Roles.** `AuthRepository` returns the current `AppUser` and their `UserRole`. Today `MockAuthRepository` provides it. To use real sign-in later, add an API-backed implementation and change nothing else.
- **Hive adapters are hand-written,** using the generator's field-index format. This avoids `build_runner` but keeps the schema able to evolve.

## Dependencies

| Package | Purpose |
|---|---|
| `get` | State management, dependency injection, named routes |
| `hive_ce`, `hive_ce_flutter` | Local persistence. This is the maintained fork of Hive, compatible with Dart 3.11. |
| `flutter_screenutil` | Scaling from the 414 × 870 design |
| `intl` | Date formatting |
| `fl_chart` | Team performance donut charts |

The Reside wordmark is bundled at `assets/images/reside_logo.png` and shown in the dashboard header (`ResideLogoHeader`).

Montserrat (Regular, Medium, SemiBold and Bold) is bundled in `assets/fonts/` under the SIL Open Font License (see `OFL.txt`), so it works offline.

## Setup and running

Requires Flutter 3.41+ / Dart 3.11+.

```bash
flutter pub get
flutter run                  # on a connected device or emulator
flutter test                 # unit, persistence and widget tests
flutter analyze
flutter build apk --debug    # Android build
```

## Tests

- `test/domain/create_task_test.dart` covers admin-only creation, unique IDs, trimming, the change notification, and every validation rule.
- `test/domain/` covers the overdue rule, every duration option, filtering, sorting (including tasks with no due date), stats, and per-member performance adding up to team totals.
- `test/data/` covers Hive seeding once, task descriptions, the change stream, the saved account choice, task changes and the member selection surviving a simulated restart, and checks that the mock data is valid.
- `test/presentation/` uses in-memory repositories and a fixed clock, with real Montserrat loaded. It covers:
  - every screen rendering without overflow at three phone sizes;
  - dashboard counts matching the task data, and tapping a count opening the right tab;
  - closing a task;
  - saving the member selection;
  - the error state and retry;
  - the Add Task button being hidden and refused for team members;
  - validation, then creating a task and updating dashboard counts;
  - the sheet staying open with an error when saving fails.

## Notes and assumptions

- Two of the design frames label the first tab "SHORTLISTED". The app uses **OPEN**, to match the Open frame and the spec.
- The design uses photo avatars. The app uses colored initials avatars. `TeamMember.avatarUrl` is supported and shown when set.
- Properties and Opportunities are fixed mock data behind `PortfolioRepository`, because nothing in the task data drives them.
- The hamburger icon opens the **demo account switcher**, because the design doesn't define a menu. Remove it once real sign-in exists.
- A new task is counted in a duration based on its due date, like every other open task. A task due next week shows under Week, not Today.
