import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class Bookmarks extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<String> _bookmarkIds = [];

  // Getter for the raw bookmark IDs, so other parts of the app can use them.
  List<String> get bookmarkIds => _bookmarkIds;

  Bookmarks() {
    _auth.authStateChanges().listen((user) {
      if (user != null) {
        _loadBookmarks();
      } else {
        _bookmarkIds.clear();
        notifyListeners();
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

    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (doc.exists && doc.data()!.containsKey('bookmarks')) {
        final ids = List<String>.from(doc.data()!['bookmarks'] as List);
        _bookmarkIds = ids;
      } else {
        _bookmarkIds = [];
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading bookmarks: $e');
      _bookmarkIds = []; // Reset on error
      notifyListeners();
    }
  }

  /// Toggles a bookmark's state for the current user using Firestore's array operators.
  Future<void> toggleBookmark(String announcementId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final isCurrentlyBookmarked = isBookmarked(announcementId);
    final userDocRef = _firestore.collection('users').doc(user.uid);

    if (isCurrentlyBookmarked) {
      _bookmarkIds.remove(announcementId);
      await userDocRef.update({
        'bookmarks': FieldValue.arrayRemove([announcementId]),
      });
      // Log unbookmark
      // await ActivityLogService().logAction(
      //   action: 'Announcement unbookmarked',
      //   details: 'Announcement ID: $announcementId',
      // );
    } else {
      _bookmarkIds.add(announcementId);
      await userDocRef.set({
        'bookmarks': FieldValue.arrayUnion([announcementId]),
      }, SetOptions(merge: true));
      // Log bookmark
      // await ActivityLogService().logAction(
      //   action: 'Announcement bookmarked',
      //   details: 'Announcement ID: $announcementId',
      // );
    }
    notifyListeners();
  }
}
