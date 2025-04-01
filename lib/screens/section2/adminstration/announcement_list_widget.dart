import 'package:flutter/material.dart';
import 'package:pivot/screens/section2/adminstration/show_dialog.dart';
import 'package:provider/provider.dart';
import 'package:pivot/providers/announcement_provider.dart';
import 'package:pivot/screens/section2/adminstration/announcement_card.dart';

/// A reusable widget that displays a list of announcements
/// This can be used anywhere in the app to show announcements
class AnnouncementListWidget extends StatelessWidget {
  final bool showActions;
  final int? maxItems;
  final List<String>? filterTags;

  const AnnouncementListWidget({
    super.key,
    this.showActions = false,
    this.maxItems,
    this.filterTags,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<AnnouncementProvider>(
      builder: (context, provider, child) {
        // Get announcements from provider
        var announcements = provider.announcements;

        // Apply tag filter if needed
        if (filterTags != null && filterTags!.isNotEmpty) {
          announcements =
              announcements.where((announcement) {
                if (announcement.tags == null) return false;
                return announcement.tags!.any(
                  (tag) => filterTags!.contains(tag),
                );
              }).toList();
        }

        // Apply max items limit if needed
        if (maxItems != null && maxItems! < announcements.length) {
          announcements = announcements.sublist(0, maxItems);
        }

        if (announcements.isEmpty) {
          return const Center(
            child: Text('مفيش اخبار', style: TextStyle(fontSize: 16)),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const BouncingScrollPhysics(),
          itemCount: announcements.length,
          itemBuilder: (context, index) {
            final announcement = announcements[index];
            return AnnouncementCard(
              announcement: announcement,
              onEdit:
                  showActions
                      ? () {
                        showAddAnnouncementDialog(
                          context: context,
                          onSave: (newAnnouncement) {
                            provider.updateAnnouncement(index, newAnnouncement);
                          },
                          isEditing: true,
                          announcement: announcement,
                          index: index,
                        );
                      }
                      : () {},
              onDelete:
                  showActions
                      ? () {
                        provider.deleteAnnouncement(index);
                      }
                      : () {},
            );
          },
        );
      },
    );
  }
}
