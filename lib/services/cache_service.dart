import 'package:hive_flutter/hive_flutter.dart';
import 'package:pivot/models/user_profile.dart';
import 'package:pivot/models/section_model.dart';
import 'package:pivot/screens/models/schedule_item.dart';
import 'package:pivot/features/home/screens/adminstration/models/announcement_data.dart';
import 'package:pivot/models/subject_model.dart';

class CacheService {
  // Singleton instance
  CacheService._privateConstructor();
  static final CacheService instance = CacheService._privateConstructor();

  // Hive box names
  static const String _usersBoxName = 'usersBox';
  static const String _sectionsBoxName = 'sectionsBox';
  static const String _subjectsBoxName = 'subjectsBox';
  static const String _scheduleBoxName = 'scheduleBox';
  static const String _announcementsBoxName = 'announcementsBox';
  static const String _cacheMetadataBoxName = 'cacheMetadataBox';
  static const String _materialsBoxName = 'materialsBox'; // For material links

  bool _initialized = false;

  // Cache expiry times (in minutes)
  static const int _usersCacheExpiry = 30; // 30 minutes
  static const int _sectionsCacheExpiry = 60; // 1 hour
  static const int _subjectsCacheExpiry = 120; // 2 hours
  static const int _scheduleCacheExpiry = 15; // 15 minutes
  static const int _announcementsCacheExpiry = 10; // 10 minutes
  static const int _materialsCacheExpiry = 30; // 30 minutes

  Future<void> init() async {
    if (_initialized) {
      return;
    }

    try {
      // Check if Hive is already initialized
      if (!Hive.isAdapterRegistered(0)) {
        await Hive.initFlutter(); // Works for both web and mobile
      }

      // Register adapters with error handling
      await _registerAdapters();

      // Open boxes with error handling
      await _openBoxes();

      _initialized = true;
    } catch (e) {
      print('CacheService initialization error: $e');
      // Don't rethrow - allow app to continue without cache
      _initialized = false;
    }
  }

