import 'package:flutter/material.dart';
import 'package:pivot/responsive.dart';
import 'package:pivot/screens/models/circular_button.dart';
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
  void initState() {
    super.initState();
    // Fetch announcements when the widget is first created
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AnnouncementProvider>(context, listen: false)
          .fetchAnnouncements();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Use a Consumer to react to changes in the provider
    return Consumer<AnnouncementProvider>(
      builder: (context, announcementProvider, child) {
        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.white,
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
                announcementProvider.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : Padding(
                        padding:
                            Responsive.padding(context, size: Space.medium),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // List of announcements
                            announcementProvider.announcements.isEmpty
                                ? Expanded(
                                    child: Center(
                                      child: Text(
                                        'ياترى الخبر طعمة ايه النهارده',
                                        style: TextStyle(
                                            fontSize: Responsive.text(context,
                                                size: TextSize.heading)),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  )
                                : Expanded(
                                    child: ListView.builder(
                                      itemCount: announcementProvider
                                          .announcements.length,
                                      itemBuilder: (context, index) {
                                        final announcement =
                                            announcementProvider
                                                .announcements[index];
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
                                                onSave: (newAnnouncement) {
                                                  announcementProvider
                                                      .updateAnnouncement(
                                                          newAnnouncement);
                                                },
                                              );
                                            },
                                            onDelete: () {
                                              if (announcement.id != null) {
                                                announcementProvider
                                                    .deleteAnnouncement(
                                                        announcement.id!);
                                              }
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
                          announcementProvider
                              .addAnnouncement(newAnnouncement);
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
      },
    );
  }
}
