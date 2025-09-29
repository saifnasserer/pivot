## Database Usage by Phases

This document captures how Firestore and Firebase Auth are used in each migration phase.

### Phase 1 — Auth (Login/Registration)

- Services: `AuthService` uses Firebase Auth and Firestore.
- Repositories: `AuthRepository` wraps `AuthService`.
- Collections/Docs:
  - `users/{uid}`: User profile document with fields (example):
    - `id: string`
    - `name: string`
    - `email: string`
    - `department: string`
    - `level: string`
    - `section: string`
    - `profileImageUrl: string?`
    - `userNumber: int`
    - `gender: string`
    - `createdAt: serverTimestamp`
- Operations:
  - Read `users/{uid}` on login to hydrate `UserProfile`.
  - Write `users/{uid}` on registration with generated `userNumber` and `createdAt`.
  - Additional registration metadata captured in-memory (e.g., `registrationDate`) prior to profile write.

### Phase 2 — Onboarding (Introduction & First Run)

- Services: `OnboardingService` uses SharedPreferences for local storage.
- Repositories: `OnboardingRepository` wraps `OnboardingService`.
- Local Storage Keys:
  - `first_run_completed`: Boolean flag for first run completion
  - `intro_shown`: Boolean flag for introduction video completion
  - `pending_deep_link`: String for storing deep links during onboarding
- Operations:
  - Read/write first run status to determine if user needs onboarding
  - Read/write intro shown status to determine if user needs introduction
  - Read/write pending deep links for post-onboarding navigation
  - Clear pending deep links after successful navigation

### Phase 3 — Home/Landing (Dashboard)

- Services: `HomeService` aggregates CategoryService and UpdateService.
- Repositories: `HomeRepository` wraps `HomeService`.
- Data Sources:
  - CategoryService: Department-based category filtering and time filters
  - UpdateService: App update checks and team formation settings
  - UserProfile: Department information for category determination
- Operations:
  - Load categories based on user department
  - Get department codes and time filters for announcements
  - Check for app updates and team formation availability
  - Manage category navigation state

Planned next phases will append their collections and operations here.
