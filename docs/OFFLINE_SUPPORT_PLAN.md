# Offline Support Implementation Plan

## Current Issues Identified

### 1. **Login & Authentication Issues**

- ❌ App doesn't allow login without internet connection
- ❌ No persistent session storage for offline access
- ❌ Firebase Auth requires network for initial login
- ❌ Auth state is not persisted locally for offline re-authentication

### 2. **Profile Tab Issues**

- ❌ Shows Firebase connection errors instead of cached data
- ❌ No graceful error handling for offline state
- ❌ Doesn't fall back to cached profile when offline
- ❌ Loading states don't distinguish between "no internet" and "loading"

### 3. **Cache System Issues**

- ✅ Hive service exists and caches data
- ❌ Cache is not prioritized when offline
- ❌ No connectivity detection before Firebase calls
- ❌ Providers don't check offline state before network requests

### 4. **General System Issues**

- ❌ No centralized offline state management
- ❌ No connectivity monitoring service
- ❌ Error messages blame Firebase instead of showing offline state
- ❌ No offline indicator in UI
- ❌ No queue system for offline operations

---

## Comprehensive Offline Support Strategy

### **Phase 1: Core Infrastructure**

#### 1.1 Create Offline Service

**File:** `lib/services/offline_service.dart`

```dart
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class OfflineService {
  static final OfflineService _instance = OfflineService._internal();
  factory OfflineService() => _instance;
  OfflineService._internal();

    final Connectivity _connectivity = Connectivity();
    ValueNotifier<bool> isOnline = ValueNotifier<bool>(true);
    ValueNotifier<ConnectivityResult> connectivityStatus =
        ValueNotifier<ConnectivityResult>(ConnectivityResult.none);

  Future<void> initialize() async {
    // Check initial connectivity
    final result = await _connectivity.checkConnectivity();
    connectivityStatus.value = result;
    isOnline.value = result != ConnectivityResult.none;

    // Listen for connectivity changes
    _connectivity.onConnectivityChanged.listen((ConnectivityResult result) {
      connectivityStatus.value = result;
      isOnline.value = result != ConnectivityResult.none;
    });
  }

  bool get hasConnection => isOnline.value;
}

// Riverpod provider
final offlineServiceProvider = Provider<OfflineService>((ref) {
  return OfflineService();
});

final isOnlineProvider = StreamProvider<bool>((ref) {
  final service = ref.watch(offlineServiceProvider);
  return Stream.value(service.hasConnection);
});
```

#### 1.2 Create Session Persistence Service

**File:** `lib/services/session_persistence_service.dart`

```dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';

class SessionPersistenceService {
  static final SessionPersistenceService _instance =
      SessionPersistenceService._internal();
  factory SessionPersistenceService() => _instance;
  SessionPersistenceService._internal();

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  // Keys
  static const String _userIdKey = 'cached_user_id';
  static const String _userEmailKey = 'cached_user_email';
  static const String _authTokenKey = 'cached_auth_token';
  static const String _lastLoginKey = 'last_login_timestamp';
  static const String _offlineAuthEnabledKey = 'offline_auth_enabled';

  /// Save user session for offline access
  Future<void> saveUserSession(User user) async {
    try {
      final token = await user.getIdToken();
      await _secureStorage.write(key: _userIdKey, value: user.uid);
      await _secureStorage.write(key: _userEmailKey, value: user.email);
      await _secureStorage.write(key: _authTokenKey, value: token);
      await _secureStorage.write(
        key: _lastLoginKey,
        value: DateTime.now().toIso8601String(),
      );
      await _secureStorage.write(key: _offlineAuthEnabledKey, value: 'true');
    } catch (e) {
      print('Error saving session: $e');
    }
  }

  /// Check if there's a valid cached session
  Future<bool> hasCachedSession() async {
    try {
      final userId = await _secureStorage.read(key: _userIdKey);
      final offlineEnabled = await _secureStorage.read(
        key: _offlineAuthEnabledKey,
      );
      return userId != null && offlineEnabled == 'true';
    } catch (e) {
      return false;
    }
  }

  /// Get cached user ID for offline access
  Future<String?> getCachedUserId() async {
    return await _secureStorage.read(key: _userIdKey);
  }

  /// Get cached user email
  Future<String?> getCachedUserEmail() async {
    return await _secureStorage.read(key: _userEmailKey);
  }

  /// Clear session (logout)
  Future<void> clearSession() async {
    await _secureStorage.deleteAll();
  }

  /// Check if session is expired (older than 30 days)
  Future<bool> isSessionExpired() async {
    try {
      final lastLoginStr = await _secureStorage.read(key: _lastLoginKey);
      if (lastLoginStr == null) return true;

      final lastLogin = DateTime.parse(lastLoginStr);
      final daysSinceLogin = DateTime.now().difference(lastLogin).inDays;
      return daysSinceLogin > 30;
    } catch (e) {
      return true;
    }
  }
}
```

