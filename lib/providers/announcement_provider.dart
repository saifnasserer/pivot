import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:pivot/screens/section2/adminstration/models/announcement_data.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'dart:io';
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
        _announcements = cachedAnnouncements;
        notifyListeners();
      }

      // Step 2: Fetch from server in the background
      List<AnnouncementData> timeFilteredAnnouncements = [];
      List<AnnouncementData> pinnedAnnouncements = [];

      // Fetch time-filtered announcements
      Query timeQuery = _firestore
          .collection(_collectionPath)
          .orderBy('timestamp', descending: true);

      final String? departmentToFilter = department;
      if (departmentToFilter != null && departmentToFilter.isNotEmpty) {
        if (departmentToFilter == 'عام') {
          // Filter for general announcements (those with 'عام' tag)
          timeQuery = timeQuery.where('tags', arrayContains: 'عام');
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
          timeQuery = timeQuery.where('tags', arrayContains: departmentTag);
        }
      }

      if (timeFilter != null && timeFilter.isNotEmpty) {
        final now = DateTime.now();
        DateTime? startDate;
        if (timeFilter == 'today') {
          startDate = DateTime(now.year, now.month, now.day);
        } else if (timeFilter == 'week') {
          final weekAgo = now.subtract(const Duration(days: 7));
          startDate = DateTime(weekAgo.year, weekAgo.month, weekAgo.day);
        }
        if (startDate != null) {
          timeQuery = timeQuery.where(
            'timestamp',
            isGreaterThanOrEqualTo: startDate,
          );
        }
      }

      final timeSnapshot = await timeQuery.get();
      timeFilteredAnnouncements =
          timeSnapshot.docs
              .map((doc) => AnnouncementData.fromFirestore(doc))
              .toList();

      // If filtering by 'today', also fetch all pinned announcements regardless of time
      if (timeFilter == 'today') {
        Query pinnedQuery = _firestore
            .collection(_collectionPath)
            .where('pinned', isEqualTo: true)
            .orderBy('timestamp', descending: true);

        if (departmentToFilter != null && departmentToFilter.isNotEmpty) {
          if (departmentToFilter == 'عام') {
            // Filter for general announcements (those with 'عام' tag)
            pinnedQuery = pinnedQuery.where('tags', arrayContains: 'عام');
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
            pinnedQuery = pinnedQuery.where(
              'tags',
              arrayContains: departmentTag,
            );
          }
        }

        final pinnedSnapshot = await pinnedQuery.get();
        pinnedAnnouncements =
            pinnedSnapshot.docs
                .map((doc) => AnnouncementData.fromFirestore(doc))
                .toList();
      }

      // Merge and deduplicate announcements
      final Map<String, AnnouncementData> mergedAnnouncements = {};

      // Add time-filtered announcements first
      for (final announcement in timeFilteredAnnouncements) {
        mergedAnnouncements[announcement.id ?? ''] = announcement;
      }

      // Add pinned announcements (they will override duplicates if any)
      for (final announcement in pinnedAnnouncements) {
        mergedAnnouncements[announcement.id ?? ''] = announcement;
      }

      _announcements = mergedAnnouncements.values.toList();

      // Sort announcements: pinned first, then by timestamp
      _announcements.sort((a, b) {
        if (a.pinned == b.pinned) {
          return b.timestamp.compareTo(a.timestamp);
        }
        return b.pinned ? 1 : -1;
      });

      // Filter out scheduled (future) and expired announcements unless requested otherwise
      if (!includeScheduledAndExpired) {
        final now = DateTime.now();
        // Remove expired announcements from Firestore
        final expired =
            _announcements
                .where((a) => a.expireAt != null && a.expireAt!.isBefore(now))
                .toList();
        for (final a in expired) {
          // Delete from Firestore
          await _firestore.collection(_collectionPath).doc(a.id).delete();
        }
        _announcements =
            _announcements.where((a) {
              final publishAt = a.publishAt;
              final expireAt = a.expireAt;
              if (publishAt != null && publishAt.isAfter(now)) return false;
              if (expireAt != null && expireAt.isBefore(now)) return false;
              return true;
            }).toList();
      }
      await CacheService.instance.cacheAnnouncements(_announcements);
    } catch (e) {
      debugPrint('[FETCH] Error fetching announcements: $e');
      _announcements = [];
    }
    _isLoading = false;
    notifyListeners();
  }

  // Add an announcement and refresh the list with the current filters
  Future<void> addAnnouncement(AnnouncementData announcement) async {
    try {
      final data = announcement.toJson();
      debugPrint(
        'Saving announcement with tags: ${data['tags']}',
      ); // Diagnostic print
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
      debugPrint('Error adding announcement: $e');
    }
  }

  // Update an announcement and refresh the list with the current filters
  Future<void> updateAnnouncement(AnnouncementData announcement) async {
    if (announcement.id == null) {
      debugPrint('Error: Announcement ID is null, cannot update.');
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
      debugPrint('Error updating announcement: $e');
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
        debugPrint('Image uploaded successfully: $downloadUrl');
      }

      return downloadUrl;
    } catch (e) {
      debugPrint('Error in uploadImage function: $e');
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
      debugPrint('Error deleting announcement: $e');
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
      debugPrint('Error pinning announcement: $e');
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
      debugPrint('Error unpinning announcement: $e');
    }
  }

  // Announcement Caching
  Future<void> cacheAnnouncements(List<AnnouncementData> announcements) async {
    debugPrint('[AnnouncementProvider] cacheAnnouncements called');
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
    debugPrint('[AnnouncementProvider] getCachedAnnouncements called');
    if (!Hive.isBoxOpen(_announcementsBoxName)) {
      throw Exception(
        'Announcement box is not open! Make sure CacheService.init() is called before any provider access.',
      );
    }
    final box = Hive.box<AnnouncementData>(_announcementsBoxName);
    return box.values.toList();
  }
}