  Future<void> _registerAdapters() async {
    try {
      if (!Hive.isAdapterRegistered(SocialMediaLinkAdapter().typeId)) {
        Hive.registerAdapter(SocialMediaLinkAdapter());
      }
      if (!Hive.isAdapterRegistered(NotificationPreferencesAdapter().typeId)) {
        Hive.registerAdapter(NotificationPreferencesAdapter());
      }
      if (!Hive.isAdapterRegistered(UserProfileAdapter().typeId)) {
        Hive.registerAdapter(UserProfileAdapter());
      }
      if (!Hive.isAdapterRegistered(SectionAdapter().typeId)) {
        Hive.registerAdapter(SectionAdapter());
      }
      if (!Hive.isAdapterRegistered(SubjectAdapter().typeId)) {
        Hive.registerAdapter(SubjectAdapter());
      }
      if (!Hive.isAdapterRegistered(ScheduleItemTypeCustomAdapter().typeId)) {
        Hive.registerAdapter(ScheduleItemTypeCustomAdapter());
      }
      if (!Hive.isAdapterRegistered(ScheduleItemCustomAdapter().typeId)) {
        Hive.registerAdapter(ScheduleItemCustomAdapter());
      }
      if (!Hive.isAdapterRegistered(AnnouncementDataAdapter().typeId)) {
        Hive.registerAdapter(AnnouncementDataAdapter());
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> _openBoxes() async {
    try {
      // Only open boxes if they're not already open
      if (!Hive.isBoxOpen(_usersBoxName)) {
        await Hive.openBox<UserProfile>(_usersBoxName);
      }
      if (!Hive.isBoxOpen(_sectionsBoxName)) {
        await Hive.openBox<Section>(_sectionsBoxName);
      }
      if (!Hive.isBoxOpen(_subjectsBoxName)) {
        await Hive.openBox<Subject>(_subjectsBoxName);
      }
      if (!Hive.isBoxOpen(_scheduleBoxName)) {
        await Hive.openBox<ScheduleItem>(_scheduleBoxName);
      }
      if (!Hive.isBoxOpen(_announcementsBoxName)) {
        await Hive.openBox<AnnouncementData>(_announcementsBoxName);
      }
      if (!Hive.isBoxOpen(_cacheMetadataBoxName)) {
        await Hive.openBox<Map>(_cacheMetadataBoxName);
      }
      if (!Hive.isBoxOpen(_materialsBoxName)) {
        await Hive.openBox(_materialsBoxName); // Dynamic box for JSON storage
      }
    } catch (e) {
      rethrow;
    }
  }

  // User Caching
  Future<void> cacheUsers(List<UserProfile> users) async {
    final box = Hive.box<UserProfile>(_usersBoxName);
    await box.clear();
    for (var user in users) {
      await box.put(user.id, user);
    }
  }

  List<UserProfile> getCachedUsers() {
    final box = Hive.box<UserProfile>(_usersBoxName);
    return box.values.toList();
  }

  /// Cache single user profile (for logged-in user)
  Future<void> cacheUserProfile(UserProfile profile) async {
    final box = Hive.box<UserProfile>(_usersBoxName);
    await box.put(profile.id, profile);
    await _updateCacheTimestamp(_usersBoxName, DateTime.now());
    print('💾 Cached user profile: ${profile.name}');
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

  // Section Caching
  Future<void> cacheSections(List<Section> sections) async {
    final box = Hive.box<Section>(_sectionsBoxName);
    await box.clear();
    for (var section in sections) {
      await box.put(section.id, section);
    }
  }

  List<Section> getCachedSections() {
    final box = Hive.box<Section>(_sectionsBoxName);
    return box.values.toList();
  }

  Future<void> clearSectionsCache() async {
    final box = Hive.box<Section>(_sectionsBoxName);
    await box.clear();
  }

  // Subject Caching
  Future<void> cacheSubjects(List<Subject> subjects) async {
    final box = Hive.box<Subject>(_subjectsBoxName);
    await box.clear();
    for (var subject in subjects) {
      await box.put(subject.id, subject);
    }
  }

  List<Subject> getCachedSubjects() {
    final box = Hive.box<Subject>(_subjectsBoxName);
    final subjects = box.values.toList();
    return subjects;
  }

  // Schedule Caching
  Future<void> cacheSchedule(List<ScheduleItem> schedule) async {
    final box = Hive.box<ScheduleItem>(_scheduleBoxName);
    await box.clear();
    for (var item in schedule) {
      await box.put(item.id, item);
    }
  }

  List<ScheduleItem> getCachedSchedule() {
    final box = Hive.box<ScheduleItem>(_scheduleBoxName);
    return box.values.toList();
  }

  // Announcement Caching
  Future<void> cacheAnnouncements(List<AnnouncementData> announcements) async {
    final box = Hive.box<AnnouncementData>(_announcementsBoxName);
    await box.clear();
    for (var ann in announcements) {
      final key =
          (ann.id?.isNotEmpty == true)
              ? ann.id!
              : (ann.title.isNotEmpty
                  ? ann.title
                  : DateTime.now().millisecondsSinceEpoch.toString());
      await box.put(key, ann);
    }
  }

  List<AnnouncementData> getCachedAnnouncements() {
    final box = Hive.box<AnnouncementData>(_announcementsBoxName);
    return box.values.toList();
  }

  // Clear announcements cache to resolve null safety issues
  Future<void> clearAnnouncementsCache() async {
    final box = Hive.box<AnnouncementData>(_announcementsBoxName);
    await box.clear();
    await _updateCacheTimestamp(_announcementsBoxName, null);
  }

  // Category-specific announcement caching
  Future<void> cacheAnnouncementsByCategory(
    String categoryKey,
    List<AnnouncementData> announcements,
  ) async {
    final box = Hive.box<AnnouncementData>(_announcementsBoxName);

    // Clear existing announcements for this category first
    final keysToRemove =
        box.keys
            .where((key) => key.toString().startsWith('${categoryKey}_'))
            .toList();

    for (var key in keysToRemove) {
      await box.delete(key);
    }

    // Store announcements with category prefix
    // IMPORTANT: HiveObject instances can only be stored with ONE key
    // We need to remove the object from any previous key before storing with new key
    for (var ann in announcements) {
      final newKey =
          '${categoryKey}_${ann.id ?? ann.title.hashCode.toString()}';

      try {
        // Check if this HiveObject is already in the box
        if (ann.isInBox) {
          // Remove from previous key first
          final oldKey = ann.key;
          if (oldKey != null && oldKey != newKey) {
            await box.delete(oldKey);
            print('🗑️ Removed announcement from old key: $oldKey');
          }
        }

        // Now store with new key
        await box.put(newKey, ann);
      } catch (e) {
        if (e.toString().contains('cannot be stored with two different keys')) {
          print(
            '⚠️ HiveObject duplicate key error for announcement: ${ann.id}',
          );
          print('   Attempting to fix by removing old entry...');

          // Find and remove the old entry
          final oldKey = ann.key;
          if (oldKey != null) {
            try {
              await box.delete(oldKey);
              // Try storing again
              await box.put(newKey, ann);
              print('✅ Fixed duplicate key error');
            } catch (e2) {
              print('❌ Could not fix duplicate key error: $e2');
              // Skip this announcement
              continue;
            }
          }
        } else {
          print('❌ Error caching announcement: $e');
          rethrow;
        }
      }
    }

    // Store category metadata
    await _updateCacheTimestamp('${categoryKey}_metadata', DateTime.now());
    print(
      '✅ Cached ${announcements.length} announcements for category: $categoryKey',
    );
  }

  List<AnnouncementData> getCachedAnnouncementsByCategory(String categoryKey) {
    final box = Hive.box<AnnouncementData>(_announcementsBoxName);
    final announcements = <AnnouncementData>[];

    for (var key in box.keys) {
      if (key.toString().startsWith('${categoryKey}_')) {
        final ann = box.get(key);
        if (ann != null && !announcements.any((a) => a.id == ann.id)) {
          announcements.add(ann);
        }
      }
    }

    return announcements;
  }

  bool isCategoryCacheValid(String categoryKey) {
    return isCacheValid('${categoryKey}_metadata');
  }

  // ===== SMART CACHING METHODS =====

  /// Check if cache is valid based on expiry time
  bool isCacheValid(String cacheType, {int? customExpiryMinutes}) {
    try {
      final metadataBox = Hive.box<Map>(_cacheMetadataBoxName);
      final timestampData = metadataBox.get('${cacheType}_timestamp');

      if (timestampData == null) return false;

      final timestamp = timestampData['timestamp'];
      if (timestamp is! DateTime) return false;

      final expiryMinutes = customExpiryMinutes ?? _getCacheExpiry(cacheType);
      final expiryTime = timestamp.add(Duration(minutes: expiryMinutes));

      return DateTime.now().isBefore(expiryTime);
    } catch (e) {
      print('❌ Error checking cache validity: $e');
      return false;
    }
  }

  /// Get cache expiry time for different data types
  int _getCacheExpiry(String cacheType) {
    switch (cacheType) {
      case _usersBoxName:
        return _usersCacheExpiry;
      case _sectionsBoxName:
        return _sectionsCacheExpiry;
      case _subjectsBoxName:
        return _subjectsCacheExpiry;
      case _scheduleBoxName:
        return _scheduleCacheExpiry;
      case _announcementsBoxName:
        return _announcementsCacheExpiry;
      default:
        return 30; // Default 30 minutes
    }
  }

  /// Update cache timestamp
  Future<void> _updateCacheTimestamp(
    String cacheType,
    DateTime? timestamp,
  ) async {
    try {
      final metadataBox = Hive.box<Map>(_cacheMetadataBoxName);
      if (timestamp == null) {
        // Clear the timestamp (mark as invalid)
        await metadataBox.delete('${cacheType}_timestamp');
      } else {
        await metadataBox.put('${cacheType}_timestamp', {
          'timestamp': timestamp,
        });
      }
    } catch (e) {
      print('❌ Error updating cache timestamp: $e');
    }
  }

  /// Smart cache retrieval - returns cached data if valid, null if expired
  T? getSmartCache<T>(String cacheType, T Function() getCachedData) {
    if (isCacheValid(cacheType)) {
      return getCachedData();
    }
    return null;
  }

  /// Smart cache storage - stores data with timestamp
  Future<void> setSmartCache<T>(
    String cacheType,
    T data,
    Future<void> Function(T) cacheFunction,
  ) async {
    await cacheFunction(data);
    await _updateCacheTimestamp(cacheType, DateTime.now());
  }

  /// Force refresh cache (bypasses expiry check)
  Future<void> forceRefreshCache(String cacheType) async {
    await _updateCacheTimestamp(cacheType, null);
  }

  /// Get cache statistics
  Map<String, dynamic> getCacheStats() {
    final metadataBox = Hive.box<Map>(_cacheMetadataBoxName);
    final stats = <String, dynamic>{};

    final cacheTypes = [
      _usersBoxName,
      _sectionsBoxName,
      _subjectsBoxName,
      _scheduleBoxName,
      _announcementsBoxName,
    ];

    for (final cacheType in cacheTypes) {
      final timestampData = metadataBox.get('${cacheType}_timestamp');
      final timestamp =
          timestampData is Map ? timestampData['timestamp'] : null;
      final isValid = isCacheValid(cacheType);
      final age =
          timestamp != null
              ? DateTime.now().difference(timestamp).inMinutes
              : null;

      stats[cacheType] = {
        'isValid': isValid,
        'lastUpdated': timestamp?.toIso8601String(),
        'ageMinutes': age,
        'expiryMinutes': _getCacheExpiry(cacheType),
      };
    }

    return stats;
  }

  /// Clear all caches
  Future<void> clearAllCaches() async {
    await Hive.box<UserProfile>(_usersBoxName).clear();
    await Hive.box<Section>(_sectionsBoxName).clear();
    await Hive.box<Subject>(_subjectsBoxName).clear();
    await Hive.box<ScheduleItem>(_scheduleBoxName).clear();
    await Hive.box<AnnouncementData>(_announcementsBoxName).clear();
    await Hive.box<Map>(_cacheMetadataBoxName).clear();
  }

  /// Clear all cache (alias for clearAllCaches)
  Future<void> clearAllCache() async {
    await clearAllCaches();
  }

  /// Clear specific user profile from cache
  Future<void> clearUserProfile(String userId) async {
    final box = Hive.box<UserProfile>(_usersBoxName);
    await box.delete(userId);
  }

  /// Clear all cached data for a specific user (called during logout)
  Future<void> clearUserCache(String? userId) async {
    print('🗑️ Clearing user cache...');
    try {
      // Clear user profile if userId is provided
      if (userId != null) {
        await clearUserProfile(userId);
        print('   ✅ User profile cleared');
      }

      // Clear schedule cache (user-specific)
      if (Hive.isBoxOpen(_scheduleBoxName)) {
        await Hive.box<ScheduleItem>(_scheduleBoxName).clear();
        print('   ✅ Schedule cache cleared');
      }

      // Clear materials cache (user-specific)
      if (Hive.isBoxOpen(_materialsBoxName)) {
        await Hive.box(_materialsBoxName).clear();
        print('   ✅ Materials cache cleared');
      }

      // Optionally clear other caches depending on your app's needs
      // (Sections and subjects might be shared across users, so maybe keep them)

      print('✅ User cache cleared successfully');
    } catch (e) {
      print('❌ Error clearing user cache: $e');
      // Don't rethrow - allow logout to continue
    }
  }

  // ===== Materials Caching =====

  /// Cache materials for a specific lecture or assistant-subject combination
  /// Key format: "lecture_{lectureId}" or "assistant_{subjectId}_{assistantId}"
  Future<void> cacheMaterials(
    String key,
    List<Map<String, dynamic>> materials,
  ) async {
    try {
      // Ensure box is open
      if (!Hive.isBoxOpen(_materialsBoxName)) {
        await Hive.openBox(_materialsBoxName);
        print('📦 Opened materials box');
      }

      final box = Hive.box(_materialsBoxName);
      await box.put(key, materials);
      await _updateCacheTimestamp('$_materialsBoxName:$key', DateTime.now());
      print('💾 Cached ${materials.length} materials for key: $key');
    } catch (e) {
      print('❌ Error caching materials: $e');
    }
  }

  /// Get cached materials by key
  List<Map<String, dynamic>> getCachedMaterials(String key) {
    try {
      // Check if box is open
      if (!Hive.isBoxOpen(_materialsBoxName)) {
        print('⚠️ Materials box not open, returning empty');
        return [];
      }

      final box = Hive.box(_materialsBoxName);
      final cached = box.get(key);

      if (cached == null) {
        return [];
      }

      // Check if cache is expired using existing method
      if (!isCacheValid(
        '$_materialsBoxName:$key',
        customExpiryMinutes: _materialsCacheExpiry,
      )) {
        print('⏰ Materials cache expired for key: $key');
        return [];
      }

      return List<Map<String, dynamic>>.from(cached);
    } catch (e) {
      print('❌ Error getting cached materials: $e');
      return [];
    }
  }

  /// Clear materials cache for specific key
  Future<void> clearMaterialsCache(String key) async {
    try {
      if (!Hive.isBoxOpen(_materialsBoxName)) {
        print('⚠️ Materials box not open');
        return;
      }

      final box = Hive.box(_materialsBoxName);
      await box.delete(key);
      print('🗑️ Cleared materials cache for key: $key');
    } catch (e) {
      print('❌ Error clearing materials cache: $e');
    }
  }

  /// Clear all materials cache
  Future<void> clearAllMaterialsCache() async {
    try {
      if (!Hive.isBoxOpen(_materialsBoxName)) {
        print('⚠️ Materials box not open');
        return;
      }

      final box = Hive.box(_materialsBoxName);
      await box.clear();
      print('🗑️ Cleared all materials cache');
    } catch (e) {
      print('❌ Error clearing all materials cache: $e');
    }
  }

  Future<void> close() async {
    await Hive.close();
  }
}