---

### **Phase 2: Authentication Enhancement**

#### 2.1 Update AuthService for Offline Support

**File:** `lib/services/auth_service.dart` (modifications)

Add offline login capability:

```dart
// Add to AuthService class
Future<UserProfile?> offlineLogin(String cachedUserId) async {
  try {
    // Try to get cached profile from Hive
    final cachedUsers = CacheService.instance.getCachedUsers();
    final cachedProfile = cachedUsers.firstWhere(
      (user) => user.id == cachedUserId,
      orElse: () => null,
    );

    if (cachedProfile != null) {
      print('✅ Offline login successful with cached profile');
      return cachedProfile;
    }

    return null;
  } catch (e) {
    print('❌ Offline login failed: $e');
    return null;
  }
}

// Modify signInWithEmailAndPassword
Future<UserProfile?> signInWithEmailAndPassword(
  String email,
  String password,
) async {
  try {
    // Check connectivity first
    final isOnline = OfflineService().hasConnection;

    if (!isOnline) {
      // Attempt offline login with cached credentials
      final cachedUserId = await SessionPersistenceService().getCachedUserId();
      if (cachedUserId != null) {
        return await offlineLogin(cachedUserId);
      }
      throw FirebaseAuthException(
        code: 'network-request-failed',
        message: 'لا يوجد اتصال بالإنترنت. يرجى المحاولة لاحقاً',
      );
    }

    // Online login flow (existing code)
    UserCredential result = await _firebaseAuth.signInWithEmailAndPassword(
      email: email.trim().toLowerCase(),
      password: password,
    );

    User? user = result.user;

    if (user != null) {
      // Save session for offline access
      await SessionPersistenceService().saveUserSession(user);

      final profile = await getUserProfile(user.uid);

      // Cache the profile
      if (profile != null) {
        await CacheService.instance.cacheUsers([profile]);
      }

      return profile;
    }
    return null;
  } catch (e) {
    rethrow;
  }
}
```

#### 2.2 Update AuthWrapper for Offline Support

**File:** `lib/features/onboarding/screens/auth_wrapper.dart` (modifications)

