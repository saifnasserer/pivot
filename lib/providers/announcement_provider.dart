import 'package:flutter/material.dart';
import 'package:pivot/screens/section2/adminstration/models/announcement_data.dart';

class AnnouncementProvider extends ChangeNotifier {
  // List to store all announcements
  final List<AnnouncementData> _announcements = [
    // Initial example data
    // AnnouncementData(
    //   title: 'محاضرة دكتور احمد',
    //   date: '30/3',
    //   color: const Color(0xffff5252),
    //   description: 'محاضرة في قاعة 5 الساعة 10 صباحا',
    //   tags: ['اخبار النهاردة', 'اخبار قسم CS'],
    // ),
    // AnnouncementData(
    //   title: 'سكشن هندسة البرمجيات',
    //   date: '1/4',
    //   color: const Color(0xFFFFEF86),
    //   description: 'سكشن في معمل 3 الساعة 2 مساء',
    //   tags: ['اخبار الاسبوع', 'اخبار قسم CS'],
    // ),
    // AnnouncementData(
    //   title: 'امتحان نصف الترم',
    //   date: '15/4',
    //   color: const Color(0xFF99F16C),
    //   description: 'امتحان في مدرج 2 الساعة 9 صباحا',
    //   tags: ['اخبار قسم SC', 'اخبار قسم AI', 'اخبار قسم CS', 'اخبار قسم IS'],
    // ),
  ];

  // Getter to access the announcements list
  List<AnnouncementData> get announcements => _announcements;

  // Add a new announcement
  void addAnnouncement(AnnouncementData announcement) {
    _announcements.add(announcement);
    notifyListeners();
  }

  // Update an existing announcement
  void updateAnnouncement(int index, AnnouncementData announcement) {
    if (index >= 0 && index < _announcements.length) {
      _announcements[index] = announcement;
      notifyListeners();
    }
  }

  // Delete an announcement
  void deleteAnnouncement(int index) {
    if (index >= 0 && index < _announcements.length) {
      _announcements.removeAt(index);
      notifyListeners();
    }
  }
}
