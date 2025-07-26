import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Enhanced Bookmarks provider with better state management and functionality
class Bookmarks extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<String> _bookmarkIds = [];
  bool _isLoading = false;
  String? _error;
  DateTime? _lastUpdated;

  // Getters
  List<String> get bookmarkIds => List.unmodifiable(_bookmarkIds);
  bool get isLoading => _isLoading;
  String? get error => _error;
  DateTime? get lastUpdated => _lastUpdated;
  int get bookmarkCount => _bookmarkIds.length;
  bool get hasBookmarks => _bookmarkIds.isNotEmpty;

  Bookmarks() {
    _auth.authStateChanges().listen((user) {
      if (user != null) {
        _loadBookmarks();
      } else {
        _clearBookmarks();
      }
    });
  }

  /// Checks if a specific announcement is bookmarked by its ID.
  bool isBookmarked(String announcementId) {
    return _bookmarkIds.contains(announcementId);
  }

  /// Loads the current user's bookmark IDs from their user document in Firestore.
  Future<void> _loadBookmarks() async {
    final user = _auth.currentUser;
    if (user == null) return;

    _setLoading(true);
    _clearError();

    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();

      if (doc.exists && doc.data()!.containsKey('bookmarks')) {
        final ids = List<String>.from(doc.data()!['bookmarks'] as List);
        _bookmarkIds = ids;
        _lastUpdated = DateTime.now();
      } else {
        _bookmarkIds = [];
        _lastUpdated = DateTime.now();
      }

      notifyListeners();
    } catch (e) {
      _setError('فشل في تحميل المحفظات: $e');
      _bookmarkIds = []; // Reset on error
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  /// Toggles a bookmark's state for the current user using Firestore's array operators.
  Future<bool> toggleBookmark(String announcementId) async {
    final user = _auth.currentUser;
    if (user == null) {
      _setError('يجب تسجيل الدخول أولاً');
      return false;
    }

    final isCurrentlyBookmarked = isBookmarked(announcementId);
    final userDocRef = _firestore.collection('users').doc(user.uid);

    // Update UI immediately for better responsiveness
    if (isCurrentlyBookmarked) {
      _bookmarkIds.remove(announcementId);
    } else {
      _bookmarkIds.add(announcementId);
    }
    _lastUpdated = DateTime.now();
    notifyListeners();

    // Handle Firestore operation in background
    try {
      if (isCurrentlyBookmarked) {
        await userDocRef.update({
          'bookmarks': FieldValue.arrayRemove([announcementId]),
        });
        // Log unbookmark
        // await ActivityLogService().logAction(
        //   action: 'Announcement unbookmarked',
        //   details: 'Announcement ID: $announcementId',
        // );
      } else {
        await userDocRef.set({
          'bookmarks': FieldValue.arrayUnion([announcementId]),
        }, SetOptions(merge: true));
        // Log bookmark
        // await ActivityLogService().logAction(
        //   action: 'Announcement bookmarked',
        //   details: 'Announcement ID: $announcementId',
        // );
      }

      _clearError();
      return true;
    } catch (e) {
      // Revert local state if Firestore operation fails
      _setError('فشل في تحديث المحفظات: $e');

      if (isCurrentlyBookmarked) {
        _bookmarkIds.add(announcementId);
      } else {
        _bookmarkIds.remove(announcementId);
      }
      notifyListeners();
      return false;
    }
  }

  /// Bulk add multiple bookmarks
  Future<bool> addMultipleBookmarks(List<String> announcementIds) async {
    final user = _auth.currentUser;
    if (user == null) {
      _setError('يجب تسجيل الدخول أولاً');
      return false;
    }

    _setLoading(true);
    _clearError();

    try {
      final userDocRef = _firestore.collection('users').doc(user.uid);

      // Add to local state
      for (final id in announcementIds) {
        if (!_bookmarkIds.contains(id)) {
          _bookmarkIds.add(id);
        }
      }
      _lastUpdated = DateTime.now();
      notifyListeners();

      // Update Firestore
      await userDocRef.set({
        'bookmarks': FieldValue.arrayUnion(announcementIds),
      }, SetOptions(merge: true));

      _clearError();
      return true;
    } catch (e) {
      _setError('فشل في إضافة المحفظات: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Bulk remove multiple bookmarks
  Future<bool> removeMultipleBookmarks(List<String> announcementIds) async {
    final user = _auth.currentUser;
    if (user == null) {
      _setError('يجب تسجيل الدخول أولاً');
      return false;
    }

    _setLoading(true);
    _clearError();

    try {
      final userDocRef = _firestore.collection('users').doc(user.uid);

      // Remove from local state
      for (final id in announcementIds) {
        _bookmarkIds.remove(id);
      }
      _lastUpdated = DateTime.now();
      notifyListeners();

      // Update Firestore
      await userDocRef.update({
        'bookmarks': FieldValue.arrayRemove(announcementIds),
      });

      _clearError();
      return true;
    } catch (e) {
      _setError('فشل في إزالة المحفظات: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Clear all bookmarks
  Future<bool> clearAllBookmarks() async {
    final user = _auth.currentUser;
    if (user == null) {
      _setError('يجب تسجيل الدخول أولاً');
      return false;
    }

    _setLoading(true);
    _clearError();

    try {
      final userDocRef = _firestore.collection('users').doc(user.uid);

      // Clear local state
      _bookmarkIds.clear();
      _lastUpdated = DateTime.now();
      notifyListeners();

      // Update Firestore
      await userDocRef.update({'bookmarks': []});

      _clearError();
      return true;
    } catch (e) {
      _setError('فشل في مسح المحفظات: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Refresh bookmarks from server
  Future<void> refreshBookmarks() async {
    await _loadBookmarks();
  }

  /// Get bookmarks that match a search query
  List<String> searchBookmarks(
    String query,
    List<Map<String, dynamic>> announcements,
  ) {
    if (query.isEmpty) return _bookmarkIds;

    final lowercaseQuery = query.toLowerCase();
    final matchingIds = <String>[];

    for (final announcement in announcements) {
      final id = announcement['id'] as String?;
      if (id != null && _bookmarkIds.contains(id)) {
        final title = (announcement['title'] as String? ?? '').toLowerCase();
        final description =
            (announcement['description'] as String? ?? '').toLowerCase();

        if (title.contains(lowercaseQuery) ||
            description.contains(lowercaseQuery)) {
          matchingIds.add(id);
        }
      }
    }

    return matchingIds;
  }

  /// Get recently added bookmarks (last N items)
  List<String> getRecentBookmarks(int count) {
    if (count <= 0) return [];
    return _bookmarkIds.take(count).toList();
  }

  /// Check if bookmarks have been updated recently
  bool get isRecentlyUpdated {
    if (_lastUpdated == null) return false;
    final difference = DateTime.now().difference(_lastUpdated!);
    return difference.inMinutes < 5; // Consider "recent" if within 5 minutes
  }

  // Private helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }

  void _clearBookmarks() {
    _bookmarkIds.clear();
    _error = null;
    _isLoading = false;
    _lastUpdated = null;
    notifyListeners();
  }
}
