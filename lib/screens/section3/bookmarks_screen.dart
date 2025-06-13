import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pivot/providers/bookmarks.dart';
import 'package:pivot/screens/models/card_model.dart';
import 'package:pivot/responsive.dart'; // Assuming you might need Responsive

class BookmarksScreen extends StatelessWidget {
  const BookmarksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Get the Bookmarks provider
    final bookmarksProvider = Provider.of<Bookmarks>(context);
    final bookmarkedItems = bookmarksProvider.bookmarks;

    // Check if there are any bookmarks
    if (bookmarkedItems.isEmpty) {
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

    // Display bookmarks using ListView
    return ListView.builder(
      itemCount: bookmarkedItems.length,
      itemBuilder: (context, index) {
        final bookmark = bookmarkedItems[index];
        // Use CardModel to display each bookmark
        // Wrap CardModel in a fixed-height container or adjust CardModel if needed
        // Example: Using a SizedBox for consistent height, adjust as needed
        return Padding(
          padding: EdgeInsets.symmetric(
            vertical: Responsive.space(context, size: Space.small),
            horizontal: Responsive.space(context, size: Space.medium),
          ),
          child: SizedBox(
            height: Responsive.space(context, size: Space.xlarge) * 15,
            child: CardModel(
              title: bookmark.title,
              date: bookmark.date,
              color: bookmark.color,
              description: bookmark.description,
              tags: bookmark.tags ?? [], // CardModel requires non-null tags
            ),
          ),
        );
      },
    );
  }
}