```dart
Future<void> _checkActiveSession() async {
  // Check for offline cached session first
  final hasCachedSession = await SessionPersistenceService().hasCachedSession();
  final isOnline = OfflineService().hasConnection;

  if (!isOnline && hasCachedSession) {
    // Offline mode with cached session
    final cachedUserId = await SessionPersistenceService().getCachedUserId();
    if (cachedUserId != null) {
      await _loadOfflineProfile(cachedUserId);
      return;
    }
  }

  // Check if there's an active Firebase session (online mode)
  final currentUser = FirebaseAuth.instance.currentUser;
  if (currentUser != null) {
    try {
      await currentUser.reload();
      await _loadProfileAndNavigate(currentUser);
    } catch (e) {
      // Handle offline or expired token
      if (!isOnline && hasCachedSession) {
        final cachedUserId = await SessionPersistenceService().getCachedUserId();
        if (cachedUserId != null) {
          await _loadOfflineProfile(cachedUserId);
        }
      } else {
        await FirebaseAuth.instance.signOut();
        ref.read(userProfileProvider.notifier).clearLoggedInUserProfile();
      }
    }
  }
}

Future<void> _loadOfflineProfile(String userId) async {
  setState(() => _loadingProfile = true);

  try {
    final cachedUsers = CacheService.instance.getCachedUsers();
    final cachedProfile = cachedUsers.firstWhere(
      (user) => user.id == userId,
      orElse: () => null,
    );

    if (cachedProfile != null) {
      ref.read(userProfileProvider.notifier).setLoggedInUserProfile(
        cachedProfile,
        isOffline: true,
      );
    }
  } catch (e) {
    print('Error loading offline profile: $e');
  }

  setState(() => _loadingProfile = false);
}
```

---

### **Phase 3: Profile & Data Enhancement**

#### 3.1 Enhanced CacheService for User Profile

**File:** `lib/services/cache_service.dart` (additions)

```dart
// Add to CacheService class

/// Cache single user profile (for logged-in user)
Future<void> cacheUserProfile(UserProfile profile) async {
  final box = Hive.box<UserProfile>(_usersBoxName);
  await box.put(profile.id, profile);
  await _updateCacheTimestamp(_usersBoxName, DateTime.now());
}

/// Get cached user profile by ID
UserProfile? getCachedUserProfile(String userId) {
  final box = Hive.box<UserProfile>(_usersBoxName);
  return box.get(userId);
}

/// Check if specific user profile is cached
bool hasUserProfileCache(String userId) {
  final box = Hive.box<UserProfile>(_usersBoxName);
  return box.containsKey(userId);
}
```

#### 3.2 Update UserProfileProvider for Offline Support

**File:** `lib/features/user/providers/user_profile_provider.dart` (modifications)

```dart
class UserProfileNotifier extends StateNotifier<UserProfileState> {
  // ... existing code

  Future<void> loadLoggedInUserProfile() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final isOnline = OfflineService().hasConnection;

      if (!isOnline) {
        // Load from cache
        final cachedUserId = await SessionPersistenceService().getCachedUserId();
        if (cachedUserId != null) {
          final cachedProfile = CacheService.instance.getCachedUserProfile(
            cachedUserId,
          );
          if (cachedProfile != null) {
            state = state.copyWith(
              isLoading: false,
              loggedInUserProfile: cachedProfile,
              isOffline: true,
            );
            return;
          }
        }

        // No cached profile available
        state = state.copyWith(
          isLoading: false,
          error: 'لا يوجد اتصال بالإنترنت ولا توجد بيانات محفوظة',
        );
        return;
      }

      // Online mode - fetch from Firebase
      final profile = await _repo.getLoggedInUserProfile();

      // Cache the profile for offline use
      if (profile != null) {
        await CacheService.instance.cacheUserProfile(profile);
      }

      state = state.copyWith(
        isLoading: false,
        loggedInUserProfile: profile,
        isOffline: false,
      );
    } catch (e) {
      // On error, try to load from cache
      final cachedUserId = await SessionPersistenceService().getCachedUserId();
      if (cachedUserId != null) {
        final cachedProfile = CacheService.instance.getCachedUserProfile(
          cachedUserId,
        );
        if (cachedProfile != null) {
          state = state.copyWith(
            isLoading: false,
            loggedInUserProfile: cachedProfile,
            isOffline: true,
            error: 'تم تحميل البيانات المحفوظة (وضع غير متصل)',
          );
          return;
        }
      }

      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void setLoggedInUserProfile(UserProfile profile, {bool isOffline = false}) {
    state = state.copyWith(
      loggedInUserProfile: profile,
      isOffline: isOffline,
    );
  }
}

// Update UserProfileState to include offline flag
class UserProfileState {
  final UserProfile? userProfile;
  final UserProfile? loggedInUserProfile;
  final List<UserProfile> allUsers;
  final bool isLoading;
  final bool isAuthenticating;
  final bool isOffline; // NEW
  final String? error;
  final Map<String, UserProfile> userProfilesCache;

  const UserProfileState({
    this.userProfile,
    this.loggedInUserProfile,
    this.allUsers = const [],
    this.isLoading = false,
    this.isAuthenticating = false,
    this.isOffline = false, // NEW
    this.error,
    this.userProfilesCache = const {},
  });

  UserProfileState copyWith({
    UserProfile? userProfile,
    UserProfile? loggedInUserProfile,
    List<UserProfile>? allUsers,
    bool? isLoading,
    bool? isAuthenticating,
    bool? isOffline, // NEW
    String? error,
    Map<String, UserProfile>? userProfilesCache,
  }) => UserProfileState(
    userProfile: userProfile ?? this.userProfile,
    loggedInUserProfile: loggedInUserProfile ?? this.loggedInUserProfile,
    allUsers: allUsers ?? this.allUsers,
    isLoading: isLoading ?? this.isLoading,
    isAuthenticating: isAuthenticating ?? this.isAuthenticating,
    isOffline: isOffline ?? this.isOffline, // NEW
    error: error ?? this.error,
    userProfilesCache: userProfilesCache ?? this.userProfilesCache,
  );
}
```

