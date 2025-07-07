import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:pivot/screens/section2/adminstration/models/announcement_data.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:pivot/services/cache_service.dart';
import 'package:pivot/services/notification_trigger_service.dart';
import 'package:pivot/services/storage_optimization_service.dart';
import 'package:image_picker/image_picker.dart';

class AnnouncementProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collectionPath = 'announcements';
  static const String _announcementsBoxName = 'announcementsBox';

  List<AnnouncementData> _announcements = [];
  bool _isLoading = false;
  String? _currentDepartmentFilter;
  String? _currentTimeFilter;

  List<AnnouncementData> get announcements => _announcements;
  bool get isLoading => _isLoading;

  // Fetch announcements with optional department and time-based filters
  Future<void> fetchAnnouncements({
    String? department,
    String? timeFilter,
    bool includeScheduledAndExpired = false,
  }) async {
    _isLoading = true;
    _currentDepartmentFilter = department;
    _currentTimeFilter = timeFilter;
    notifyListeners();

    try {
      // Step 1: Load from cache first
      final cachedAnnouncements =
          CacheService.instance.getCachedAnnouncements();
      if (cachedAnnouncements.isNotEmpty) {
        //debugprint(
        //   '[ANNOUNCEMENT_PROVIDER] Loaded ${cachedAnnouncements.length} announcements from cache',
        // );
        _announcements = cachedAnnouncements;
        notifyListeners();
      }

      // Step 2: Fetch from server in the background
      Query query = _firestore
          .collection(_collectionPath)
          .orderBy('timestamp', descending: true);

      final String? departmentToFilter = department;

      if (departmentToFilter != null && departmentToFilter.isNotEmpty) {
        if (departmentToFilter == 'عام') {
          // Filter for general announcements (those with 'عام' tag)
          // //debugprint('[ANNOUNCEMENT_PROVIDER] Filtering for عام announcements');
          query = query.where('tags', arrayContains: 'عام');
        } else if (departmentToFilter.startsWith('today_mixed:')) {
          // Special case for today's news: include both user's department and عام announcements
          // Format: 'today_mixed:userDeptTag'
          // final userDeptTag = departmentToFilter.substring(
          //   'today_mixed:'.length,
          // );
          //debugprint(
          //   '[ANNOUNCEMENT_PROVIDER] Today mixed filtering - User dept tag: $userDeptTag',
          // );
          // We'll handle this with multiple queries and merge results
        } else {
          // Handle both short format (SC) and full format (اخبار قسم SC)
          String departmentTag;
          if (departmentToFilter.startsWith('اخبار قسم ')) {
            // Already in full format
            departmentTag = departmentToFilter;
          } else {
            // Convert short format to full format
            departmentTag = 'اخبار قسم $departmentToFilter';
          }
          //debugprint(
          //   '[ANNOUNCEMENT_PROVIDER] Department filtering - Department tag: $departmentTag',
          // );
          query = query.where('tags', arrayContains: departmentTag);
        }
      }

      if (timeFilter != null && timeFilter.isNotEmpty) {
        final now = DateTime.now();
        DateTime? startDate;
        if (timeFilter == 'today') {
          // Show announcements from the last 24 hours instead of calendar day
          startDate = now.subtract(const Duration(hours: 24));
          //debugprint(
          //   '[ANNOUNCEMENT_PROVIDER] Time filtering - Last 24 hours from: $startDate',
          // );
        } else if (timeFilter == 'week') {
          final weekAgo = now.subtract(const Duration(days: 7));
          startDate = DateTime(weekAgo.year, weekAgo.month, weekAgo.day);
          //debugprint(
          //   '[ANNOUNCEMENT_PROVIDER] Time filtering - Week from: $startDate',
          // );
        }
        if (startDate != null) {
          query = query.where(
            'timestamp',
            isGreaterThanOrEqualTo: startDate.millisecondsSinceEpoch,
          );
        }
      }

      List<AnnouncementData> announcements = [];

      // Handle special case for today's mixed filtering
      if (departmentToFilter != null &&
          departmentToFilter.startsWith('today_mixed:') &&
          timeFilter == 'today') {
        //debugprint('[ANNOUNCEMENT_PROVIDER] Executing today mixed filtering');

        // Fetch announcements from today that are either from user's department OR are عام
        final now = DateTime.now();
        // Use last 24 hours instead of calendar day
        final startDate = now.subtract(const Duration(hours: 24));
        //debugprint(
        //   '[ANNOUNCEMENT_PROVIDER] Today mixed - Last 24 hours from: $startDate',
        // );
        //debugprint('[ANNOUNCEMENT_PROVIDER] Today mixed - Current time: $now');
        //debugprint(
        //   '[ANNOUNCEMENT_PROVIDER] Today mixed - Start date milliseconds: ${startDate.millisecondsSinceEpoch}',
        // );

        // Extract user department tag from the format 'today_mixed:userDeptTag'
        final userDeptTag = departmentToFilter.substring('today_mixed:'.length);
        //debugprint(
        //   '[ANNOUNCEMENT_PROVIDER] Today mixed - User dept tag: $userDeptTag',
        // );

        // DEBUG: Check what announcements exist in the database
        //debugprint(
        //   '[ANNOUNCEMENT_PROVIDER] DEBUG: Checking all announcements in database...',
        // );
        final allAnnouncementsSnapshot =
            await _firestore.collection(_collectionPath).get();
        //debugprint(
        //   '[ANNOUNCEMENT_PROVIDER] DEBUG: Total announcements in database: ${allAnnouncementsSnapshot.docs.length}',
        // );

        for (final doc in allAnnouncementsSnapshot.docs) {
          final data = doc.data();
          final tags = List<String>.from(data['tags'] ?? []);
          final timestamp = data['timestamp'];
          final title = data['title'] ?? 'No title';

          // Convert timestamp to readable date
          // DateTime announcementDate;
          // if (timestamp is int) {
          //   announcementDate = DateTime.fromMillisecondsSinceEpoch(timestamp);
          // } else if (timestamp is Timestamp) {
          //   announcementDate = timestamp.toDate();
          // } else {
          //   announcementDate = DateTime.now();
          // }

          //debugprint(
          //   '[ANNOUNCEMENT_PROVIDER] DEBUG: Announcement "$title" - Tags: $tags, Timestamp: $timestamp, Date: $announcementDate',
          // );
        }

        // DEBUG: Check announcements with the specific department tag (any time)
        //debugprint(
        //   '[ANNOUNCEMENT_PROVIDER] DEBUG: Checking announcements with tag: $userDeptTag (any time)',
        // );
        final deptAnyTimeQuery = _firestore
            .collection(_collectionPath)
            .where('tags', arrayContains: userDeptTag);
        final deptAnyTimeSnapshot = await deptAnyTimeQuery.get();
        //debugprint(
        //   '[ANNOUNCEMENT_PROVIDER] DEBUG: Announcements with tag $userDeptTag (any time): ${deptAnyTimeSnapshot.docs.length}',
        // );

        // DEBUG: Check announcements with عام tag (any time)
        //debugprint(
        //   '[ANNOUNCEMENT_PROVIDER] DEBUG: Checking announcements with tag: عام (any time)',
        // );
        // final generalAnyTimeQuery = _firestore
        //     .collection(_collectionPath)
        //     .where('tags', arrayContains: 'عام');
        // final generalAnyTimeSnapshot = await generalAnyTimeQuery.get();
        //debugprint(
        //   '[ANNOUNCEMENT_PROVIDER] DEBUG: Announcements with tag عام (any time): ${generalAnyTimeSnapshot.docs.length}',
        // );

        // DEBUG: Check announcements from today (any tag)
        //debugprint(
        //   '[ANNOUNCEMENT_PROVIDER] DEBUG: Checking announcements from last 24 hours (any tag)',
        // );
        // final todayAnyTagQuery = _firestore
        //     .collection(_collectionPath)
        //     .where(
        //       'timestamp',
        //       isGreaterThanOrEqualTo: startDate.millisecondsSinceEpoch,
        //     );
        // final todayAnyTagSnapshot = await todayAnyTagQuery.get();
        //debugprint(
        //   '[ANNOUNCEMENT_PROVIDER] DEBUG: Announcements from last 24 hours (any tag): ${todayAnyTagSnapshot.docs.length}',
        // );

        // Query 1: Today's announcements from user's department
        Query deptQuery = _firestore
            .collection(_collectionPath)
            .where('tags', arrayContains: userDeptTag)
            .where(
              'timestamp',
              isGreaterThanOrEqualTo: startDate.millisecondsSinceEpoch,
            )
            .orderBy('timestamp', descending: true);

        //debugprint(
        //   '[ANNOUNCEMENT_PROVIDER] Today mixed - Executing department query for tag: $userDeptTag (last 24h)',
        // );
        final deptSnapshot = await deptQuery.get();
        // //debugprint(
        //   '[ANNOUNCEMENT_PROVIDER] Today mixed - Department query returned ${deptSnapshot.docs.length} documents',
        // );

        // Query 2: Today's عام announcements
        Query generalQuery = _firestore
            .collection(_collectionPath)
            .where('tags', arrayContains: 'عام')
            .where(
              'timestamp',
              isGreaterThanOrEqualTo: startDate.millisecondsSinceEpoch,
            )
            .orderBy('timestamp', descending: true);

        //debugprint(
        //   '[ANNOUNCEMENT_PROVIDER] Today mixed - Executing general query for عام (last 24h)',
        // );
        final generalSnapshot = await generalQuery.get();
        //debugprint(
        // '[ANNOUNCEMENT_PROVIDER] Today mixed - General query returned ${generalSnapshot.docs.length} documents',
        // );

        // Merge results and deduplicate
        final Map<String, AnnouncementData> mergedResults = {};

        for (final doc in deptSnapshot.docs) {
          final announcement = AnnouncementData.fromFirestore(doc);
          mergedResults[announcement.id ?? ''] = announcement;
          //debugprint(
          //   '[ANNOUNCEMENT_PROVIDER] Today mixed - Added department announcement: ${announcement.title} (ID: ${announcement.id})',
          // );
        }

        for (final doc in generalSnapshot.docs) {
          final announcement = AnnouncementData.fromFirestore(doc);
          mergedResults[announcement.id ?? ''] = announcement;
          //debugprint(
          //   '[ANNOUNCEMENT_PROVIDER] Today mixed - Added general announcement: ${announcement.title} (ID: ${announcement.id})',
          // );
        }

        announcements = mergedResults.values.toList();
        //debugprint(
        //   '[ANNOUNCEMENT_PROVIDER] Today mixed - Final merged count: ${announcements.length}',
        // );

        // Remove the fallback logic - "اخبار اليوم" should only show last 24 hours
        // even if there are no announcements in that time period
      } else {
        // Regular query execution
        //debugprint('[ANNOUNCEMENT_PROVIDER] Executing regular query');
        final snapshot = await query.get();
        //debugprint(
        //   '[ANNOUNCEMENT_PROVIDER] Regular query returned ${snapshot.docs.length} documents',
        // );
        announcements =
            snapshot.docs
                .map((doc) => AnnouncementData.fromFirestore(doc))
                .toList();
      }

      //debugprint(
      //   '[ANNOUNCEMENT_PROVIDER] Before sorting - Count: ${announcements.length}',
      // );

      // Sort announcements: pinned first, then by timestamp
      announcements.sort((a, b) {
        if (a.pinned == b.pinned) {
          return b.timestamp.compareTo(a.timestamp);
        }
        return b.pinned ? 1 : -1;
      });

      //debugprint(
      //   '[ANNOUNCEMENT_PROVIDER] After sorting - Count: ${announcements.length}',
      // );
      //debugprint(
      //   '[ANNOUNCEMENT_PROVIDER] Pinned announcements: ${announcements.where((a) => a.pinned).length}',
      // );

      // Filter out scheduled (future) and expired announcements unless requested otherwise
      if (!includeScheduledAndExpired) {
        final now = DateTime.now();
        // Remove expired announcements from Firestore
        final expired =
            announcements
                .where((a) => a.expireAt != null && a.expireAt!.isBefore(now))
                .toList();
        //debugprint(
        //   '[ANNOUNCEMENT_PROVIDER] Expired announcements found: ${expired.length}',
        // );

        for (final a in expired) {
          // Delete from Firestore
          await _firestore.collection(_collectionPath).doc(a.id).delete();
        }

        // final beforeFilter = announcements.length;
        announcements =
            announcements.where((a) {
              final publishAt = a.publishAt;
              final expireAt = a.expireAt;
              if (publishAt != null && publishAt.isAfter(now)) return false;
              if (expireAt != null && expireAt.isBefore(now)) return false;
              return true;
            }).toList();
        //debugprint(
        //   '[ANNOUNCEMENT_PROVIDER] After filtering scheduled/expired - Before: $beforeFilter, After: ${announcements.length}',
        // );
      }

      _announcements = announcements;
      //debugprint(
      //   '[ANNOUNCEMENT_PROVIDER] Final announcements count: ${_announcements.length}',
      // );

      await CacheService.instance.cacheAnnouncements(_announcements);
    } catch (e) {
      //debugprint('[ANNOUNCEMENT_PROVIDER] Error fetching announcements: $e');
      _announcements = [];
    }
    _isLoading = false;
    notifyListeners();
  }

  // Add an announcement and refresh the list with the current filters
  Future<void> addAnnouncement(AnnouncementData announcement) async {
    try {
      final data = announcement.toJson();
      //debugprint(
      //   'Saving announcement with tags: ${data['tags']}',
      // ); // Diagnostic print
      await _firestore.collection(_collectionPath).add(data);
      await fetchAnnouncements(
        department: _currentDepartmentFilter,
        timeFilter: _currentTimeFilter,
      );

      // Send notification for new announcement
      if (announcement.tags.isNotEmpty) {
        // Extract department from tags (assuming format: "اخبار قسم [Department]")
        for (String tag in announcement.tags) {
          if (tag.startsWith('اخبار قسم ')) {
            final department = tag.replaceFirst('اخبار قسم ', '');
            await NotificationTriggerService().sendDepartmentNotification(
              department,
              announcement.title,
              announcement.description,
            );
            break; // Send to first department found
          }
        }
      }
    } catch (e) {
      //debugprint('Error adding announcement: $e');
    }
  }

  // Update an announcement and refresh the list with the current filters
  Future<void> updateAnnouncement(AnnouncementData announcement) async {
    if (announcement.id == null) {
      //debugprint('Error: Announcement ID is null, cannot update.');
      return;
    }
    try {
      await _firestore
          .collection(_collectionPath)
          .doc(announcement.id)
          .update(announcement.toJson());
      await fetchAnnouncements(
        department: _currentDepartmentFilter,
        timeFilter: _currentTimeFilter,
      );
    } catch (e) {
      //debugprint('Error updating announcement: $e');
    }
  }

  // Upload an image to Firebase Storage and return the URL
  Future<String?> uploadImage(XFile image) async {
    try {
      // Use the optimized storage service
      final storageService = StorageOptimizationService();
      final downloadUrl = await storageService.uploadFileOptimized(
        image,
        folder: 'announcements',
        usage: 'announcement',
        checkDuplicate: true,
      );

      if (downloadUrl != null) {
        //debugprint('Image uploaded successfully: $downloadUrl');
      }

      return downloadUrl;
    } catch (e) {
      //debugprint('Error in uploadImage function: $e');
      return null;
    }
  }

  // Delete an announcement and refresh the list with the current filters
  Future<void> deleteAnnouncement(String announcementId) async {
    try {
      final doc =
          await _firestore
              .collection(_collectionPath)
              .doc(announcementId)
              .get();
      final title = doc.exists ? doc.data()!['title'] : '';
      await _firestore.collection(_collectionPath).doc(announcementId).delete();
      await fetchAnnouncements(
        department: _currentDepartmentFilter,
        timeFilter: _currentTimeFilter,
      );
    } catch (e) {
      //debugprint('Error deleting announcement: $e');
    }
  }

  // Add pin/unpin functionality
  Future<void> pinAnnouncement(AnnouncementData announcement) async {
    if (announcement.id == null) return;
    try {
      await _firestore.collection(_collectionPath).doc(announcement.id).update({
        'pinned': true,
      });
      await fetchAnnouncements(
        department: _currentDepartmentFilter,
        timeFilter: _currentTimeFilter,
      );
    } catch (e) {
      //debugprint('Error pinning announcement: $e');
    }
  }

  Future<void> unpinAnnouncement(AnnouncementData announcement) async {
    if (announcement.id == null) return;
    try {
      await _firestore.collection(_collectionPath).doc(announcement.id).update({
        'pinned': false,
      });
      await fetchAnnouncements(
        department: _currentDepartmentFilter,
        timeFilter: _currentTimeFilter,
      );
    } catch (e) {
      //debugprint('Error unpinning announcement: $e');
    }
  }

  // Announcement Caching
  Future<void> cacheAnnouncements(List<AnnouncementData> announcements) async {
    //debugprint('[AnnouncementProvider] cacheAnnouncements called');
    if (!Hive.isBoxOpen(_announcementsBoxName)) {
      throw Exception(
        'Announcement box is not open! Make sure CacheService.init() is called before any provider access.',
      );
    }
    final box = Hive.box<AnnouncementData>(_announcementsBoxName);
    await box.clear();
    for (var ann in announcements) {
      await box.put(ann.id ?? ann.title, ann);
    }
  }

  Future<List<AnnouncementData>> getCachedAnnouncements() async {
    //debugprint('[AnnouncementProvider] getCachedAnnouncements called');
    if (!Hive.isBoxOpen(_announcementsBoxName)) {
      throw Exception(
        'Announcement box is not open! Make sure CacheService.init() is called before any provider access.',
      );
    }
    final box = Hive.box<AnnouncementData>(_announcementsBoxName);
    return box.values.toList();
  }
}
