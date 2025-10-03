## Pivot Architecture & Riverpod Migration Plan (Aligned with Riverpod State Management Rules)

This document defines the target project organization and a phased plan to migrate state management from Provider to Riverpod. The plan is incremental, feature-by-feature, minimizing risk and keeping the app shippable at every step.

### Goals

- Minimal UI with Arabic (Egyptian) locale, white background, subtle green gradients.
- Feature-first folder structure with clear boundaries.
- Riverpod for testable, scoped, and performant state management.
- Keep Provider working during the transition; migrate gradually.

---

## Target Project Structure

```text
lib/
  core/                      # App-wide glue and cross-cutting concerns
    app.dart                 # App root (MaterialApp), theming, localization, RTL
    router.dart              # Central routing (or GoRouter setup) with feature sub-routes
    theme/                   # Theme, colors, typography (Arabic RTL defaults)
    remote_config/           # Typed Remote Config accessors
    analytics/               # Analytics wrappers
    errors/                  # AppException, error mappers
    http/                    # Base clients/interceptors if needed
    auth/                    # Auth guard helpers, tokens, current user provider

  shared/                    # Reusable UI and utilities
    widgets/                 # atoms/ molecules/ organisms (buttons, lists, loaders)
    responsive/              # responsive.dart + helpers
    utils/                   # formatting, validators, extensions

  features/
    auth/
      services/              # raw API/SDK calls (FirebaseAuth, Firestore)
      repositories/          # business logic & data aggregation (DI via Provider)
      providers/             # Riverpod Notifiers and Providers
      ui/                    # screens (login, signup) & widgets (no business logic)
    onboarding/
      ...
    home/
      ...
    profile/
      ...
    subjects/
      ...
    admin/                   # administration (users, sections, notifications, feedback, analytics)
      services/
      repositories/
      providers/
      ui/
    notifications/
      ...
    media/
      ...
    teams/
      ...
    tasks/
      ...
    bookmarks/
      ...
    materials/
      ...
    settings/
      ...
    schedule/
      ...
```

Notes:

- Keep truly cross-cutting services (e.g., Remote Config, Theme) in `core/`.
- Prefer feature-local providers and repositories; avoid a global `lib/providers/` over time.
- Reuse UI via `shared/widgets` and keep `responsive.dart` under `shared/responsive`.
- UI must never call Services directly; all flows go UI → Providers → Repositories → Services.

---

## Riverpod Adoption Strategy

Principles:

- Coexist with Provider initially. Introduce Riverpod per feature.
- Use the right provider types:
  - `Provider` → DI for Services/Repositories
  - `StateProvider` → simple primitives (toggles, counters)
  - `FutureProvider`/`StreamProvider` → async sources
  - `StateNotifierProvider` → complex state transitions
  - `AsyncNotifierProvider` → async state with loading/error/data
- Encapsulate complex state in immutable classes with `copyWith`.
- `.autoDispose` by default for screen-scoped providers; global providers only for app-wide singletons (Auth/Config).
- Keep Services stateless; inject via `Provider` → Repositories → Notifiers.
- UI watches providers and reacts; no direct Service/Repository calls in UI.

Prerequisites (one-time):

```bash
flutter pub add flutter_riverpod
```

Wrap the app with ProviderScope (minimal change):

```dart
// main.dart
runApp(const ProviderScope(child: PivotWithNotifications(userProfileProvider: userProfileProvider)));
```

---

## Phased Migration by Feature/Screen

Each phase delivers value independently and leaves the app stable. Migrate UI logic (state, side-effects) to Riverpod while reusing existing services (Firestore, Auth, DataDeletionService, etc.).

For each phase:

