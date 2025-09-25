import 'package:flutter/material.dart';
import 'package:pivot/screens/section2/adminstration/models/announcement_data.dart';
import 'package:pivot/responsive.dart';


// Reusable widget for announcement cards
class AnnouncementCard extends StatelessWidget {
  final AnnouncementData announcement;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const AnnouncementCard({
    super.key,
    required this.announcement,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final isExpired =
        announcement.expireAt != null && announcement.expireAt!.isBefore(now);
    final hasExpiry = announcement.expireAt != null;
    final accentColor = isExpired ? Colors.grey[400] : Color(0xff1976d2);
    final preview =
        (announcement.description.trim().isNotEmpty)
            ? announcement.description.split('\n').first.trim()
            : null;
    return Card(
      margin: EdgeInsets.only(
        bottom: Responsive.space(context, size: Space.small),
      ),
      color: Colors.white,
      elevation: 2,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(
          Responsive.space(context, size: Space.large),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Accent bar
          Container(
            width: 5,
            decoration: BoxDecoration(
              color: accentColor,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(
                  Responsive.space(context, size: Space.large),
                ),
                bottomLeft: Radius.circular(
                  Responsive.space(context, size: Space.large),
                ),
              ),
            ),
          ),
          // Main content
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(
                vertical: Responsive.space(context, size: Space.small) * 1.2,
                horizontal: Responsive.space(context, size: Space.small) * 1.2,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Popup menu for actions
                      PopupMenuButton<String>(
                        onSelected: (value) {
                          if (value == 'edit') onEdit();
                          if (value == 'delete') onDelete();
                        },
                        itemBuilder:
                            (context) => [
                              PopupMenuItem(
                                value: 'edit',
                                child: Row(
                                  children: [
                                    Icon(Icons.edit_outlined, size: 18),
                                    SizedBox(
                                      width: Responsive.space(
                                        context,
                                        size: Space.small,
                                      ),
                                    ),
                                    Text('تعديل'),
                                  ],
                                ),
                              ),
                              PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.delete_outline_rounded,
                                      size: 18,
                                    ),
                                    SizedBox(
                                      width: Responsive.space(
                                        context,
                                        size: Space.small,
                                      ),
                                    ),
                                    Text('حذف'),
                                  ],
                                ),
                              ),
                            ],
                        icon: Icon(Icons.more_vert, color: Colors.grey[700]),
                        tooltip: 'خيارات',
                      ),
                      // Title and preview
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              announcement.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize:
                                    Responsive.text(
                                      context,
                                      size: TextSize.heading,
                                    ) *
                                    1.1,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                              textAlign: TextAlign.end,
                            ),
                            if (preview != null && preview.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 2.0),
                                child: Text(
                                  preview,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize:
                                        Responsive.text(
                                          context,
                                          size: TextSize.small,
                                        ) *
                                        1.05,
                                    color: Colors.grey[600],
                                  ),
                                  textAlign: TextAlign.end,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  // Tags
                  if (announcement.tags.isNotEmpty)
                    Padding(
                      padding: EdgeInsets.only(top: 8.0, bottom: 2.0),
                      child: Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        alignment: WrapAlignment.end,
                        children:
                            announcement.tags.map((tag) {
                              // Convert full format to display format
                              String displayTag = tag;
                              if (tag.startsWith('اخبار قسم ')) {
                                displayTag = tag.replaceFirst('اخبار قسم ', '');
                              }

                              return Container(
                                margin: EdgeInsets.only(left: 4),
                                padding: EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Color(0xffF1F1F1),
                                  borderRadius: BorderRadius.circular(
                                    Responsive.space(
                                      context,
                                      size: Space.large,
                                    ),
                                  ),
                                ),
                                child: Text(
                                  displayTag,
                                  style: TextStyle(
                                    fontSize:
                                        Responsive.text(
                                          context,
                                          size: TextSize.small,
                                        ) *
                                        0.85,
                                    color: Colors.black87,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              );
                            }).toList(),
                      ),
                    ),
                  // Date and expiry
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (hasExpiry)
                        Row(
                          children: [
                            Icon(
                              Icons.event,
                              color: isExpired ? Colors.red : Colors.grey,
                              size: Responsive.space(context, size: Space.tiny),
                            ),
                            SizedBox(
                              width: Responsive.space(
                                context,
                                size: Space.tiny,
                              ),
                            ),
                            // Text(
                            //   'ينتهي: ' +
                            //       (announcement.expireAt != null
                            //           ? '${announcement.expireAt!.year}/${announcement.expireAt!.month.toString().padLeft(2, '0')}/${announcement.expireAt!.day.toString().padLeft(2, '0')}'
                            //           : ''),
                            //   style: TextStyle(
                            //     color:
                            //         isExpired ? Colors.red : Colors.grey[700],
                            //     fontSize: 11,
                            //     fontWeight: FontWeight.w500,
                            //   ),
                            // ),
                          ],
                        ),
                      Text(
                        announcement.date,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: Responsive.text(
                            context,
                            size: TextSize.small,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