#### 3.3 Update ProfileDetailsTab with Offline Handling

**File:** `lib/features/profile/screens/profile/profile_details_tab.dart` (modifications)

```dart
@override
Widget build(BuildContext context) {
  final userProfileState = ref.watch(userProfileProvider);
  final userProfile = userProfileState.loggedInUserProfile;
  final isOffline = userProfileState.isOffline;

  if (userProfile == null) {
    return _buildLoadingState(userProfileState.error, isOffline);
  }

  return Container(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Colors.grey[50]!, Colors.white],
      ),
    ),
    child: Column(
      children: [
        // Offline indicator
        if (isOffline) _buildOfflineIndicator(),

        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.all(Responsive.space(context, size: Space.medium)),
            child: Column(
              children: [
                _buildProfileDetailsSection(userProfile),
                SizedBox(height: Responsive.space(context, size: Space.large)),
                _buildQuickActionsSection(userProfile),
                SizedBox(height: Responsive.space(context, size: Space.large)),
                _buildLogoutSection(),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

Widget _buildOfflineIndicator() {
  return Container(
    width: double.infinity,
    padding: EdgeInsets.symmetric(
      vertical: Responsive.space(context, size: Space.small),
      horizontal: Responsive.space(context, size: Space.medium),
    ),
    decoration: BoxDecoration(
      color: Colors.orange.withOpacity(0.1),
      border: Border(
        bottom: BorderSide(color: Colors.orange.withOpacity(0.3)),
      ),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.cloud_off, size: 16, color: Colors.orange.shade700),
        SizedBox(width: Responsive.space(context, size: Space.small)),
        Text(
          'وضع غير متصل - البيانات المحفوظة',
          style: TextStyle(
            color: Colors.orange.shade700,
            fontSize: Responsive.text(context, size: TextSize.small),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );
}

Widget _buildLoadingState(String? error, bool isOffline) {
  if (error != null) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isOffline ? Icons.cloud_off : Icons.error_outline,
            size: 64,
            color: isOffline ? Colors.orange : Colors.red,
          ),
          SizedBox(height: Responsive.space(context, size: Space.medium)),
          Text(
            isOffline
                ? 'لا يوجد اتصال بالإنترنت'
                : 'فشل في تحميل البيانات',
            style: TextStyle(
              fontSize: Responsive.text(context, size: TextSize.medium),
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: Responsive.space(context, size: Space.small)),
          Text(
            error,
            style: TextStyle(
              fontSize: Responsive.text(context, size: TextSize.small),
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          if (!isOffline) ...[
            SizedBox(height: Responsive.space(context, size: Space.medium)),
            ElevatedButton.icon(
              onPressed: () {
                ref.read(userProfileProvider.notifier).loadLoggedInUserProfile();
              },
              icon: Icon(Icons.refresh),
              label: Text('إعادة المحاولة'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ],
      ),
    );
  }

  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CircularProgressIndicator(color: Colors.black),
        SizedBox(height: Responsive.space(context, size: Space.medium)),
        Text(
          'جاري تحميل البيانات...',
          style: TextStyle(
            fontSize: Responsive.text(context, size: TextSize.medium),
            color: Colors.grey[600],
          ),
        ),
      ],
    ),
  );
}
```