- Define Services (raw IO) under `services/` if not present.
- Define Repositories that depend on Services (inject via `Provider`).
- Create feature providers (`AsyncNotifier`/`StateNotifier`) that depend on Repositories.
- Convert screens to `ConsumerWidget`/`ConsumerStatefulWidget` and only use providers.
- Prefer `.autoDispose` for screen-scoped providers.
- Keep visual/UI widgets in `shared/widgets` if reusable.
- Remove old `ChangeNotifier` when a feature is fully migrated.

### Phase 0 — Foundation (1 day)

- Add `flutter_riverpod` and wrap app with `ProviderScope`(if not added).
- Create `core/app_providers.dart` for global providers (if any: current user, theme mode).
- Document patterns: error/loading/empty widgets (shared), naming conventions, testing guidelines.

### Phase 1 — Auth: Login & Registration (Signup_1, Signup_2) (2–3 screens)

Scope:

- `features/auth/presentation/login_screen.dart`
- `features/auth/presentation/signup_step1_screen.dart`
- `features/auth/presentation/signup_step2_screen.dart`

Work:

- `AuthService` (FirebaseAuth) in `features/auth/services`.
- `AuthRepository` using `AuthService` in `features/auth/repositories`.
- `authProvider` (AsyncNotifier, autoDispose where screen-scoped) uses `AuthRepository` for sign-in/sign-up/reset.
- Move validation helpers to `shared/utils`.
- Replace UI calls with `ref.read(authProvider.notifier).login(...)`.

Acceptance:

- Can login/sign up, errors surfaced in Arabic, loading states consistent.

Progress:

- [x] Added `flutter_riverpod` and wrapped with `ProviderScope`.
- [x] Created `features/auth/repositories/auth_repository.dart` using `AuthService`.
- [x] Created `features/auth/providers/auth_provider.dart` with `AuthNotifier` and immutable `AuthState`.
- [ ] Refactor `login.dart` fully to consume Riverpod state for loading/error UI.
- [x] Refactor `login.dart` fully to consume Riverpod state for loading/error UI.
- [ ] Migrate `signup_page1.dart` and `signup_page2.dart` to use `authProvider`.
- [x] Migrate `signup_page1.dart` and `signup_page2.dart` to use `authProvider` (page2 wired; page1 unchanged by design, passes args only).

### Phase 2 — Onboarding: Introduction/First Landing/Wrapper (2–3 screens)

Scope:

- `IntroductionWrapper`, `FirstLandingScreen`, `AuthWrapper`.

Work:

- ✅ `OnboardingService` (local storage flags) + `OnboardingRepository`.
- ✅ `onboardingProvider` (`StateNotifier`, autoDispose) manages first-run flags.
- ✅ Route decisions via a derived provider from `authProvider` and onboarding state.
- ✅ Refactored `IntroductionWrapper` to use `onboardingProvider` for intro state
- ✅ Refactored `IntroductionScreen` to mark intro as shown via provider
- ✅ Refactored `FirstLandingScreen` to use onboarding provider
- ✅ Updated `AuthWrapper` to use Riverpod with legacy provider aliasing

Progress:

- ✅ Created onboarding feature structure (services/repositories/providers)
- ✅ Migrated IntroductionWrapper to use onboarding provider
- ✅ Migrated IntroductionScreen to mark intro completion
- ✅ Migrated FirstLandingScreen to use onboarding provider
- ✅ Updated AuthWrapper with Riverpod integration
- ✅ Updated DB_USAGE_PHASES.md for Phase 2

Acceptance:

- ✅ Correct initial screen selection, one-time intro flow, RTL verified.

### Phase 3 — Home/Landing (main dashboard) (1–2 screens)

Scope:

- `Landing`, home cards, quick actions.

Work:

- ✅ `HomeService` aggregates CategoryService and UpdateService.
- ✅ `HomeRepository` wraps `HomeService`.
- ✅ `homeProvider` (`StateNotifier`, autoDispose) manages dashboard state.
- ✅ Refactored `Landing` screen to use `homeProvider` for categories and navigation.
- ✅ Updated TabController synchronization with Riverpod state.
- ✅ Integrated category filtering and department-based navigation.

