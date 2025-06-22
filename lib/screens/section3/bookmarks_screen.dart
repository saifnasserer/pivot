import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:pivot/providers/bookmarks.dart';
import 'package:pivot/responsive.dart';
import 'package:pivot/screens/section2/adminstration/models/announcement_data.dart';
import 'package:pivot/screens/section3/profile_widgets/bookmark_card.dart';
import 'package:provider/provider.dart';

class BookmarksScreen extends StatelessWidget {
  const BookmarksScreen({super.key});

  // Fetches announcements and re-orders them to match the bookmarking order.
  Future<List<AnnouncementData>> _fetchBookmarkedAnnouncements(
    List<String> ids,
  ) async {
    if (ids.isEmpty) {
      return [];
    }

    final announcementsRef = FirebaseFirestore.instance.collection(
      'announcements',
    );
    final List<AnnouncementData> fetchedAnnouncements = [];

    // Chunk the IDs into lists of 10 to respect Firestore's 'whereIn' limit.
    for (var i = 0; i < ids.length; i += 10) {
      final chunk = ids.sublist(i, i + 10 > ids.length ? ids.length : i + 10);
      final querySnapshot =
          await announcementsRef
              .where(FieldPath.documentId, whereIn: chunk)
              .get();
      for (var doc in querySnapshot.docs) {
        fetchedAnnouncements.add(AnnouncementData.fromFirestore(doc));
      }
    }

    // Re-order the fetched announcements to match the order of the bookmark IDs.
    final announcementsMap = {
      for (var announcement in fetchedAnnouncements)
        announcement.id: announcement,
    };
    final sortedAnnouncements =
        ids
            .map((id) => announcementsMap[id])
            .where((announcement) => announcement != null)
            .cast<AnnouncementData>()
            .toList();

    return sortedAnnouncements;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<Bookmarks>(
      builder: (context, bookmarksProvider, child) {
        // Reverse the list of IDs to show the most recently bookmarked first.
        final bookmarkIds = bookmarksProvider.bookmarkIds.reversed.toList();

        if (bookmarkIds.isEmpty) {
          return Center(
            child: Text(
              'مفيش محفوظات',
              style: TextStyle(
                fontSize: Responsive.text(context, size: TextSize.heading),
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
              textDirection: TextDirection.rtl,
            ),
          );
        }

        return FutureBuilder<List<AnnouncementData>>(
          future: _fetchBookmarkedAnnouncements(bookmarkIds),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(
                child: Text(
                  'حدث خطأ أثناء تحميل المحفوظات',
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: Responsive.text(context, size: TextSize.medium),
                  ),
                  textDirection: TextDirection.rtl,
                ),
              );
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(
                child: Text(
                  'مفيش محفوظات',
                  style: TextStyle(
                    fontSize: Responsive.text(context, size: TextSize.heading),
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[600],
                  ),
                  textDirection: TextDirection.rtl,
                ),
              );
            }

            final bookmarkedItems = snapshot.data!;
            return ListView.builder(
              padding: EdgeInsets.symmetric(
                vertical: Responsive.space(context, size: Space.medium),
              ),
              itemCount: bookmarkedItems.length,
              itemBuilder: (context, index) {
                final bookmark = bookmarkedItems[index];
                return BookmarkCard(
                  bookmark: bookmark,
                  onRemove: () {
                    if (bookmark.id != null) {
                      bookmarksProvider.toggleBookmark(bookmark.id!);
                    }
                  },
                );
              },
            );
          },
        );
      },
    );
  }
}
