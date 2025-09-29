import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BookmarksService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get user's bookmarks
  Future<List<String>> getUserBookmarks() async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (!doc.exists) return [];

      final data = doc.data()!;
      final bookmarks = data['bookmarks'] as List<dynamic>? ?? [];
      return bookmarks.cast<String>();
    } catch (e) {
      throw Exception('Failed to fetch user bookmarks: $e');
    }
  }

  // Check if item is bookmarked
  Future<bool> isBookmarked(String itemId) async {
    try {
      final bookmarks = await getUserBookmarks();
      return bookmarks.contains(itemId);
    } catch (e) {
      return false;
    }
  }

  // Add bookmark
  Future<bool> addBookmark(String itemId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      await _firestore.collection('users').doc(user.uid).update({
        'bookmarks': FieldValue.arrayUnion([itemId]),
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      throw Exception('Failed to add bookmark: $e');
    }
  }

  // Remove bookmark
  Future<bool> removeBookmark(String itemId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      await _firestore.collection('users').doc(user.uid).update({
        'bookmarks': FieldValue.arrayRemove([itemId]),
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      throw Exception('Failed to remove bookmark: $e');
    }
  }

  // Toggle bookmark
  Future<bool> toggleBookmark(String itemId) async {
    try {
      final isCurrentlyBookmarked = await isBookmarked(itemId);
      if (isCurrentlyBookmarked) {
        return await removeBookmark(itemId);
      } else {
        return await addBookmark(itemId);
      }
    } catch (e) {
      throw Exception('Failed to toggle bookmark: $e');
    }
  }

  // Add multiple bookmarks
  Future<bool> addMultipleBookmarks(List<String> itemIds) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      await _firestore.collection('users').doc(user.uid).update({
        'bookmarks': FieldValue.arrayUnion(itemIds),
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      throw Exception('Failed to add multiple bookmarks: $e');
    }
  }

  // Remove multiple bookmarks
  Future<bool> removeMultipleBookmarks(List<String> itemIds) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      await _firestore.collection('users').doc(user.uid).update({
        'bookmarks': FieldValue.arrayRemove(itemIds),
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      throw Exception('Failed to remove multiple bookmarks: $e');
    }
  }

  // Clear all bookmarks
  Future<bool> clearAllBookmarks() async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      await _firestore.collection('users').doc(user.uid).update({
        'bookmarks': [],
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      throw Exception('Failed to clear all bookmarks: $e');
    }
  }

  // Get bookmarked items with details
  Future<List<Map<String, dynamic>>> getBookmarkedItemsDetails() async {
    try {
      final bookmarks = await getUserBookmarks();
      if (bookmarks.isEmpty) return [];

      List<Map<String, dynamic>> items = [];

      // Get announcements
      final announcementsSnapshot =
          await _firestore
              .collection('announcements')
              .where(FieldPath.documentId, whereIn: bookmarks)
              .get();

      for (var doc in announcementsSnapshot.docs) {
        final data = doc.data();
        items.add({
          'id': doc.id,
          'type': 'announcement',
          'title': data['title'] ?? '',
          'content': data['content'] ?? '',
          'createdAt': data['createdAt'],
          'author': data['author'] ?? '',
        });
      }

      // Get subjects
      final subjectsSnapshot =
          await _firestore
              .collection('subjects')
              .where(FieldPath.documentId, whereIn: bookmarks)
              .get();

      for (var doc in subjectsSnapshot.docs) {
        final data = doc.data();
        items.add({
          'id': doc.id,
          'type': 'subject',
          'title': data['name'] ?? '',
          'description': data['description'] ?? '',
          'createdAt': data['createdAt'],
          'department': data['department'] ?? '',
        });
      }

      // Get tasks
      final user = _auth.currentUser;
      if (user != null) {
        final tasksSnapshot =
            await _firestore
                .collection('users')
                .doc(user.uid)
                .collection('tasks')
                .where(FieldPath.documentId, whereIn: bookmarks)
                .get();

        for (var doc in tasksSnapshot.docs) {
          final data = doc.data();
          items.add({
            'id': doc.id,
            'type': 'task',
            'title': data['title'] ?? '',
            'description': data['description'] ?? '',
            'dueDate': data['dueDate'],
            'importance': data['importance'] ?? 'mid',
          });
        }
      }

      return items;
    } catch (e) {
      throw Exception('Failed to fetch bookmarked items details: $e');
    }
  }

  // Search bookmarks
  Future<List<String>> searchBookmarks(String query) async {
    try {
      final bookmarks = await getUserBookmarks();
      if (query.isEmpty) return bookmarks;

      final lowercaseQuery = query.toLowerCase();
      return bookmarks.where((bookmark) {
        return bookmark.toLowerCase().contains(lowercaseQuery);
      }).toList();
    } catch (e) {
      throw Exception('Failed to search bookmarks: $e');
    }
  }

  // Get bookmarks by type
  Future<List<String>> getBookmarksByType(String type) async {
    try {
      final items = await getBookmarkedItemsDetails();
      return items
          .where((item) => item['type'] == type)
          .map((item) => item['id'] as String)
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch bookmarks by type: $e');
    }
  }

  // Get bookmarks statistics
  Future<Map<String, dynamic>> getBookmarksStatistics() async {
    try {
      final bookmarks = await getUserBookmarks();
      final items = await getBookmarkedItemsDetails();

      Map<String, int> typeCounts = {};
      for (var item in items) {
        final type = item['type'] as String;
        typeCounts[type] = (typeCounts[type] ?? 0) + 1;
      }

      return {
        'totalBookmarks': bookmarks.length,
        'typeCounts': typeCounts,
        'announcementsCount': typeCounts['announcement'] ?? 0,
        'subjectsCount': typeCounts['subject'] ?? 0,
        'tasksCount': typeCounts['task'] ?? 0,
        'hasBookmarks': bookmarks.isNotEmpty,
      };
    } catch (e) {
      throw Exception('Failed to fetch bookmarks statistics: $e');
    }
  }

  // Export bookmarks
  Future<Map<String, dynamic>> exportBookmarks() async {
    try {
      final bookmarks = await getUserBookmarks();
      final items = await getBookmarkedItemsDetails();

      return {
        'bookmarks': bookmarks,
        'items': items,
        'exportDate': DateTime.now().toIso8601String(),
        'version': '1.0',
      };
    } catch (e) {
      throw Exception('Failed to export bookmarks: $e');
    }
  }

  // Import bookmarks
  Future<bool> importBookmarks(List<String> bookmarkIds) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      await _firestore.collection('users').doc(user.uid).update({
        'bookmarks': bookmarkIds,
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      throw Exception('Failed to import bookmarks: $e');
    }
  }

  // Sync bookmarks (merge with existing)
  Future<bool> syncBookmarks(List<String> newBookmarks) async {
    try {
      final currentBookmarks = await getUserBookmarks();
      final mergedBookmarks = {...currentBookmarks, ...newBookmarks}.toList();

      return await importBookmarks(mergedBookmarks);
    } catch (e) {
      throw Exception('Failed to sync bookmarks: $e');
    }
  }
}