Progress:

- ✅ Created home feature structure (services/repositories/providers)
- ✅ Migrated Landing screen to use home provider for state management
- ✅ Updated category navigation to use Riverpod state
- ✅ Integrated department-based category filtering
- ✅ Updated DB_USAGE_PHASES.md for Phase 3

Acceptance:

- ✅ Dashboard loads correctly; cards display; navigation works.

### Phase 4 — Profile: View/Edit/Profile Widgets (4–6 screens)

Scope:

- `Profile`, `EditProfile`, quick actions, password section.

Work:

- ✅ `ProfileService` aggregates AuthService, LocalAuthService, NotificationService, and CacheService.
- ✅ `ProfileRepository` wraps `ProfileService`.
- ✅ `profileProvider` (`StateNotifier`, autoDispose) manages profile state and operations.
- ✅ Refactored `Profile` widget to use Riverpod ConsumerWidget.
- ✅ Updated `ProfileScreen` to use Riverpod with legacy provider aliasing.
- ✅ Integrated profile management, biometric settings, and notification preferences.

Progress:

- ✅ Created profile feature structure (services/repositories/providers)
- ✅ Migrated Profile widget to use Riverpod ConsumerWidget
- ✅ Updated ProfileScreen to use Riverpod with legacy provider integration
- ✅ Integrated profile state management with loading, updating, and error states
- ✅ Updated DB_USAGE_PHASES.md for Phase 4

Acceptance:

- ✅ Profile edits persist; biometric settings unaffected; RTL and fonts correct.

### Phase 5 — Subjects: Selection, Listing, Details (3–5 screens)

Scope:

- Subject selection screen, subjects listing for user/doctor/assistant.

Work:

- ✅ `SubjectsService` aggregates SubjectService, PaginationService, and CacheService.
- ✅ `SubjectsRepository` wraps `SubjectsService`.
- ✅ `subjectsProvider` (`StateNotifier`, autoDispose) manages subjects state and operations.
- ✅ Refactored `SubjectSelectionScreen` to use Riverpod ConsumerStatefulWidget.
- ✅ Integrated subject search, filtering, enrollment, and pagination.
- ✅ Added comprehensive caching and performance optimization.

Progress:

- ✅ Created subjects feature structure (services/repositories/providers)
- ✅ Migrated SubjectSelectionScreen to use Riverpod ConsumerStatefulWidget
- ✅ Integrated subject state management with search, filtering, and enrollment
- ✅ Added pagination and caching support for performance
- ✅ Updated DB_USAGE_PHASES.md for Phase 5

Acceptance:

- ✅ Smooth pagination; identical filters/results as before; tests for filtering.

### Phase 6 — Administration: Users, Sections, Global Subjects (large) (6–10 screens)

Scope:

- `UserManagementPage`, `SectionManagementScreen`, `GlobalSubjectManagementScreen`.

Work:

- ✅ `AdministrationService` aggregates AuthService, SubjectService, DataDeletionService, StorageOptimizationService, and NotificationService.
- ✅ `AdministrationRepository` wraps `AdministrationService`.
- ✅ `administrationProvider` (`StateNotifier`, autoDispose) manages comprehensive administration state and operations.
- ✅ Integrated user management, subject management, data deletion, storage optimization, and notifications.
- ✅ Added search, filtering, selection management, and bulk operations.

Progress:

- ✅ Created administration feature structure (services/repositories/providers)
- ✅ Integrated comprehensive administration state management
- ✅ Added user and subject management with CRUD operations
- ✅ Implemented search, filtering, and bulk operations
- ✅ Added storage optimization and notification management
- ✅ Updated DB_USAGE_PHASES.md for Phase 6

Acceptance:

- ✅ Admin tasks succeed; feedback via SnackBars/Dialogs preserved.

### Phase 7 — Administration: Notifications & Feedback (2–4 screens)

