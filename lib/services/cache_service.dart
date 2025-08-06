import 'package:hive_flutter/hive_flutter.dart';
import 'package:pivot/models/user_profile.dart';
import 'package:pivot/models/section_model.dart';
import 'package:pivot/models/subject_model.dart';
import 'package:pivot/screens/models/schedule_item.dart';
import 'package:pivot/screens/section2/adminstration/models/announcement_data.dart';

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

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) {
      print('CacheService already initialized, skipping...');
      return;
    }

    _initialized = true;

    try {
      await Hive.initFlutter(); // Works for both web and mobile
      print('Hive initialized successfully');

      // Register adapters
      if (!Hive.isAdapterRegistered(SocialMediaLinkAdapter().typeId)) {
        Hive.registerAdapter(SocialMediaLinkAdapter());
        print('SocialMediaLinkAdapter registered');
      }
      if (!Hive.isAdapterRegistered(NotificationPreferencesAdapter().typeId)) {
        Hive.registerAdapter(NotificationPreferencesAdapter());
        print('NotificationPreferencesAdapter registered');
      }
      if (!Hive.isAdapterRegistered(UserProfileAdapter().typeId)) {
        Hive.registerAdapter(UserProfileAdapter());
        print('UserProfileAdapter registered');
      }
      if (!Hive.isAdapterRegistered(SectionAdapter().typeId)) {
        Hive.registerAdapter(SectionAdapter());
        print(
          'SectionAdapter registered with typeId: ${SectionAdapter().typeId}',
        );
      }
      if (!Hive.isAdapterRegistered(SubjectAdapter().typeId)) {
        Hive.registerAdapter(SubjectAdapter());
        print('SubjectAdapter registered');
      }
      if (!Hive.isAdapterRegistered(ScheduleItemTypeCustomAdapter().typeId)) {
        Hive.registerAdapter(ScheduleItemTypeCustomAdapter());
        print('ScheduleItemTypeCustomAdapter registered');
      }
      if (!Hive.isAdapterRegistered(ScheduleItemCustomAdapter().typeId)) {
        Hive.registerAdapter(ScheduleItemCustomAdapter());
        print('ScheduleItemCustomAdapter registered');
      }
      if (!Hive.isAdapterRegistered(AnnouncementDataAdapter().typeId)) {
        Hive.registerAdapter(AnnouncementDataAdapter());
        print('AnnouncementDataAdapter registered');
      }

      // Open boxes
      await Hive.openBox<UserProfile>(_usersBoxName);
      print('UserProfile box opened');
      await Hive.openBox<Section>(_sectionsBoxName);
      print('Section box opened');
      await Hive.openBox<Subject>(_subjectsBoxName);
      print('Subject box opened');
      await Hive.openBox<ScheduleItem>(_scheduleBoxName);
      print('ScheduleItem box opened');
      await Hive.openBox<AnnouncementData>(_announcementsBoxName);
      print('AnnouncementData box opened');
      print('All Hive boxes opened successfully');
    } catch (e, stackTrace) {
      print('Error initializing CacheService: $e');
      print('Stack trace: $stackTrace');
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
    return box.values.toList();
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
  }

  Future<void> close() async {
    await Hive.close();
  }
}
