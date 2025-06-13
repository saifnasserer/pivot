import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pivot/screens/section2/adminstration/models/announcement_data.dart';

class AnnouncementProvider with ChangeNotifier {

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collectionPath = 'announcements';

  List<AnnouncementData> _announcements = [];
  bool _isLoading = false;
  String? _currentDepartmentFilter;
  String? _currentTimeFilter;

  List<AnnouncementData> get announcements => _announcements;
  bool get isLoading => _isLoading;

  // Fetch announcements with optional department and time-based filters
  Future<void> fetchAnnouncements(
      {String? department, String? timeFilter}) async {
    _isLoading = true;
    _currentDepartmentFilter = department;
    _currentTimeFilter = timeFilter;
    // Notify listeners immediately of the loading state change.
    notifyListeners();

    try {
      Query query = _firestore
          .collection(_collectionPath)
          .orderBy('timestamp', descending: true);

      final String? departmentToFilter = department;

      // Apply department filter if one is needed for the query.
      if (departmentToFilter != null && departmentToFilter.isNotEmpty) {
        final departmentTag = 'اخبار قسم $departmentToFilter';
        query = query.where('tags', arrayContains: departmentTag);
      }

      // Apply time filter if one was requested.
      if (timeFilter != null && timeFilter.isNotEmpty) {
        final now = DateTime.now();
        DateTime? startDate;

        if (timeFilter == 'today') {
          startDate = DateTime(now.year, now.month, now.day);
        } else if (timeFilter == 'week') {
          final weekAgo = now.subtract(const Duration(days: 7));
          startDate = DateTime(weekAgo.year, weekAgo.month, weekAgo.day);
        }

        if (startDate != null) {
          query = query.where('timestamp', isGreaterThanOrEqualTo: startDate);
        }
      }

      final snapshot = await query.get();
      _announcements = snapshot.docs
          .map((doc) => AnnouncementData.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('[FETCH] Error fetching announcements: $e');
      _announcements = [];
    }

    _isLoading = false;
    notifyListeners();
  }

  // Add an announcement and refresh the list with the current filters
  Future<void> addAnnouncement(AnnouncementData announcement) async {
    try {
      final data = announcement.toJson();
      debugPrint('Saving announcement with tags: ${data['tags']}'); // Diagnostic print
      await _firestore.collection(_collectionPath).add(data);
      await fetchAnnouncements(
          department: _currentDepartmentFilter, timeFilter: _currentTimeFilter);
    } catch (e) {
      debugPrint('Error adding announcement: $e');
    }
  }

  // Update an announcement and refresh the list with the current filters
  Future<void> updateAnnouncement(AnnouncementData announcement) async {
    if (announcement.id == null) {
      debugPrint('Error: Announcement ID is null, cannot update.');
      return;
    }
    try {
      await _firestore
          .collection(_collectionPath)
          .doc(announcement.id)
          .update(announcement.toJson());
      await fetchAnnouncements(
          department: _currentDepartmentFilter, timeFilter: _currentTimeFilter);
    } catch (e) {
      debugPrint('Error updating announcement: $e');
    }
  }

  // Delete an announcement and refresh the list with the current filters
  Future<void> deleteAnnouncement(String announcementId) async {
    try {
      await _firestore.collection(_collectionPath).doc(announcementId).delete();
      await fetchAnnouncements(
          department: _currentDepartmentFilter, timeFilter: _currentTimeFilter);
    } catch (e) {
      debugPrint('Error deleting announcement: $e');
    }
  }
}

