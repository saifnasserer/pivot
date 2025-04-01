import 'package:flutter/material.dart';
import 'package:pivot/providers/announcement_provider.dart';
import 'package:pivot/screens/models/card_model.dart';
import 'package:provider/provider.dart';

class CSReport extends StatefulWidget {
  const CSReport({super.key});

  @override
  State<CSReport> createState() => _CSReportState();
}

class _CSReportState extends State<CSReport> {
  // Controller for the PageView
  late PageController _pageController;

  // List of tags to filter by for SC report
  final List<String> _filterTags = ['اخبار قسم CS'];

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

    // Filter announcements by tags
    final filteredAnnouncements =
        announcementProvider.announcements.where((announcement) {
          if (announcement.tags == null || announcement.tags!.isEmpty) {
            return false;
          }
          return announcement.tags!.any((tag) => _filterTags.contains(tag));
        }).toList();

    if (filteredAnnouncements.isEmpty) {
      return const Center(
        child: Text(
          'مفيش اخبار',
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
          desc: announcement.description,
          color: announcement.color,
          date: announcement.date,
        );
      },
      onPageChanged: (index) {
        // No need to track the current index since we're not using it
      },
    );
  }
}
