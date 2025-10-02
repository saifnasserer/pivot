import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:pivot/features/home/screens/adminstration/models/announcement_data.dart';
import 'package:pivot/models/comment_data.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:pivot/services/cache_service.dart';

class AnnouncementsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final String _collectionPath = 'announcements';

  Future<List<AnnouncementData>> fetchAnnouncements({
    String? department,
    String? timeFilter,
    bool includeScheduledAndExpired = false,
  }) async {
    print(
      '🔍 [AnnouncementsService] Starting fetch with department: $department, timeFilter: $timeFilter',
    );
    try {
      Query query = _firestore.collection(_collectionPath);

      // Apply filters
      if (department != null && department.isNotEmpty) {
        print(
          '🔍 [AnnouncementsService] Adding department filter: $department',
        );

        // Handle special case for today's news with mixed department content
        if (department.startsWith('today_mixed:')) {
          // For today's news, get the user's department and filter by it
          final userDepartment = department.replaceFirst('today_mixed:', '');
          print(
            '🔍 [AnnouncementsService] Today mixed department: $userDepartment',
          );
          query = query.where('tags', arrayContains: userDepartment);
        } else {
          // Filter by tags array (original working approach)
          print(
            '🔍 [AnnouncementsService] Regular department filter: $department',
          );
          query = query.where('tags', arrayContains: department);
        }
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

      print(
        '🔍 [AnnouncementsService] Query returned ${announcements.length} announcements',
      );

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
      print('📝 [AnnouncementsService] Creating announcement with:');
      print('   - Title: ${announcement.title}');
      print('   - Department: ${announcement.department}');
      print('   - Tags: ${announcement.tags}');
      print('   - Timestamp: ${announcement.timestamp}');

      final docRef = await _firestore
          .collection(_collectionPath)
          .add(announcement.toMap());

      // Update with generated ID
      await docRef.update({'id': docRef.id});

      print(
        '✅ [AnnouncementsService] Announcement created with ID: ${docRef.id}',
      );

      // Trigger notifications
      // TODO: Implement notification trigger
    } catch (e) {
      print('❌ [AnnouncementsService] Error creating announcement: $e');
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
      // First, get the announcement to retrieve image URLs
      final announcementDoc =
          await _firestore.collection(_collectionPath).doc(id).get();

      if (announcementDoc.exists) {
        final data = announcementDoc.data();
        final imageUrls =
            (data?['imageUrls'] as List<dynamic>?)?.cast<String>() ?? [];

        // Delete all associated images from Firebase Storage
        if (imageUrls.isNotEmpty) {
          print('🗑️ Deleting ${imageUrls.length} images for announcement $id');
          for (final imageUrl in imageUrls) {
            try {
              // Skip placeholder URLs
              if (imageUrl.startsWith('placeholder_')) {
                print('⚠️ Skipping placeholder URL: $imageUrl');
                continue;
              }

              // Extract the storage path from the URL
              final ref = _storage.refFromURL(imageUrl);
              await ref.delete();
              print('✅ Deleted image: ${ref.fullPath}');
            } catch (e) {
              // Continue deleting other images even if one fails
              print('⚠️ Failed to delete image: $imageUrl - $e');
            }
          }
        }
      }

      // Delete the Firestore document
      await _firestore.collection(_collectionPath).doc(id).delete();
      print('✅ Deleted announcement $id from Firestore');
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
            print('✅ Announcement image uploaded: $downloadUrl');
          } else {
            print('❌ Upload failed for image $i');
          }
        }
      }

      return uploadedUrls;
    } catch (e) {
      print('❌ Error uploading announcement images: $e');
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
}
