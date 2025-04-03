import 'package:flutter/material.dart';
import 'package:pivot/screens/section2/adminstration/models/announcement_data.dart';
import 'package:provider/provider.dart';
import 'package:pivot/providers/bookmarks.dart';
import 'package:pivot/screens/models/card_model.dart';
import 'package:pivot/responsive.dart';

// Function to build the slivers for bookmarks
List<Widget> buildBookmarksSlivers(BuildContext context) {
  final bookmarksProvider = Provider.of<Bookmarks>(context, listen: false);
  final List<AnnouncementData> bookmarkedItems = bookmarksProvider.bookmarks;

  // If no bookmarks, return a SliverFillRemaining with the message
  if (bookmarkedItems.isEmpty) {
    return [
      SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: Text(
            'لا توجد عناصر محفوظة',
            style: TextStyle(
              fontSize: Responsive.text(context, size: TextSize.heading),
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
            textDirection: TextDirection.rtl,
          ),
        ),
      ),
    ];
  }

  // If there are bookmarks, return a SliverList
  return [
    SliverPadding(
      padding: EdgeInsets.symmetric(
        horizontal: Responsive.space(context, size: Space.medium),
        vertical: Responsive.space(context, size: Space.small),
      ),
      sliver: SliverList.separated(
        itemCount: bookmarkedItems.length,
        itemBuilder: (context, index) {
          final bookmark = bookmarkedItems[index];
          return CardModel(
            title: bookmark.title,
            date: bookmark.date,
            color: bookmark.color,
            description: bookmark.description,
            tags: bookmark.tags ?? [],
          );
        },
        separatorBuilder:
            (context, index) =>
                SizedBox(height: Responsive.space(context, size: Space.medium)),
      ),
    ),
  ];
}

// Optional: Keep BookmarksScreen as a StatelessWidget if you need to pass parameters
// or manage local state later, but have its build method call buildBookmarksSlivers.
// For now, the function is simpler.
/*
class BookmarksScreen extends StatelessWidget {
  const BookmarksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(); 
  }

  static List<Widget> buildSlivers(BuildContext context) {
    return buildBookmarksSlivers(context);
  }
}
*/
