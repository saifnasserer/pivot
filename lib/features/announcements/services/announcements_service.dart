import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:pivot/features/home/screens/adminstration/models/announcement_data.dart';
import 'package:pivot/models/comment_data.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

class AnnouncementsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collectionPath = 'announcements';
  static const String _announcementsBoxName = 'announcementsBox';

  Future<List<AnnouncementData>> fetchAnnouncements({
    String? department,
    String? timeFilter,
    bool includeScheduledAndExpired = false,
  }) async {
    try {
      Query query = _firestore.collection(_collectionPath);

      // Apply filters
      if (department != null && department.isNotEmpty) {
        query = query.where('department', isEqualTo: department);
      }

      if (timeFilter != null && timeFilter.isNotEmpty) {
        final now = DateTime.now();
        DateTime startDate;

        switch (timeFilter) {
          case 'today':
            startDate = DateTime(now.year, now.month, now.day);
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

      final snapshot = await query.get();
      var announcements =
          snapshot.docs
              .map(
                (doc) => AnnouncementData.fromMap(
                  doc.data() as Map<String, dynamic>,
                  doc.id,
                ),
              )
              .toList();

      // TODO: Implement scheduled and expired announcement filtering
      // when includeScheduledAndExpired is false
      // This should filter out:
      // 1. Announcements with publishAt date in the future
      // 2. Announcements with expireAt date in the past
      // 3. Delete expired announcements from Firestore
      if (!includeScheduledAndExpired) {
        // For now, just return all announcements
        // Full implementation should be added later
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

      // Trigger notifications
      // TODO: Implement notification trigger
    } catch (e) {
      throw Exception('Failed to add announcement: $e');
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

      for (final imagePath in imagePaths) {
        final compressedImage = await FlutterImageCompress.compressWithFile(
          imagePath,
          quality: 85,
          minWidth: 800,
          minHeight: 600,
        );

        if (compressedImage != null) {
          // TODO: Implement image upload
          // final url = await StorageOptimizationService().uploadImage(
          //   compressedImage,
          //   'announcements/${DateTime.now().millisecondsSinceEpoch}_${imagePaths.indexOf(imagePath)}.jpg',
          // );
          // uploadedUrls.add(url);
          uploadedUrls.add('placeholder_url_${imagePaths.indexOf(imagePath)}');
        }
      }

      return uploadedUrls;
    } catch (e) {
      throw Exception('Failed to upload images: $e');
    }
  }

  Future<void> _cacheAnnouncements(List<AnnouncementData> announcements) async {
    try {
      final box = await Hive.openBox(_announcementsBoxName);
      final announcementsMap = announcements.map((a) => a.toMap()).toList();
      await box.put('announcements', announcementsMap);
      await box.close();
    } catch (e) {
      // Cache failure shouldn't break the app
      print('Failed to cache announcements: $e');
    }
  }

  Future<List<AnnouncementData>> _loadCachedAnnouncements() async {
    try {
      final box = await Hive.openBox(_announcementsBoxName);
      final cachedData = box.get('announcements') as List<dynamic>?;
      await box.close();

      if (cachedData != null) {
        return cachedData
            .map(
              (data) =>
                  AnnouncementData.fromMap(data as Map<String, dynamic>, ''),
            )
            .toList();
      }

      return [];
    } catch (e) {
      print('Failed to load cached announcements: $e');
      return [];
    }
  }
}
