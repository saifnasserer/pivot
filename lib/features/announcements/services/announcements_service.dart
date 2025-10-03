import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:pivot/features/home/screens/adminstration/models/announcement_data.dart';
import 'package:pivot/models/comment_data.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:pivot/services/cache_service.dart';
import 'package:pivot/services/notification_trigger_service.dart';

class AnnouncementsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final String _collectionPath = 'announcements';
  final NotificationTriggerService _notificationService =
      NotificationTriggerService();

  // Store last document for pagination
  DocumentSnapshot? _lastDocument;
  DocumentSnapshot? get lastDocument => _lastDocument;

  Future<List<AnnouncementData>> fetchAnnouncements({
    String? department,
    String? timeFilter,
    String? userLevel,
    bool includeScheduledAndExpired = false,
    int limit = 10,
    DocumentSnapshot? startAfterDocument,
  }) async {
    try {
      Query query = _firestore.collection(_collectionPath);

      // Store if this is a "today_mixed" filter for special handling
      bool isTodayMixed = false;
      String? todayMixedDepartment;

      // Apply filters
      if (department != null && department.isNotEmpty) {
        // Handle special case for today's news with mixed department content
        if (department.startsWith('today_mixed:')) {
          isTodayMixed = true;
          // For today's news, get the user's department
          todayMixedDepartment = department.replaceFirst('today_mixed:', '');
          // Don't apply department filter here - we'll filter client-side for more flexibility
        } else {
          // Filter by tags array (original working approach)
          query = query.where('tags', arrayContains: department);
        }
      }

      if (timeFilter != null && timeFilter.isNotEmpty && !isTodayMixed) {
        final now = DateTime.now();
        DateTime startDate;

        switch (timeFilter) {
          case 'today':
            // Past 24 hours (rolling window, not since midnight)
            startDate = now.subtract(const Duration(hours: 24));
            break;
          case 'week':
            startDate = now.subtract(const Duration(days: 7));
            break;
          case 'month':
            startDate = DateTime(now.year, now.month - 1, now.day);
            break;
          default:
            startDate = DateTime(now.year - 1, now.month, now.day);
        }

        query = query.where(
          'timestamp',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
        );
      }

      // Order by timestamp descending
      query = query.orderBy('timestamp', descending: true);

      // Apply pagination
      if (startAfterDocument != null) {
        query = query.startAfterDocument(startAfterDocument);
      }

      // Limit results
      query = query.limit(limit);

      final snapshot = await query.get();

      // Store last document for pagination
      _lastDocument = snapshot.docs.isNotEmpty ? snapshot.docs.last : null;

      var announcements =
          snapshot.docs
              .map(
                (doc) => AnnouncementData.fromMap(
                  doc.data() as Map<String, dynamic>,
                  doc.id,
                ),
              )
              .toList();

      // Special filtering for "today_mixed" (Today's News category)
      if (isTodayMixed && todayMixedDepartment != null) {
        final now = DateTime.now();
        final past24Hours = now.subtract(const Duration(hours: 24));

        announcements =
            announcements.where((announcement) {
              // Check if announcement belongs to user's department or is general
              final hasUserDepartment = announcement.tags.contains(
                todayMixedDepartment,
              );
              final isGeneral = announcement.tags.contains('اخبار عامة');

              // Must be user's department or general
              if (!hasUserDepartment && !isGeneral) {
                return false;
              }

              // Pinned announcements from user's dept/general → always show regardless of age
              if (announcement.pinned == true) {
                return true;
              }

              // For non-pinned, must be from past 24 hours
              if (announcement.timestamp.isBefore(past24Hours)) {
                return false;
              }

              return true;
            }).toList();
      }

      // Filter by user level if provided
      if (userLevel != null && userLevel.isNotEmpty) {
        announcements =
            announcements.where((announcement) {
              // If announcement has no level specified, show it to everyone (general announcements)
              if (announcement.level == null || announcement.level!.isEmpty) {
                return true;
              }
              // If announcement specifies multiple levels (comma-separated), check if user's level is included
              final announcementLevels =
                  announcement.level!.split(',').map((l) => l.trim()).toList();
              return announcementLevels.contains(userLevel);
            }).toList();
      }

      // Filter scheduled and expired announcements
      if (!includeScheduledAndExpired) {
        final now = DateTime.now();

        announcements =
            announcements.where((announcement) {
              // Check if announcement is scheduled for future
              if (announcement.publishAt != null &&
                  announcement.publishAt!.isAfter(now)) {
                return false;
              }

              // Check if announcement has expired
              if (announcement.expireAt != null &&
                  announcement.expireAt!.isBefore(now)) {
                // Queue for deletion (async, don't block the fetch)
                _deleteExpiredAnnouncement(announcement.id);
                return false;
              }

              return true;
            }).toList();
      }

      // Cache the results
      await _cacheAnnouncements(announcements);

      return announcements;
    } catch (e) {
      // Try to load from cache on error
      return await _loadCachedAnnouncements();
    }
  }

  Future<void> addAnnouncement(AnnouncementData announcement) async {
    try {
      final docRef = await _firestore
          .collection(_collectionPath)
          .add(announcement.toMap());

      // Update with generated ID
      await docRef.update({'id': docRef.id});

      // Trigger notifications asynchronously (don't block the creation)
      _triggerAnnouncementNotification(announcement, docRef.id);
    } catch (e) {
      throw Exception('Failed to add announcement: $e');
    }
  }

  /// Triggers push notifications for new announcements
  /// This runs asynchronously and doesn't block the announcement creation
  Future<void> _triggerAnnouncementNotification(
    AnnouncementData announcement,
    String announcementId,
  ) async {
    try {
      // Don't send notifications for scheduled announcements
      if (announcement.publishAt != null &&
          announcement.publishAt!.isAfter(DateTime.now())) {
        return;
      }

      // Prepare notification data
      final notificationData = {
        'type': 'announcement',
        'announcementId': announcementId,
        'timestamp': DateTime.now().millisecondsSinceEpoch.toString(),
      };

      // Extract department from tags (e.g., "اخبار قسم SC" -> "SC")
      String? targetDepartment;
      if (announcement.tags.isNotEmpty) {
        for (final tag in announcement.tags) {
          if (tag.startsWith('اخبار قسم ')) {
            targetDepartment = tag.replaceFirst('اخبار قسم ', '');
            break;
          }
        }
      }

      // 1. Send to specific level if specified
      if (announcement.level != null && announcement.level!.isNotEmpty) {
        // Handle comma-separated levels
        final levels =
            announcement.level!.split(',').map((l) => l.trim()).toList();

        for (final level in levels) {
          await _notificationService.sendLevelNotification(
            level,
            announcement.title,
            announcement.description.length > 100
                ? '${announcement.description.substring(0, 100)}...'
                : announcement.description,
          );
        }
      }
      // 2. Send to specific department if no level specified but department is specified
      else if (targetDepartment != null) {
        await _notificationService.sendDepartmentNotification(
          targetDepartment,
          announcement.title,
          announcement.description.length > 100
              ? '${announcement.description.substring(0, 100)}...'
              : announcement.description,
          data: notificationData,
        );
      }
      // 3. Send to all users for general announcements
      else {
        await _notificationService.sendGlobalNotification(
          announcement.title,
          announcement.description.length > 100
              ? '${announcement.description.substring(0, 100)}...'
              : announcement.description,
          data: notificationData,
        );
      }
    } catch (e) {
      // Don't throw - notification failure shouldn't break announcement creation
    }
  }

  Future<void> updateAnnouncement(
    String id,
    AnnouncementData announcement,
  ) async {
    try {
      await _firestore
          .collection(_collectionPath)
          .doc(id)
          .update(announcement.toMap());
    } catch (e) {
      throw Exception('Failed to update announcement: $e');
    }
  }

  Future<void> deleteAnnouncement(String id) async {
    try {
      // First, get the announcement to retrieve image URLs
      final announcementDoc =
          await _firestore.collection(_collectionPath).doc(id).get();

      if (announcementDoc.exists) {
        final data = announcementDoc.data();
        final imageUrls =
            (data?['imageUrls'] as List<dynamic>?)?.cast<String>() ?? [];

        // Delete all associated images from Firebase Storage
        if (imageUrls.isNotEmpty) {
          for (final imageUrl in imageUrls) {
            try {
              // Skip placeholder URLs
              if (imageUrl.startsWith('placeholder_')) {
                continue;
              }

              // Extract the storage path from the URL
              final ref = _storage.refFromURL(imageUrl);
              await ref.delete();
            } catch (e) {
              // Continue deleting other images even if one fails
            }
          }
        }
      }

      // Delete the Firestore document
      await _firestore.collection(_collectionPath).doc(id).delete();
    } catch (e) {
      throw Exception('Failed to delete announcement: $e');
    }
  }

  Future<void> togglePin(String id) async {
    try {
      final doc = await _firestore.collection(_collectionPath).doc(id).get();
      if (doc.exists) {
        final currentPinned = doc.data()?['pinned'] ?? false;
        await _firestore.collection(_collectionPath).doc(id).update({
          'pinned': !currentPinned,
        });
      }
    } catch (e) {
      throw Exception('Failed to toggle pin: $e');
    }
  }

  Future<void> addComment(String announcementId, CommentData comment) async {
    try {
      await _firestore
          .collection(_collectionPath)
          .doc(announcementId)
          .collection('comments')
          .add(comment.toMap());
    } catch (e) {
      throw Exception('Failed to add comment: $e');
    }
  }

  Future<void> deleteComment(String announcementId, String commentId) async {
    try {
      await _firestore
          .collection(_collectionPath)
          .doc(announcementId)
          .collection('comments')
          .doc(commentId)
          .delete();
    } catch (e) {
      throw Exception('Failed to delete comment: $e');
    }
  }

  Future<List<CommentData>> getComments(String announcementId) async {
    try {
      final snapshot =
          await _firestore
              .collection(_collectionPath)
              .doc(announcementId)
              .collection('comments')
              .orderBy('timestamp', descending: true)
              .get();

      return snapshot.docs
          .map((doc) => CommentData.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw Exception('Failed to get comments: $e');
    }
  }

  // Stream comments for real-time updates
  Stream<List<CommentData>> streamComments(String announcementId) {
    try {
      return _firestore
          .collection(_collectionPath)
          .doc(announcementId)
          .collection('comments')
          .orderBy('timestamp', descending: true)
          .snapshots()
          .map(
            (snapshot) =>
                snapshot.docs
                    .map((doc) => CommentData.fromMap(doc.data(), doc.id))
                    .toList(),
          );
    } catch (e) {
      throw Exception('Failed to stream comments: $e');
    }
  }

  // Like a comment
  Future<void> likeComment(
    String announcementId,
    String commentId,
    String userId,
  ) async {
    try {
      final commentRef = _firestore
          .collection(_collectionPath)
          .doc(announcementId)
          .collection('comments')
          .doc(commentId);

      final doc = await commentRef.get();
      if (doc.exists) {
        final likes = List<String>.from(doc.data()?['likes'] ?? []);
        if (likes.contains(userId)) {
          likes.remove(userId);
        } else {
          likes.add(userId);
        }
        await commentRef.update({'likes': likes});
      }
    } catch (e) {
      throw Exception('Failed to like comment: $e');
    }
  }

  // Reply to a comment
  Future<void> replyToComment(
    String announcementId,
    String parentCommentId,
    CommentData reply,
  ) async {
    try {
      await _firestore
          .collection(_collectionPath)
          .doc(announcementId)
          .collection('comments')
          .add(reply.toMap());
    } catch (e) {
      throw Exception('Failed to reply to comment: $e');
    }
  }

  // Update a comment
  Future<void> updateComment(
    String announcementId,
    String commentId,
    String newContent,
  ) async {
    try {
      await _firestore
          .collection(_collectionPath)
          .doc(announcementId)
          .collection('comments')
          .doc(commentId)
          .update({'content': newContent});
    } catch (e) {
      throw Exception('Failed to update comment: $e');
    }
  }

  Future<List<String>> uploadImages(List<String> imagePaths) async {
    try {
      final uploadedUrls = <String>[];

      for (int i = 0; i < imagePaths.length; i++) {
        final imagePath = imagePaths[i];
        final compressedImage = await FlutterImageCompress.compressWithFile(
          imagePath,
          quality: 85,
          minWidth: 800,
          minHeight: 600,
        );

        if (compressedImage != null) {
          // Generate unique announcement ID and filename
          final announcementId =
              DateTime.now().millisecondsSinceEpoch.toString();
          final fileName = 'image_$i.jpg';

          // Upload to Firebase Storage following the rules pattern
          final storageRef = _storage
              .ref()
              .child('announcements')
              .child(announcementId)
              .child('attachments')
              .child(fileName);

          final uploadTask = storageRef.putData(compressedImage);
          final snapshot = await uploadTask;

          if (snapshot.state == TaskState.success) {
            final downloadUrl = await snapshot.ref.getDownloadURL();
            uploadedUrls.add(downloadUrl);
          }
        }
      }

      return uploadedUrls;
    } catch (e) {
      throw Exception('Failed to upload images: $e');
    }
  }

  Future<void> _cacheAnnouncements(List<AnnouncementData> announcements) async {
    try {
      // Use CacheService to ensure consistent box handling
      await CacheService.instance.cacheAnnouncements(announcements);
    } catch (e) {
      // Cache failure shouldn't break the app
      print('Failed to cache announcements: $e');
    }
  }

  Future<List<AnnouncementData>> _loadCachedAnnouncements() async {
    try {
      // Use CacheService to ensure consistent box handling
      return CacheService.instance.getCachedAnnouncements();
    } catch (e) {
      print('Failed to load cached announcements: $e');
      return [];
    }
  }

  /// Deletes an expired announcement from Firestore
  /// This is called asynchronously without blocking the main fetch operation
  Future<void> _deleteExpiredAnnouncement(String? announcementId) async {
    if (announcementId == null || announcementId.isEmpty) return;

    try {
      await deleteAnnouncement(announcementId);
    } catch (e) {
      // Don't throw - this is a background cleanup operation
    }
  }
}
