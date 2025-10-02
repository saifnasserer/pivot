import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pivot/features/announcements/services/announcements_service.dart';
import 'package:pivot/features/home/screens/adminstration/models/announcement_data.dart';
import 'package:pivot/models/comment_data.dart';

class AnnouncementsRepository {
  AnnouncementsRepository(this._service);

  final AnnouncementsService _service;

  Future<List<AnnouncementData>> fetchAnnouncements({
    String? department,
    String? timeFilter,
    String? userLevel,
    bool includeScheduledAndExpired = false,
    int limit = 10,
    DocumentSnapshot? startAfterDocument,
  }) => _service.fetchAnnouncements(
    department: department,
    timeFilter: timeFilter,
    userLevel: userLevel,
    includeScheduledAndExpired: includeScheduledAndExpired,
    limit: limit,
    startAfterDocument: startAfterDocument,
  );

  DocumentSnapshot? getLastDocument() => _service.lastDocument;

  Future<void> addAnnouncement(AnnouncementData announcement) =>
      _service.addAnnouncement(announcement);

  Future<void> updateAnnouncement(String id, AnnouncementData announcement) =>
      _service.updateAnnouncement(id, announcement);

  Future<void> deleteAnnouncement(String id) => _service.deleteAnnouncement(id);

  Future<void> togglePin(String id) => _service.togglePin(id);

  Future<void> addComment(String announcementId, CommentData comment) =>
      _service.addComment(announcementId, comment);

  Future<void> deleteComment(String announcementId, String commentId) =>
      _service.deleteComment(announcementId, commentId);

  Future<List<CommentData>> getComments(String announcementId) =>
      _service.getComments(announcementId);

  Future<List<CommentData>> getCommentsForAnnouncement(String announcementId) =>
      _service.getComments(announcementId);

  Future<void> likeComment(
    String announcementId,
    String commentId,
    String userId,
  ) => _service.likeComment(announcementId, commentId, userId);

  Future<void> replyToComment(
    String announcementId,
    String parentCommentId,
    CommentData reply,
  ) => _service.replyToComment(announcementId, parentCommentId, reply);

  Future<void> updateComment(
    String announcementId,
    String commentId,
    String newContent,
  ) => _service.updateComment(announcementId, commentId, newContent);

  Future<List<String>> uploadImages(List<String> imagePaths) =>
      _service.uploadImages(imagePaths);
}
