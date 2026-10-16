# Reside — Manager's Team Dashboard

[![Build & Release Flutter App](https://github.com/Akshaykalwar8933/assessment01/actions/workflows/build.yml/badge.svg)](https://github.com/Akshaykalwar8933/assessment01/actions/workflows/build.yml)

A Flutter app that recreates the Reside team-management screens:

- **Manager's Team View** (Dashboard)
- **Team Performance**
- **Team's Task** (Open / Overdue / Closed tabs)

Admins can also **create tasks and assign them to a team member**.

It is built with **Flutter 3.41.4**, **GetX** and **Hive**, following **Clean Architecture**. All data is stored on the device and there is no backend yet. The code is organized so a REST API or Firebase can be added later without changing the UI or the business logic.

| | |
|---|---|
| Package name | `popaya_assessment` |
| Android application ID | `com.example.popaya_assessment` |
| iOS bundle ID | `com.example.popayaAssessment` |
| Design reference | 414 × 870 logical pixels |

---

## Features

### Dashboard (Manager's Team View)
- Reside logo header, plus a team-member picker (avatar dropdown). The selected member is saved across restarts.
- A **My Tasks / Teams** switch:
  - **My Tasks** shows the selected member's tasks.
  - **Teams** shows everyone's tasks.
- **Open / Overdue / Closed** task counts, with a duration selector. Tap a count to open Team's Task on that tab.
- A **View Team Performance** button.
- **Properties** (All listings, Under Onboarding) and **Opportunities** (To rent-in, To lease-out).

### Duration filter
**Today, Week, Month, Quarter, Annual, Till Date, Date Range.**
- Date Range opens a date-range picker. Cancelling keeps the previous choice.
- The same filter is used on the Dashboard, on Team Performance and in Team's Task filters.

### Team Performance
- One card per team member, with a **donut chart** (`fl_chart`) and a legend.
- Members with no tasks show a neutral grey ring.
- Has its own duration filter.
- Tap a member's card to see that member's tasks.

### Team's Task
- **Open / Overdue / Closed** tabs share one reusable list and one reusable task card.
- Each card shows the assignee, the due date ("Today 4:30PM"), how long it's been overdue ("Overdue 2 days"), or "Closed".
- **Filters:** duration, assignee, has / no due date.
- **Sort:** due date (soonest or latest), created date (newest or oldest), title A–Z.
- Tap a task to see its details, then **Mark as closed** or **Reopen** it.

### Add Task (admins only)
An **Add Task** button appears **only on the Dashboard**, and **only for the Admin role**. It opens a bottom sheet with these fields:

| Field | Required | Rules |
|---|---|---|
| Assign to (team member) | Yes | Must be an existing member |
| Template | No | Picking one fills in the title and description |
| Task title | Yes | 3–120 characters |
| Description | No | Up to 500 characters |
| Due date & time | Yes | Must be in the future |

- **The assignee is pre-selected:**
  - on the Dashboard, the selected member is filled in when **My Tasks** is active;
  - on Team's Task, the member is filled in when the list is showing one member's tasks.
- The admin can always pick a different member.
- Every invalid field shows its own message, and nothing is saved until all fields are valid.
- Double taps are ignored. The **Add Task** button shows a spinner while saving.
- The new task gets a unique ID and status **Open**, and is saved to Hive.
- The sheet closes only after a successful save, and a "Task added" message appears.
- If saving fails, the error shows inside the sheet and the sheet stays open.
- Dashboard counts, Team Performance and the task lists all **refresh automatically**.

### Roles
- Users and roles come from mock data: one **Admin** (the manager) plus one **Team Member** login per member.
- The Admin is the default user, and the current user is saved across restarts.
- **Team members:**
  - never see the Add Task button;
  - have their dashboard locked to their own tasks.
- **Where the admin check runs:** in three places, not just by hiding the button:
  - when the sheet is opened;
  - in `SessionController` before submitting;
  - in the `CreateTask` use case.
- There is no switch-account button in the UI. The current user changes through `SessionController.switchToUser`, which the tests use. A real sign-in screen can call it later.

### Error handling
- **Screens never get stuck loading.** Every controller catches *any* error, not only expected ones, and shows the error screen with **Retry**.
- **Messages are friendly.** Expected failures show their own message, such as "Could not save the task." Unexpected ones show "Something went wrong. Please try again." and are logged. Error messages use one red snackbar style, and the same message is not stacked repeatedly.
- **No grey or red screens.** A widget that fails to build shows "This section could not be displayed." while the rest of the screen keeps working. In debug builds the cause is also shown.
- **Uncaught async errors** (futures, streams) are caught app-wide and shown as a snackbar instead of crashing.
- **Startup failure:** if local storage can't be opened at launch, a friendly screen with **Retry** appears instead of a blank app.
- See `lib/core/error/error_reporting.dart`.

### System bars and safe areas
- Edge-to-edge on Android (enforced on Android 15+) and iOS. The status and navigation bars are transparent with dark icons, and there is no grey scrim.
- Headers sit below the status bar, the notch and the Dynamic Island.
- Lists, the Add Task button and every bottom sheet's buttons stay above the gesture bar or the 3-button navigation bar.
- The app has a light design only. Android night themes and iOS (`UIUserInterfaceStyle = Light`) stay light, so dark mode causes no black flashes or black strips.

### General
- Loading, empty and error states (with **Retry**) on every screen, plus pull-to-refresh on every list.
- **Responsive layout:** `flutter_screenutil` scaling from the 414 × 870 design, plus `Expanded`, `Flexible`, `FittedBox` and scrolling. Tests check for overflow at **320×568, 414×870 and 480×1000**.
- Montserrat font and the Reside logo are bundled, so the app works offline.

---

## Technologies used

| Technology | Version | What it's used for |
|---|---|---|
| **Flutter** | **3.41.4** (stable) | UI framework |
| **Dart** | 3.11.1 | Language (null-safe) |
| [`get`](https://pub.dev/packages/get) (GetX) | 4.7.3 | State management (`Rx`, `Obx`), dependency injection, named routes and bindings, snackbars |
| [`hive_ce`](https://pub.dev/packages/hive_ce) + [`hive_ce_flutter`](https://pub.dev/packages/hive_ce_flutter) | 2.22.0 / 2.3.4 | Local storage on the device. This is the maintained fork of Hive. The type adapters are hand-written, so no `build_runner` is needed. |
| [`flutter_screenutil`](https://pub.dev/packages/flutter_screenutil) | 5.9.3 | Responsive sizing (`.w`, `.h`, `.r`, `.sp`) from the 414 × 870 design |
| [`fl_chart`](https://pub.dev/packages/fl_chart) | 1.2.0 | Team Performance donut charts (`PieChart`) |
| [`intl`](https://pub.dev/packages/intl) | 0.20.3 | Date and time formatting |
| `flutter_lints` | 6.0.0 | Lint rules for `flutter analyze` |
| **Montserrat** font | bundled | App font (SIL Open Font License, see `assets/fonts/OFL.txt`) |
| **GitHub Actions** | — | Builds the release APK and publishes it as a GitHub Release (see below) |
| **JDK 17** | — | Android Gradle build (locally and in CI) |

**Architecture and practices:**
- Clean Architecture and SOLID principles.
- Repository pattern and use cases.
- Dependency injection with GetX bindings.
- An injectable `Clock`, so tests control time.
- Unit, persistence and widget tests.

---

## Architecture

```
lib/
├── core/            theme (AppColors, AppTextStyles, AppTheme), routes (names, args, GetPages),
│                    di (composition root), error (AppException), utils (calendar date helpers)
├── domain/          pure Dart — no Flutter, Hive or GetX
│   ├── entities/        Task (incl. derived overdue rule), TeamMember, AppUser/UserRole,
│   │                    TaskDraft (incl. validation)/TaskTemplate, DurationFilter (incl. date range),
│   │                    TaskStats/MemberPerformance, TaskFilter/TaskSortOrder, PortfolioSummary
│   ├── repositories/    repository contracts: Task, Team, Portfolio, Auth
│   ├── services/        TaskListQueryService (select / filter / sort / group), Clock
│   └── usecases/        GetTaskCountsByStatus, GetTeamPerformance, GetFilteredTasksGroupedByStatus,
│                        UpdateTaskClosedStatus, CreateTask
├── data/
│   ├── models/          Hive models + hand-written TypeAdapters
│   ├── datasources/     HiveLocalDataSource (boxes, one-time seeding), MockData
│   └── repositories/    Hive-backed implementations, MockPortfolioRepository, MockAuthRepository
└── presentation/
    ├── controllers/     Dashboard, TeamPerformance, TeamTasks, AddTask, Session (app-wide)
    ├── bindings/        one GetX Binding per route
    ├── screens/         dashboard/, team_performance/, team_tasks/ (+ filter / sort / details sheets),
    │                    add_task/ (Add Task sheet); each screen keeps its single-use widgets
    └── widgets/         widgets shared by several screens: TaskCard, DurationFilterDropdown,
                         TeamMemberAvatar, BackButtonTitleHeader, loading/error/message views, labels
```

**How a request flows:**

```
Screen (widget) → GetX Controller → Use case / Repository contract → Hive repository → Hive box
```

### Key decisions
- **Overdue is calculated, never stored.**
  - A task's stored status is only `open` or `closed`.
  - It counts as *overdue* when it is open and its due date has passed (`Task.displayStatusAt`). Each task is in exactly one of the three statuses.
- **One source of truth.** Dashboard counts, Team Performance and the task lists all come from the same task data and the same rules, so their numbers always agree.
- **Duration rule.** A task falls in a period based on one date:
  - closed tasks: the completion date;
  - open tasks: the due date;
  - tasks with neither: the creation date.

  Presets mean the current calendar period (weeks start on Monday). Till Date means everything up to the end of today.
- **Controllers never touch Hive.**
  - Controllers use use cases for real business logic, and repository contracts for simple reads and writes.
  - To move to a REST API or Firebase, add new repository implementations and register them in `lib/core/di/injection.dart`.
- **Live updates.** `TaskRepository.watchTaskChanges()` (built on Hive's `box.watch()`) sends an event whenever a task is created, closed or reopened. Every screen listens to it.
- **Seeding.**
  - Mock data is written on the first launch only, so your changes survive restarts.
  - Seed dates are relative to that first launch, so every duration shows data.
  - Increase `HiveLocalDataSource.seedVersion` to reseed.

---

## Getting started

### Requirements
- **Flutter 3.41.4** (stable channel), which includes Dart 3.11.1. Check with `flutter --version`.
- **JDK 17** and the Android SDK for Android builds. Xcode is needed for iOS builds.

### Run locally
```bash
git clone https://github.com/Akshaykalwar8933/assessment01.git
cd assessment01
flutter pub get
flutter run            # on a connected device or emulator
```

### Useful commands
```bash
flutter analyze                 # static analysis
flutter test                    # unit, persistence and widget tests
flutter build apk --debug       # debug APK
flutter build apk --release     # release APK → build/app/outputs/flutter-apk/app-release.apk
```

---

## CI/CD: automatic APK build with GitHub Actions

The workflow is in [`.github/workflows/build.yml`](.github/workflows/build.yml) and is named **"Build & Release Flutter App"**.

**What it does:**
1. Checks out the repository.
2. Sets up **JDK 17** (Temurin), with a Gradle cache.
3. Sets up **Flutter 3.41.4** (stable), with an SDK cache, using `subosito/flutter-action`.
4. Runs `flutter pub get`.
5. Builds a **release APK** with `flutter build apk --release --no-tree-shake-icons`.
6. Creates a **GitHub Release** with auto-generated release notes, using `softprops/action-gh-release`, and attaches `app-release.apk`.

**How to run it:**
1. Open the repository on GitHub and go to **Actions**.
2. Choose **Build & Release Flutter App**, then **Run workflow**.
3. Enter a **Release Tag** (for example `v1.0.1`) and a **Release Name** (for example `Apk v1.0.1`). Use a new tag each time.
4. When it finishes, download the APK from the repository's **Releases** page.

The workflow runs only when started by hand (`workflow_dispatch`). It needs `contents: write` permission to create the release, and that permission is already set in the file.

---

## Tests

Run them with `flutter test`.

| Area | What's covered |
|---|---|
| `test/domain/` | The overdue rule, every duration option, filtering, sorting (including tasks with no due date), task counts, per-member performance adding up to team totals |
| `test/domain/create_task_test.dart` | Admin-only creation, unique IDs, trimming, the change notification, every validation rule |
| `test/data/` | Hive seeding once; tasks, descriptions, the member selection and the current user surviving a simulated restart; the change stream; valid mock data |
| `test/presentation/error_handling_and_system_ui_test.dart` | Unexpected errors show the error screen (not a spinner) and snackbars, the build-error fallback, uncaught async errors, transparent system bars with dark icons, headers below the status bar, lists and buttons clearing a navigation bar |
| `test/presentation/` | Every screen without overflow at three phone sizes, counts matching the data, tap-through to the right tab, closing a task, saving the member selection, error and retry, Add Task hidden and refused for team members, validation then creating a task and updating counts, the sheet staying open when saving fails |

The widget tests use in-memory repositories, a fixed clock and the real Montserrat font.

---

## Notes and assumptions

- Two design frames label the first tab "SHORTLISTED". The app uses **OPEN**, to match the Open frame and the spec.
- The design uses photo avatars. The app shows colored initials avatars, and `TeamMember.avatarUrl` is shown when it's set.
- Properties and Opportunities are fixed mock data behind `PortfolioRepository`, because no task data drives them.
- The hamburger icon is decorative, because the design doesn't define a menu.
- A new task counts toward the period it's due in. A task due next week shows under **Week**, not **Today**.
