import 'package:flutter/material.dart';
import 'package:pivot/responsive.dart';
import 'package:pivot/screens/section2/adminstration/models/announcement_data.dart';

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
    return Card(
      margin: EdgeInsets.only(
        bottom: Responsive.space(context, size: Space.small),
      ),
      color: announcement.color.withOpacity(.3),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: Responsive.padding(context, size: Space.small) * 1.5,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Action buttons
            Row(
              children: [
                IconButton(
                  icon: Icon(
                    Icons.delete_outline_rounded,
                    size:
                        Responsive.text(context, size: TextSize.heading) * 0.9,
                  ),
                  color: Colors.black,
                  onPressed: onDelete,
                  tooltip: 'حذف',
                  splashRadius: 24,
                ),
                IconButton(
                  iconSize:
                      Responsive.text(context, size: TextSize.heading) * 0.9,
                  icon: const Icon(Icons.edit_outlined),
                  color: Colors.black,
                  onPressed: onEdit,
                  tooltip: 'تعديل',
                  splashRadius: 24,
                ),
              ],
            ),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Title with date badge
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        margin: EdgeInsets.only(
                          right:
                              Responsive.space(context, size: Space.small) *
                              0.8,
                          top: 4,
                        ),
                        padding: EdgeInsets.symmetric(
                          horizontal:
                              Responsive.space(context, size: Space.small) *
                              0.7,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Color(0xffff5252),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          announcement.date,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize:
                                Responsive.text(context, size: TextSize.small) *
                                0.9,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          announcement.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: Responsive.text(
                              context,
                              size: TextSize.heading,
                            ),
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.end,
                        ),
                      ),
                    ],
                  ),

                  // Tags (if available)
                  if (announcement.tags != null &&
                      announcement.tags!.isNotEmpty)
                    Padding(
                      padding: EdgeInsets.only(
                        top: Responsive.space(context, size: Space.small) * 0.6,
                      ),
                      child: Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        alignment: WrapAlignment.end,
                        children:
                            announcement.tags!.map((tag) {
                              return Container(
                                margin: EdgeInsets.only(left: 4),
                                padding: EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Color(0xffD9D9D9).withOpacity(0.8),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  tag,
                                  style: TextStyle(
                                    fontSize:
                                        Responsive.text(
                                          context,
                                          size: TextSize.small,
                                        ) *
                                        0.8,
                                    color: Colors.black,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              );
                            }).toList(),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