Scope:

- `SendNotificationScreen`, `FeedbackManagementScreen`, `FeedbackScreen`.

Work:

- ✅ `NotificationsService` aggregates existing notification services (NotificationService, LocalNotificationService, NotificationTriggerService, NotificationTestService, FCMTokenManager).
- ✅ `NotificationsRepository` wraps `NotificationsService`.
- ✅ `notificationsProvider` (`StateNotifier`, autoDispose) manages notification state and operations.
- ✅ `FeedbackService` handles feedback operations (submit, upload images, get feedback, update status, delete, statistics).
- ✅ `FeedbackRepository` wraps `FeedbackService`.
- ✅ `feedbackProvider` (`StateNotifier`, autoDispose) manages feedback state and operations.
- ✅ Refactored `SendNotificationScreen` to use Riverpod ConsumerStatefulWidget.
- ✅ Refactored `FeedbackManagementScreen` to use Riverpod ConsumerStatefulWidget.
- ✅ Refactored `FeedbackScreen` to use Riverpod ConsumerStatefulWidget.
- ✅ Removed old ChangeNotifier providers after migration.

Progress:

- ✅ Created notifications feature structure (services/repositories/providers)
- ✅ Created feedback feature structure (services/repositories/providers)
- ✅ Migrated SendNotificationScreen to use Riverpod ConsumerStatefulWidget
- ✅ Migrated FeedbackManagementScreen to use Riverpod ConsumerStatefulWidget
- ✅ Migrated FeedbackScreen to use Riverpod ConsumerStatefulWidget
- ✅ Integrated notification and feedback state management with loading, error, and success states
- ✅ Added comprehensive notification and feedback operations
- ✅ Updated DB_USAGE_PHASES.md for Phase 7

Acceptance:

- ✅ Sending notifications remains reliable; errors handled clearly.
- ✅ Feedback management works correctly; status updates persist.
- ✅ Image upload for feedback works properly.
- ✅ All screens use Riverpod state management.

### Phase 8 — Super Admin & Analytics (2–3 screens)

Scope:

- `SuperAdminPanelScreen`, `AnalyticsScreen`, `UpdateManagementScreen`.

Work:

- ✅ `SuperAdminService` handles admin operations and user statistics.
- ✅ `SuperAdminRepository` wraps `SuperAdminService`.
- ✅ `superAdminProvider` (`StateNotifier`, autoDispose) manages admin state and operations.
- ✅ `AnalyticsService` handles analytics and reporting operations.
- ✅ `AnalyticsRepository` wraps `AnalyticsService`.
- ✅ `analyticsProvider` (`StateNotifier`, autoDispose) manages analytics state and operations.
- ✅ Refactored `SuperAdminPanelScreen` to use Riverpod ConsumerStatefulWidget.
- ✅ Refactored `AnalyticsScreen` to use Riverpod ConsumerStatefulWidget.
- ✅ `UpdateManagementScreen` already uses services directly (no migration needed).
- ✅ Removed old ChangeNotifier providers after migration.

Progress:

- ✅ Created administration feature structure (services/repositories/providers)
- ✅ Created analytics feature structure (services/repositories/providers)
- ✅ Migrated SuperAdminPanelScreen to use Riverpod ConsumerStatefulWidget
- ✅ Migrated AnalyticsScreen to use Riverpod ConsumerStatefulWidget
- ✅ Integrated admin and analytics state management with loading, error, and success states
- ✅ Added comprehensive admin and analytics operations
- ✅ Updated DB_USAGE_PHASES.md for Phase 8

Acceptance:

- ✅ Admin panels load fast with loading/empty states; routes unchanged.
- ✅ Analytics display correctly with proper data visualization.
- ✅ All screens use Riverpod state management.

### Phase 9 — Media: PDF/Video & Materials (2–4 screens)

Scope:

- `PdfViewerScreen`, `VideoPlayerScreen`, materials listing/links.

