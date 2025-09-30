# Riverpod Quick Reference Guide

## 🚀 Quick Start Cheat Sheet

### Common Migration Patterns

#### Pattern 1: StatelessWidget → ConsumerWidget

```dart
// BEFORE
class MyScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<MyProvider>(context);
    return Text(provider.data);
  }
}

// AFTER
class MyScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(myProvider);
    return Text(state.data);
  }
}
```

#### Pattern 2: StatefulWidget → ConsumerStatefulWidget

```dart
// BEFORE
class MyScreen extends StatefulWidget {
  @override
  _MyScreenState createState() => _MyScreenState();
}

class _MyScreenState extends State<MyScreen> {
  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<MyProvider>(context);
    return Text(provider.data);
  }
}

// AFTER
class MyScreen extends ConsumerStatefulWidget {
  @override
  ConsumerState<MyScreen> createState() => _MyScreenState();
}

class _MyScreenState extends ConsumerState<MyScreen> {
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(myProvider);
    return Text(state.data);
  }
}
```

#### Pattern 3: Provider.of with listen: false → ref.read

```dart
// BEFORE
onPressed: () {
  Provider.of<MyProvider>(context, listen: false).doSomething();
}

// AFTER
onPressed: () {
  ref.read(myProvider.notifier).doSomething();
}
```

#### Pattern 4: context.read → ref.read

```dart
// BEFORE
onPressed: () {
  context.read<MyProvider>().doSomething();
}

// AFTER
onPressed: () {
  ref.read(myProvider.notifier).doSomething();
}
```

---

## 📦 Available Riverpod Providers

### Core Providers

| Legacy                | Riverpod              | Path                                                     |
| --------------------- | --------------------- | -------------------------------------------------------- |
| `UserProfileProvider` | `userProfileProvider` | `lib/features/user/providers/user_profile_provider.dart` |
| `AuthProvider`        | `authProvider`        | `lib/features/auth/providers/auth_provider.dart`         |

### Feature Providers

| Feature        | Provider                 | Path                                                                 |
| -------------- | ------------------------ | -------------------------------------------------------------------- |
| Tasks          | `tasksProvider`          | `lib/features/tasks/providers/tasks_provider.dart`                   |
| Schedule       | `scheduleProvider`       | `lib/features/schedule/providers/schedule_provider.dart`             |
| Profile        | `profileProvider`        | `lib/features/profile/providers/profile_provider.dart`               |
| Announcements  | `announcementsProvider`  | `lib/features/announcements/providers/announcements_provider.dart`   |
| Home           | `homeProvider`           | `lib/features/home/providers/home_provider.dart`                     |
| Teams          | `teamsProvider`          | `lib/features/teams/providers/teams_provider.dart`                   |
| Subjects       | `subjectsProvider`       | `lib/features/subjects/providers/subjects_provider.dart`             |
| Settings       | `settingsProvider`       | `lib/features/settings/providers/settings_provider.dart`             |
| Media          | `mediaProvider`          | `lib/features/media/providers/media_provider.dart`                   |
| Materials      | `materialsProvider`      | `lib/features/media/providers/materials_provider.dart`               |
| Bookmarks      | `bookmarksProvider`      | `lib/features/bookmarks/providers/bookmarks_provider.dart`           |
| Notifications  | `notificationsProvider`  | `lib/features/notifications/providers/notifications_provider.dart`   |
| Administration | `administrationProvider` | `lib/features/administration/providers/administration_provider.dart` |

---

## 🎯 When to Use What

### ref.watch() - For UI Updates

Use when the widget should rebuild when state changes.

```dart
Widget build(BuildContext context, WidgetRef ref) {
  final state = ref.watch(myProvider); // Rebuilds on change
  return Text(state.value);
}
```

### ref.read() - For One-Time Reads

Use in callbacks, event handlers, or methods (NOT in build method).

```dart
onPressed: () {
  ref.read(myProvider.notifier).increment(); // One-time call
}
```

### ref.listen() - For Side Effects

Use for navigation, showing snackbars, etc.

```dart
@override
void initState() {
  super.initState();
  ref.listen(myProvider, (previous, next) {
    if (next.hasError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(next.error!)),
      );
    }
  });
}
```

---

## 🔄 Provider Access Patterns

### Inside Widget

```dart
// Watch (rebuilds on change)
final state = ref.watch(myProvider);

// Read (one-time access)
ref.read(myProvider.notifier).method();

// Listen (side effects)
ref.listen(myProvider, (prev, next) { });
```

### Inside Provider

```dart
class MyNotifier extends StateNotifier<MyState> {
  MyNotifier(this._ref) : super(MyState());

  final Ref _ref;

  void doSomething() {
    // Access another provider
    final otherProvider = _ref.read(anotherProvider);
  }
}
```

---

## 🏗️ Provider State Structure

Most providers follow this pattern:

```dart
// State class
class MyState {
  final List<Item> items;
  final bool isLoading;
  final String? error;

  const MyState({
    this.items = const [],
    this.isLoading = false,
    this.error,
  });

  MyState copyWith({...}) => MyState(...);
}

// Provider declaration
final myProvider = StateNotifierProvider<MyNotifier, MyState>(
  (ref) => MyNotifier(ref),
);

// Notifier class
class MyNotifier extends StateNotifier<MyState> {
  MyNotifier(this._ref) : super(const MyState());

  final Ref _ref;

  Future<void> fetchData() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final data = await _repo.fetchData();
      state = state.copyWith(items: data, isLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }
}
```

---

## ⚠️ Common Mistakes

### ❌ DON'T: Use ref.watch in callbacks

```dart
// WRONG
onPressed: () {
  final state = ref.watch(myProvider); // Will cause issues
}
```

### ✅ DO: Use ref.read in callbacks

```dart
// CORRECT
onPressed: () {
  ref.read(myProvider.notifier).doSomething();
}
```

### ❌ DON'T: Store ref in a variable

```dart
// WRONG
final myRef = ref;
Future.delayed(..., () => myRef.read(...)); // Might be disposed
```

### ✅ DO: Use ref directly

```dart
// CORRECT
Future.delayed(..., () => ref.read(...));
```

---

## 🧪 Testing Tips

### Test with ProviderScope

```dart
testWidgets('my test', (tester) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        myProvider.overrideWith((ref) => MockMyNotifier()),
      ],
      child: MyApp(),
    ),
  );
});
```

---

## 📝 Migration Checklist (Per File)

- [ ] Replace `import 'package:provider/provider.dart'`
- [ ] Replace `import 'package:pivot/providers/old.dart'`
- [ ] Add `import 'package:flutter_riverpod/flutter_riverpod.dart'`
- [ ] Add `import 'package:pivot/features/*/providers/new.dart'`
- [ ] Change `StatelessWidget` → `ConsumerWidget`
- [ ] OR change `StatefulWidget` → `ConsumerStatefulWidget`
- [ ] Add `WidgetRef ref` parameter to `build()`
- [ ] Replace `Provider.of<X>(context)` → `ref.watch(xProvider)`
- [ ] Replace `Provider.of<X>(context, listen: false)` → `ref.read(xProvider.notifier)`
- [ ] Replace `context.read<X>()` → `ref.read(xProvider.notifier)`
- [ ] Test the screen thoroughly
- [ ] Commit changes

---

## 🔗 Helpful Links

- [Riverpod Docs](https://riverpod.dev/)
- [Provider vs Riverpod](https://riverpod.dev/docs/from_provider/motivation)
- [Riverpod Examples](https://github.com/rrousselGit/riverpod/tree/master/examples)

---

**Quick Tip**: Keep this file open while migrating for quick reference! 📖
