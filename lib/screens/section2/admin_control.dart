import 'package:flutter/material.dart';
import 'package:pivot/responsive.dart';
import 'package:pivot/screens/models/circular_button.dart';
import 'package:pivot/screens/section2/adminstration/models/announcement_data.dart';
import 'package:pivot/screens/section2/adminstration/announcement_card.dart';
import 'package:pivot/screens/section2/adminstration/show_dialog.dart';
import 'package:provider/provider.dart';
import 'package:pivot/providers/announcement_provider.dart';

class AdminControl extends StatefulWidget {
  const AdminControl({super.key});
  static const String id = 'admin_id';

  @override
  State<AdminControl> createState() => _AdminControlState();
}

class _AdminControlState extends State<AdminControl> {
  @override
  Widget build(BuildContext context) {
    // Access the announcement provider
    final announcementProvider = Provider.of<AnnouncementProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'المطبخ',
          style: TextStyle(
            fontSize: Responsive.text(context, size: TextSize.heading),
            fontWeight: FontWeight.bold,
          ),
        ),
        surfaceTintColor: Colors.white,
        centerTitle: true,
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Padding(
              padding: Responsive.padding(context, size: Space.medium),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // List of announcements
                  Expanded(
                    child: ListView.builder(
                      itemCount: announcementProvider.announcements.length,
                      itemBuilder: (context, index) {
                        final announcement =
                            announcementProvider.announcements[index];
                        return Padding(
                          padding: EdgeInsets.only(
                            bottom: Responsive.space(
                              context,
                              size: Space.small,
                            ),
                          ),
                          child: AnnouncementCard(
                            announcement: announcement,
                            onEdit: () {
                              showAddAnnouncementDialog(
                                context: context,
                                isEditing: true,
                                announcement: announcement,
                                index: index,
                                onSave: (newAnnouncement) {
                                  announcementProvider.updateAnnouncement(
                                    index,
                                    newAnnouncement,
                                  );
                                },
                              );
                            },
                            onDelete: () {
                              announcementProvider.deleteAnnouncement(index);
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: Responsive.space(context),
              child: CircularButton(
                onPressed: () {
                  showAddAnnouncementDialog(
                    context: context,
                    onSave: (newAnnouncement) {
                      announcementProvider.addAnnouncement(newAnnouncement);
                    },
                  );
                },
                icon: Icons.add_rounded,
                iconSizeMultiplier: 3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
