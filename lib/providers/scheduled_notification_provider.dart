import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pivot/models/scheduled_notification.dart';
import 'package:pivot/services/notification_service.dart';

class ScheduledNotificationProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NotificationService _notificationService = NotificationService();

  List<ScheduledNotification> _scheduledNotifications = [];
  bool _isLoading = false;
  String? _error;

  List<ScheduledNotification> get scheduledNotifications =>
      _scheduledNotifications;
  bool get isLoading => _isLoading;
  String? get error => _error;

  List<ScheduledNotification> get pendingNotifications =>
      _scheduledNotifications.where((n) => n.isPending).toList();

  List<ScheduledNotification> get sentNotifications =>
      _scheduledNotifications.where((n) => n.isSent).toList();

  List<ScheduledNotification> get overdueNotifications =>
      _scheduledNotifications.where((n) => n.isOverdue).toList();

  // Fetch all scheduled notifications
  Future<void> fetchScheduledNotifications() async {
    _setLoading(true);
    try {
      final querySnapshot =
          await _firestore
              .collection('scheduledNotifications')
              .orderBy('scheduledTime', descending: false)
              .get();

      _scheduledNotifications =
          querySnapshot.docs
              .map(
                (doc) => ScheduledNotification.fromJson({
                  'id': doc.id,
                  ...doc.data(),
                }),
              )
              .toList();

      _error = null;
    } catch (e) {
      _error = 'فشل في تحميل الإشعارات المجدولة: $e';
      debugPrint('Error fetching scheduled notifications: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Create a new scheduled notification
  Future<bool> createScheduledNotification(
    ScheduledNotification notification,
  ) async {
    try {
      final docRef = await _firestore
          .collection('scheduledNotifications')
          .add(notification.toJson());

      final newNotification = notification.copyWith(id: docRef.id);
      _scheduledNotifications.add(newNotification);
      _scheduledNotifications.sort(
        (a, b) => a.scheduledTime.compareTo(b.scheduledTime),
      );

      notifyListeners();
      return true;
    } catch (e) {
      _error = 'فشل في إنشاء الإشعار المجدول: $e';
      debugPrint('Error creating scheduled notification: $e');
      notifyListeners();
      return false;
    }
  }

  // Update a scheduled notification
  Future<bool> updateScheduledNotification(
    ScheduledNotification notification,
  ) async {
    if (notification.id == null) return false;

    try {
      await _firestore
          .collection('scheduledNotifications')
          .doc(notification.id)
          .update(notification.toJson());

      final index = _scheduledNotifications.indexWhere(
        (n) => n.id == notification.id,
      );
      if (index != -1) {
        _scheduledNotifications[index] = notification;
        _scheduledNotifications.sort(
          (a, b) => a.scheduledTime.compareTo(b.scheduledTime),
        );
        notifyListeners();
      }
      return true;
    } catch (e) {
      _error = 'فشل في تحديث الإشعار المجدول: $e';
      debugPrint('Error updating scheduled notification: $e');
      notifyListeners();
      return false;
    }
  }

  // Cancel a scheduled notification
  Future<bool> cancelScheduledNotification(String notificationId) async {
    try {
      await _firestore
          .collection('scheduledNotifications')
          .doc(notificationId)
          .update({
            'status': 'cancelled',
            'sentAt': FieldValue.serverTimestamp(),
          });

      final index = _scheduledNotifications.indexWhere(
        (n) => n.id == notificationId,
      );
      if (index != -1) {
        _scheduledNotifications[index] = _scheduledNotifications[index]
            .copyWith(status: 'cancelled', sentAt: DateTime.now());
        notifyListeners();
      }
      return true;
    } catch (e) {
      _error = 'فشل في إلغاء الإشعار المجدول: $e';
      debugPrint('Error cancelling scheduled notification: $e');
      notifyListeners();
      return false;
    }
  }

  // Delete a scheduled notification
  Future<bool> deleteScheduledNotification(String notificationId) async {
    try {
      await _firestore
          .collection('scheduledNotifications')
          .doc(notificationId)
          .delete();

      _scheduledNotifications.removeWhere((n) => n.id == notificationId);
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'فشل في حذف الإشعار المجدول: $e';
      debugPrint('Error deleting scheduled notification: $e');
      notifyListeners();
      return false;
    }
  }

  // Send a scheduled notification immediately
  Future<bool> sendScheduledNotificationNow(
    ScheduledNotification notification,
  ) async {
    try {
      List<String> tokens = [];

      if (notification.sendToAllUsers) {
        tokens = await _notificationService.getAllUserFCMTokens();
      } else {
        tokens = await _notificationService.getMultipleUserFCMTokens(
          notification.targetUserIds,
        );
      }

      if (tokens.isEmpty) {
        await _updateNotificationStatus(
          notification.id!,
          'failed',
          errorMessage: 'لا توجد رموز FCM صالحة',
        );
        return false;
      }

      int successCount = 0;
      for (String token in tokens) {
        final success = await _notificationService.sendNotification(
          targetToken: token,
          title: notification.title,
          body: notification.body,
        );
        if (success) successCount++;
      }

      final newStatus = successCount > 0 ? 'sent' : 'failed';
      final errorMessage =
          successCount == 0 ? 'فشل في إرسال جميع الإشعارات' : null;

      await _updateNotificationStatus(
        notification.id!,
        newStatus,
        sentCount: successCount,
        totalCount: tokens.length,
        errorMessage: errorMessage,
      );

      return successCount > 0;
    } catch (e) {
      await _updateNotificationStatus(
        notification.id!,
        'failed',
        errorMessage: 'خطأ في إرسال الإشعار: $e',
      );
      return false;
    }
  }

  // Update notification status
  Future<void> _updateNotificationStatus(
    String notificationId,
    String status, {
    int? sentCount,
    int? totalCount,
    String? errorMessage,
  }) async {
    try {
      final updateData = {
        'status': status,
        'sentAt': FieldValue.serverTimestamp(),
      };

      if (sentCount != null) updateData['sentCount'] = sentCount;
      if (totalCount != null) updateData['totalCount'] = totalCount;
      if (errorMessage != null) updateData['errorMessage'] = errorMessage;

      await _firestore
          .collection('scheduledNotifications')
          .doc(notificationId)
          .update(updateData);

      final index = _scheduledNotifications.indexWhere(
        (n) => n.id == notificationId,
      );
      if (index != -1) {
        _scheduledNotifications[index] = _scheduledNotifications[index]
            .copyWith(
              status: status,
              sentAt: DateTime.now(),
              sentCount: sentCount,
              totalCount: totalCount,
              errorMessage: errorMessage,
            );
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error updating notification status: $e');
    }
  }

  // Process due notifications (called by background service)
  Future<void> processDueNotifications() async {
    final now = DateTime.now();
    final dueNotifications =
        _scheduledNotifications
            .where((n) => n.isPending && n.scheduledTime.isBefore(now))
            .toList();

    for (final notification in dueNotifications) {
      await sendScheduledNotificationNow(notification);
    }
  }

  // Get notifications by status
  List<ScheduledNotification> getNotificationsByStatus(String status) {
    return _scheduledNotifications.where((n) => n.status == status).toList();
  }

  // Get notifications by creator
  List<ScheduledNotification> getNotificationsByCreator(String creatorId) {
    return _scheduledNotifications
        .where((n) => n.createdBy == creatorId)
        .toList();
  }

  // Get notifications scheduled between dates
  List<ScheduledNotification> getNotificationsBetweenDates(
    DateTime start,
    DateTime end,
  ) {
    return _scheduledNotifications
        .where(
          (n) =>
              n.scheduledTime.isAfter(start) && n.scheduledTime.isBefore(end),
        )
        .toList();
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
}