---

### **Phase 4: Global Offline UI Indicators**

#### 4.1 Create Offline Banner Widget

**File:** `lib/widgets/offline_banner.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pivot/services/offline_service.dart';
import 'package:pivot/responsive.dart';

class OfflineBanner extends ConsumerWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOnline = ref.watch(isOnlineProvider).value ?? true;

    if (isOnline) {
      return const SizedBox.shrink();
    }

    return Material(
      elevation: 4,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(
          vertical: Responsive.space(context, size: Space.small),
          horizontal: Responsive.space(context, size: Space.medium),
        ),
        decoration: BoxDecoration(
          color: Colors.orange.shade600,
        ),
        child: SafeArea(
          bottom: false,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.cloud_off, size: 16, color: Colors.white),
              SizedBox(width: Responsive.space(context, size: Space.small)),
              Text(
                'لا يوجد اتصال بالإنترنت',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: Responsive.text(context, size: TextSize.small),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

#### 4.2 Add to Landing/Main Screen

**File:** `lib/features/home/screens/landing.dart` (modification)

```dart
@override
Widget build(BuildContext context) {
  return Scaffold(
    body: Column(
      children: [
        const OfflineBanner(), // Add this
        Expanded(
          child: // ... existing content
        ),
      ],
    ),
  );
}
```

---

### **Phase 5: Provider-Level Offline Handling**

#### 5.1 Create Base Provider Mixin for Offline Support

**File:** `lib/providers/offline_provider_mixin.dart`

```dart
import 'package:pivot/services/offline_service.dart';
import 'package:pivot/services/cache_service.dart';

mixin OfflineProviderMixin {
  /// Execute operation with offline fallback
  Future<T> executeWithOfflineFallback<T>({
    required Future<T> Function() onlineOperation,
    required T Function() offlineFallback,
    required String cacheKey,
  }) async {
    try {
      final isOnline = OfflineService().hasConnection;

      if (!isOnline) {
        print('📱 Offline mode: Using cached data for $cacheKey');
        return offlineFallback();
      }

      // Attempt online operation
      return await onlineOperation();
    } catch (e) {
      // On error, try offline fallback
      print('⚠️ Online operation failed, using offline fallback: $e');
      return offlineFallback();
    }
  }

  /// Check connectivity before operation
  Future<bool> checkConnectivity() async {
    return OfflineService().hasConnection;
  }
}
```

---

### **Phase 6: Offline Queue for Write Operations**

#### 6.1 Create Offline Operations Queue

**File:** `lib/services/offline_queue_service.dart`

```dart
import 'package:hive_flutter/hive_flutter.dart';
import 'dart:convert';

enum OperationType {
  createTask,
  updateTask,
  deleteTask,
  updateProfile,
  addNote,
  // Add more as needed
}

class QueuedOperation {
  final String id;
  final OperationType type;
  final Map<String, dynamic> data;
  final DateTime timestamp;
  final int retryCount;