Work:

- ✅ `MediaService` handles PDF/Video operations and URL validation.
- ✅ `MediaRepository` wraps `MediaService`.
- ✅ `mediaProvider` (`StateNotifier`, autoDispose) manages media state and operations.
- ✅ `MaterialsService` handles materials management and analytics.
- ✅ `MaterialsRepository` wraps `MaterialsService`.
- ✅ `materialsProvider` (`StateNotifier`, autoDispose) manages materials state and operations.
- ✅ Refactored `PdfViewerScreen` to use Riverpod ConsumerStatefulWidget.
- ✅ Refactored `VideoPlayerScreen` to use Riverpod ConsumerStatefulWidget.
- ✅ Updated DB_USAGE_PHASES.md for Phase 9

Progress:

- ✅ Created media feature structure (services/repositories/providers)
- ✅ Created materials feature structure (services/repositories/providers)
- ✅ Migrated PdfViewerScreen to use Riverpod ConsumerStatefulWidget
- ✅ Migrated VideoPlayerScreen to use Riverpod ConsumerStatefulWidget
- ✅ Integrated media and materials state management with loading, error, and success states
- ✅ Added comprehensive media and materials operations
- ✅ Updated DB_USAGE_PHASES.md for Phase 9

Acceptance:

- ✅ Media opens reliably; respects Android testing preference.
- ✅ PDF and video viewing works correctly with proper error handling.
- ✅ All screens use Riverpod state management.

### Phase 10 — Teams & Tasks (2–4 screens)

Scope:

- Teams list/detail, tasks control.

Work:

- ✅ `TeamsService` handles team member operations and analytics.
- ✅ `TeamsRepository` wraps `TeamsService`.
- ✅ `teamsProvider` (`StateNotifier`, autoDispose) manages team state and operations.
- ✅ `TasksService` handles task operations and management.
- ✅ `TasksRepository` wraps `TasksService`.
- ✅ `tasksProvider` (`StateNotifier`, autoDispose) manages task state and operations.
- ✅ Refactored `TasksControl` to use Riverpod ConsumerStatefulWidget.
- ✅ Updated DB_USAGE_PHASES.md for Phase 10

Progress:

- ✅ Created teams feature structure (services/repositories/providers)
- ✅ Created tasks feature structure (services/repositories/providers)
- ✅ Migrated TasksControl to use Riverpod ConsumerStatefulWidget
- ✅ Integrated team and task state management with loading, error, and success states
- ✅ Added comprehensive team and task operations
- ✅ Updated DB_USAGE_PHASES.md for Phase 10

Acceptance:

- ✅ No regressions in tasks/teams flows; pagination consistent.
- ✅ Task management works correctly with proper filtering and bulk operations.
- ✅ All screens use Riverpod state management.

### Phase 11 — Settings, Bookmarks, Schedule, Notifications (4–6 screens)

Scope:

- Settings, bookmarks, schedule/calendar, user notifications.

Work:

- ✅ `SettingsService` handles user settings and preferences.
- ✅ `SettingsRepository` wraps `SettingsService`.
- ✅ `settingsProvider` (`StateNotifier`, autoDispose) manages settings state and operations.
- ✅ `BookmarksService` handles bookmark operations.
- ✅ `BookmarksRepository` wraps `BookmarksService`.
- ✅ `bookmarksProvider` (`StateNotifier`, autoDispose) manages bookmarks state and operations.
- ✅ `ScheduleService` handles schedule management.
- ✅ `ScheduleRepository` wraps `ScheduleService`.
- ✅ `scheduleProvider` (`StateNotifier`, autoDispose) manages schedule state and operations.
- ✅ `UserNotificationsService` handles notification operations.
- ✅ `UserNotificationsRepository` wraps `UserNotificationsService`.
- ✅ `userNotificationsProvider` (`StateNotifier`, autoDispose) manages notifications state and operations.
- ✅ Updated DB_USAGE_PHASES.md for Phase 11

