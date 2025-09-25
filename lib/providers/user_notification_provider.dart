import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pivot/models/user_notification.dart';

class UserNotificationProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<UserNotification> _notifications = [];
  bool _isLoading = false;
  String? _error;
  int _unreadCount = 0;

  List<UserNotification> get notifications => _notifications;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get unreadCount => _unreadCount;

  Future<void> fetchNotifications() async {
    final user = _auth.currentUser;
    if (user == null) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final snapshot =
          await _firestore
              .collection('users')
              .doc(user.uid)
              .collection('notifications')
              .orderBy('createdAt', descending: true)
              .limit(50)
              .get();

      _notifications =
          snapshot.docs
              .map((doc) => UserNotification.fromFirestore(doc))
              .toList();

      _updateUnreadCount();
    } catch (e) {
      _error = "Failed to load notifications: $e";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> markAsRead(String notificationId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('notifications')
          .doc(notificationId)
          .update({'isRead': true});

      final index = _notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1 && !_notifications[index].isRead) {
        final updatedNotification = UserNotification(
          id: _notifications[index].id,
          title: _notifications[index].title,
          body: _notifications[index].body,
          createdAt: _notifications[index].createdAt,
          isRead: true,
          data: _notifications[index].data,
        );
        _notifications[index] = updatedNotification;
        _updateUnreadCount();
        notifyListeners();
      }
    } catch (e) {}
  }

  Future<void> markAllAsRead() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final unreadIds =
        _notifications.where((n) => !n.isRead).map((n) => n.id).toList();

    if (unreadIds.isEmpty) return;

    try {
      final batch = _firestore.batch();
      for (String id in unreadIds) {
        final docRef = _firestore
            .collection('users')
            .doc(user.uid)
            .collection('notifications')
            .doc(id);
        batch.update(docRef, {'isRead': true});
      }
      await batch.commit();

      // Update local state
      _notifications =
          _notifications.map((n) {
            if (!n.isRead) {
              return UserNotification(
                id: n.id,
                title: n.title,
                body: n.body,
                createdAt: n.createdAt,
                isRead: true,
                data: n.data,
              );
            }
            return n;
          }).toList();

      _updateUnreadCount();
      notifyListeners();
    } catch (e) {}
  }

  void _updateUnreadCount() {
    _unreadCount = _notifications.where((n) => !n.isRead).length;
  }
}
