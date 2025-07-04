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
      //debugprint('Error loading bookmarks: $e');
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

    // Update UI immediately for better responsiveness
    if (isCurrentlyBookmarked) {
      _bookmarkIds.remove(announcementId);
    } else {
      _bookmarkIds.add(announcementId);
    }
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
    } catch (e) {
      // Revert local state if Firestore operation fails
      //debugprint('Error toggling bookmark: $e');
      if (isCurrentlyBookmarked) {
        _bookmarkIds.add(announcementId);
      } else {
        _bookmarkIds.remove(announcementId);
      }
      notifyListeners();

      // You might want to show a snackbar or toast here to inform the user
      // ScaffoldMessenger.of(context).showSnackBar(
      //   SnackBar(content: Text('فشل في تحديث المحفظات')),
      // );
    }
  }
}
