import 'package:flutter/material.dart';
import 'package:pivot/screens/section2/adminstration/models/announcement_data.dart';

class AnnouncementProvider extends ChangeNotifier {
  final List<AnnouncementData> _announcements = [];

  List<AnnouncementData> get announcements => _announcements;

  void addAnnouncement(AnnouncementData announcement) {
    _announcements.add(announcement);
    notifyListeners();
  }

  void updateAnnouncement(int index, AnnouncementData announcement) {
    if (index >= 0 && index < _announcements.length) {
      _announcements[index] = announcement;
      notifyListeners();
    }
  }

  void deleteAnnouncement(int index) {
    if (index >= 0 && index < _announcements.length) {
      _announcements.removeAt(index);
      notifyListeners();
    }
  }
}
