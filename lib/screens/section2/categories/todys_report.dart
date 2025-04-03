import 'package:flutter/material.dart';
import 'package:pivot/providers/announcement_provider.dart';
import 'package:pivot/screens/models/card_model.dart';
import 'package:provider/provider.dart';

class TodysReport extends StatefulWidget {
  const TodysReport({super.key});

  @override
  State<TodysReport> createState() => _TodysReportState();
}

class _TodysReportState extends State<TodysReport> {
  // Controller for the PageView
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    // Initialize the PageController
    _pageController = PageController(
      // Initial page
      initialPage: 0,
      // ViewportFraction controls how much of adjacent pages is visible
      // 1.0 means only the current page is visible
      viewportFraction: 1.0,
    );
  }

  @override
  void dispose() {
    // Clean up the controller when the widget is disposed
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final announcementProvider = Provider.of<AnnouncementProvider>(context);

    // Get the current time
    final now = DateTime.now();

    // Filter announcements by timestamp (last 24 hours)
    final filteredAnnouncements =
        announcementProvider.announcements.where((announcement) {
          // Calculate the difference between now and the announcement timestamp
          final difference = now.difference(announcement.timestamp);

          // Return true if the announcement is less than 24 hours old
          return difference.inHours < 24;
        }).toList();

    if (filteredAnnouncements.isEmpty) {
      return const Center(
        child: Text(
          'مفيش اخبار النهاردة',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      );
    }

    return PageView.builder(
      controller: _pageController,
      scrollDirection: Axis.vertical,
      itemCount: filteredAnnouncements.length,
      itemBuilder: (context, index) {
        final announcement = filteredAnnouncements[index];
        return CardModel(
          title: announcement.title,
          date: announcement.date,
          color: announcement.color,
          description: announcement.description,
          tags: announcement.tags ?? [],
        );
      },
      onPageChanged: (index) {
        // No need to track the current index since we're not using it
      },
    );
  }
}
