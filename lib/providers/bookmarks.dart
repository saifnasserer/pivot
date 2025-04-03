import 'package:flutter/foundation.dart';
import 'package:pivot/screens/section2/adminstration/models/announcement_data.dart';

class Bookmarks extends ChangeNotifier {
  final List<AnnouncementData> _bookmarks = [];

  List<AnnouncementData> get bookmarks => _bookmarks;

  bool isBookmarked(AnnouncementData item) {
    return _bookmarks.any((b) => b.title == item.title && b.description == item.description);
  }

  void addBookmark(AnnouncementData item) {
    if (!isBookmarked(item)) {
      _bookmarks.add(item);
      notifyListeners();
    }
  }

  void removeBookmark(AnnouncementData item) {
    _bookmarks.removeWhere((b) => b.title == item.title && b.description == item.description);
    notifyListeners();
  }
}