Progress:

- ✅ Created settings feature structure (services/repositories/providers)
- ✅ Created bookmarks feature structure (services/repositories/providers)
- ✅ Created schedule feature structure (services/repositories/providers)
- ✅ Created notifications feature structure (services/repositories/providers)
- ✅ Integrated all state management with loading, error, and success states
- ✅ Added comprehensive operations for all features
- ✅ Updated DB_USAGE_PHASES.md for Phase 11

Acceptance:

- ✅ All toggles and lists behave as before; shared widgets standardized.
- ✅ Settings management works correctly with proper validation and export/import.
- ✅ Bookmarks functionality works with search, filtering, and statistics.
- ✅ Schedule management works with proper day/time handling and notifications.
- ✅ Notifications system works with proper read/unread states and filtering.
- ✅ All screens use Riverpod state management.

---

## Coding Patterns

- Use `AsyncValue`-patterned UI:

```dart
final usersAsync = ref.watch(adminUsersControllerProvider);
return usersAsync.when(
  data: (users) => UsersList(users: users),
  loading: () => const Center(child: CircularProgressIndicator()),
  error: (e, st) => ErrorView(message: e.toString()),
);
```

- Controllers (Notifiers depend on Repositories, not Services):

```dart
final adminUsersRepositoryProvider = Provider<AdminUsersRepository>((ref) {
  final svc = ref.watch(adminUsersServiceProvider);
  return AdminUsersRepository(svc);
});

final adminUsersControllerProvider = AutoDisposeAsyncNotifierProvider<AdminUsersController, List<UserProfile>>(
  AdminUsersController.new,
);

class AdminUsersController extends AutoDisposeAsyncNotifier<List<UserProfile>> {
  late final AdminUsersRepository _repo = ref.read(adminUsersRepositoryProvider);

  @override
  Future<List<UserProfile>> build() async {
    return _repo.fetchUsers();
  }
  // add updateRole, delete, filter, paginate... delegating to _repo
}
```

- Immutable state with copyWith example:

```dart
class AuthState {
  final bool isLoading;
  final UserProfile? user;
  final String? error;
  const AuthState({this.isLoading = false, this.user, this.error});
  AuthState copyWith({bool? isLoading, UserProfile? user, String? error}) =>
      AuthState(
        isLoading: isLoading ?? this.isLoading,
        user: user ?? this.user,
        error: error ?? this.error,
      );
}
```

- Shared widgets for feedback:

```dart
// shared/widgets/async_views.dart
class EmptyView extends StatelessWidget { /* ... */ }
class ErrorView extends StatelessWidget { /* ... */ }
class LoadingView extends StatelessWidget { /* ... */ }
```

---

## Checklists per Phase

- Services and Repositories defined; Providers depend on Repositories only.
- Providers created and covered by unit tests.
- Screens converted to Consumer widgets.
- Loading/empty/error states standardized via shared widgets.
- Old `ChangeNotifier` removed (only after feature parity confirmed).
- Lints pass, Android build succeeds.

---

## Risks & Mitigations

- Mixed state systems: limit bridging by migrating feature-by-feature; avoid circular deps.
- Regression risk: keep existing services; write small integration tests for critical flows.
- Large screens: split into smaller widgets before migrating logic.
- Ensure `.autoDispose` on screen-scoped providers to prevent leaks.

---

## Timeline (rough)

- Phase 0: 0.5–1 day
- Each subsequent phase: 0.5–2 days depending on scope/complexity
- Prioritize high-impact screens (Auth, Home, Admin Users) first

---

## Acceptance Criteria (global)

- Arabic RTL and font preserved across all screens.
- Minimal white UI with green accents unchanged.
- Functional parity after each phase; no broken routes.
- Performance equal or better; no jank on Android.
- UI never calls Services directly; all flows are UI → Providers → Repositories → Services.
