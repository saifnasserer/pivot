import 'package:hive_flutter/hive_flutter.dart';
import 'package:pivot/models/user_profile.dart';
import 'package:pivot/models/section_model.dart';
import 'package:pivot/screens/models/schedule_item.dart';
import 'package:pivot/screens/section2/adminstration/models/announcement_data.dart';
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

  bool _initialized = false;

  // Cache expiry times (in minutes)
  static const int _usersCacheExpiry = 30; // 30 minutes
  static const int _sectionsCacheExpiry = 60; // 1 hour
  static const int _subjectsCacheExpiry = 120; // 2 hours
  static const int _scheduleCacheExpiry = 15; // 15 minutes
  static const int _announcementsCacheExpiry = 10; // 10 minutes

  Future<void> init() async {
    if (_initialized) {
      return;
    }

    _initialized = true;

    try {
      await Hive.initFlutter(); // Works for both web and mobile

      // Register adapters with error handling
      await _registerAdapters();

      // Open boxes with error handling
      await _openBoxes();
    } catch (e) {
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
      await Hive.openBox<UserProfile>(_usersBoxName);
      await Hive.openBox<Section>(_sectionsBoxName);
      await Hive.openBox<Subject>(_subjectsBoxName);
      await Hive.openBox<ScheduleItem>(_scheduleBoxName);
      await Hive.openBox<AnnouncementData>(_announcementsBoxName);
      await Hive.openBox<Map>(_cacheMetadataBoxName);
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
          ann.id ??
          ann.title ??
          DateTime.now().millisecondsSinceEpoch.toString();
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

  // ===== SMART CACHING METHODS =====

  /// Check if cache is valid based on expiry time
  bool isCacheValid(String cacheType, {int? customExpiryMinutes}) {
    final metadataBox = Hive.box<Map>(_cacheMetadataBoxName);
    final timestampData = metadataBox.get('${cacheType}_timestamp');
    final timestamp = timestampData is Map ? timestampData['timestamp'] : null;

    if (timestamp == null) return false;

    final expiryMinutes = customExpiryMinutes ?? _getCacheExpiry(cacheType);
    final expiryTime = timestamp.add(Duration(minutes: expiryMinutes));

    return DateTime.now().isBefore(expiryTime);
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
    final metadataBox = Hive.box<Map>(_cacheMetadataBoxName);
    await metadataBox.put('${cacheType}_timestamp', {
      'timestamp': timestamp ?? DateTime.now(),
    });
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

  Future<void> close() async {
    await Hive.close();
  }
}
