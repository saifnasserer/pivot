import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:pivot/screens/section2/adminstration/models/announcement_data.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'dart:io';
import 'package:pivot/services/cache_service.dart';
import 'package:pivot/services/notification_trigger_service.dart';

class AnnouncementProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collectionPath = 'announcements';

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
      Query query = _firestore
          .collection(_collectionPath)
          .orderBy('timestamp', descending: true);
      final String? departmentToFilter = department;
      if (departmentToFilter != null && departmentToFilter.isNotEmpty) {
        final departmentTag = 'اخبار قسم $departmentToFilter';
        query = query.where('tags', arrayContains: departmentTag);
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
          query = query.where('timestamp', isGreaterThanOrEqualTo: startDate);
        }
      }
      final snapshot = await query.get();
      _announcements =
          snapshot.docs
              .map((doc) => AnnouncementData.fromFirestore(doc))
              .toList();
      _announcements.sort((a, b) {
        if (a.pinned == b.pinned) {
          return b.timestamp.compareTo(a.timestamp);
        }
        return b.pinned ? 1 : -1;
      });
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
      // Compress the image before uploading
      final tempDir = Directory.systemTemp;
      final targetPath =
          '${tempDir.path}/${DateTime.now().millisecondsSinceEpoch}.jpg';
      final compressedFile = await FlutterImageCompress.compressAndGetFile(
        image.path,
        targetPath,
        quality: 60,
        minWidth: 600,
        minHeight: 600,
        format: CompressFormat.jpeg,
      );
      final fileToUpload = compressedFile ?? File(image.path);
      final bytes = await (fileToUpload as File).readAsBytes();
      final String fileName = '${const Uuid().v4()}.jpg';
      final Reference storageRef = FirebaseStorage.instance.ref().child(
        'announcements/$fileName',
      );

      final UploadTask uploadTask = storageRef.putData(bytes);

      // Listen for state changes, errors, and completion of the upload.
      uploadTask.snapshotEvents.listen(
        (TaskSnapshot taskSnapshot) {
          debugPrint(
            'Task state: ${taskSnapshot.state}',
          ); // paused, running, success
          debugPrint(
            'Progress: ${(taskSnapshot.bytesTransferred / taskSnapshot.totalBytes) * 100} %',
          );
        },
        onError: (e) {
          // This will catch events like permission errors
          debugPrint('Upload error from listener: $e');
        },
      );

      // Await completion
      final TaskSnapshot snapshot = await uploadTask;
      final String downloadUrl = await snapshot.ref.getDownloadURL();
      debugPrint('Upload successful: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      // This will catch other exceptions
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
}