  QueuedOperation({
    required this.id,
    required this.type,
    required this.data,
    required this.timestamp,
    this.retryCount = 0,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.toString(),
    'data': data,
    'timestamp': timestamp.toIso8601String(),
    'retryCount': retryCount,
  };

  factory QueuedOperation.fromJson(Map<String, dynamic> json) {
    return QueuedOperation(
      id: json['id'],
      type: OperationType.values.firstWhere(
        (e) => e.toString() == json['type'],
      ),
      data: json['data'],
      timestamp: DateTime.parse(json['timestamp']),
      retryCount: json['retryCount'] ?? 0,
    );
  }
}

class OfflineQueueService {
  static final OfflineQueueService _instance = OfflineQueueService._internal();
  factory OfflineQueueService() => _instance;
  OfflineQueueService._internal();

  static const String _queueBoxName = 'offlineQueueBox';

  Future<void> init() async {
    if (!Hive.isBoxOpen(_queueBoxName)) {
      await Hive.openBox(_queueBoxName);
    }
  }

  /// Add operation to queue
  Future<void> queueOperation(QueuedOperation operation) async {
    final box = Hive.box(_queueBoxName);
    await box.put(operation.id, jsonEncode(operation.toJson()));
    print('📝 Queued operation: ${operation.type}');
  }

  /// Get all queued operations
  List<QueuedOperation> getQueuedOperations() {
    final box = Hive.box(_queueBoxName);
    return box.values
        .map((e) => QueuedOperation.fromJson(jsonDecode(e)))
        .toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
  }

  /// Remove operation from queue
  Future<void> removeOperation(String operationId) async {
    final box = Hive.box(_queueBoxName);
    await box.delete(operationId);
  }

  /// Clear all queued operations
  Future<void> clearQueue() async {
    final box = Hive.box(_queueBoxName);
    await box.clear();
  }

  /// Get queue count
  int getQueueCount() {
    final box = Hive.box(_queueBoxName);
    return box.length;
  }

  /// Process queue when online
  Future<void> processQueue({
    required Future<void> Function(QueuedOperation) processor,
  }) async {
    final operations = getQueuedOperations();

    for (final operation in operations) {
      try {
        await processor(operation);
        await removeOperation(operation.id);
        print('✅ Processed queued operation: ${operation.type}');
      } catch (e) {
        print('❌ Failed to process operation: ${operation.type} - $e');
        // Optionally increment retry count or handle failures
      }
    }
  }
}
```

---

## Implementation Priority

### **🔴 Critical (Implement First)**

1. OfflineService with connectivity monitoring
2. SessionPersistenceService for offline login
3. Update AuthWrapper for offline session handling
4. Update AuthService for offline login fallback

### **🟠 High Priority**

5. Enhanced CacheService for user profile
6. Update UserProfileProvider for offline support
7. Update ProfileDetailsTab with offline UI
8. Add OfflineBanner widget to main screens

### **🟡 Medium Priority**

9. Implement OfflineProviderMixin for all providers
10. Update other providers (tasks, subjects, etc.) with offline support
11. Add offline indicators throughout the app

### **🟢 Low Priority (Future Enhancement)**

12. Implement OfflineQueueService
13. Add sync notification when back online
14. Implement conflict resolution for offline changes

---

## Testing Checklist

- [ ] Turn off internet → App should show cached data
- [ ] Login offline → Should work with cached credentials
- [ ] View profile offline → Should show cached profile
- [ ] View tasks offline → Should show cached tasks
- [ ] Create task offline → Should queue operation
- [ ] Turn on internet → Should sync queued operations
- [ ] Logout → Should clear cached credentials
- [ ] Error messages → Should be user-friendly, no Firebase errors

---

## Success Metrics

✅ **User can login offline with cached credentials**
✅ **Profile tab shows cached data instead of Firebase errors**
✅ **Offline indicator appears when no connection**
✅ **All read operations work offline with cached data**
✅ **Write operations are queued for later sync**
✅ **User-friendly error messages throughout**
✅ **Seamless transition between online/offline modes**

---

## Notes

- Firebase Auth still requires initial online login to establish credentials
- Offline mode works after first successful online login
- Cached data has 30-day expiry for security
- Queue operations sync automatically when connection is restored
- User can manually trigger sync from settings
