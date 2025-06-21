import 'package:flutter/material.dart';
import 'package:pivot/responsive.dart';
import 'package:pivot/screens/section2/adminstration/models/announcement_data.dart';
import 'package:pivot/screens/section3/profile_widgets/bookmark_card.dart';

// Reusable widget for announcement cards
class AnnouncementCard extends StatelessWidget {
  final AnnouncementData announcement;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback? onPin;
  final VoidCallback? onUnpin;

  const AnnouncementCard({
    super.key,
    required this.announcement,
    required this.onEdit,
    required this.onDelete,
    this.onPin,
    this.onUnpin,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.only(
        bottom: Responsive.space(context, size: Space.small),
      ),
      color: announcement.color.withOpacity(.2),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: Responsive.padding(context, size: Space.small) * 1.5,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            showDialog(
              context: context,
              builder:
                  (context) => BookmarkDetailsDialog(
                    model: announcement,
                    color: announcement.color,
                    title: announcement.title,
                    date: announcement.date,
                    description: announcement.description,
                    imageUrls: announcement.imageUrls,
                    links: announcement.links,
                    tags: announcement.tags,
                    onRemove: null, // Not used for announcements
                  ),
            );
          },
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Title and more menu
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // More menu using PopupMenuButton
                        PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert, size: 22),
                          onSelected: (value) {
                            if (value == 'edit') {
                              onEdit();
                            } else if (value == 'delete') {
                              onDelete();
                            } else if (value == 'pin') {
                              if (onPin != null) onPin!();
                            } else if (value == 'unpin') {
                              if (onUnpin != null) onUnpin!();
                            }
                          },
                          itemBuilder:
                              (context) => [
                                PopupMenuItem(
                                  value: 'edit',
                                  child: Row(
                                    children: [
                                      Icon(Icons.edit, size: 18),
                                      SizedBox(
                                        width: Responsive.space(
                                          context,
                                          size: Space.tiny,
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
                                      Icon(Icons.delete, size: 18),
                                      SizedBox(
                                        width: Responsive.space(
                                          context,
                                          size: Space.tiny,
                                        ),
                                      ),
                                      Text('حذف'),
                                    ],
                                  ),
                                ),
                                if (!announcement.pinned)
                                  PopupMenuItem(
                                    value: 'pin',
                                    child: Row(
                                      children: [
                                        Icon(Icons.push_pin_outlined, size: 18),
                                        SizedBox(
                                          width: Responsive.space(
                                            context,
                                            size: Space.tiny,
                                          ),
                                        ),
                                        Text('تثبيت'),
                                      ],
                                    ),
                                  ),
                                if (announcement.pinned)
                                  PopupMenuItem(
                                    value: 'unpin',
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.push_pin,
                                          size: 18,
                                          color: Colors.orange,
                                        ),
                                        SizedBox(
                                          width: Responsive.space(
                                            context,
                                            size: Space.tiny,
                                          ),
                                        ),
                                        Text('إلغاء التثبيت'),
                                      ],
                                    ),
                                  ),
                              ],
                        ),
                        // Title
                        if (announcement.pinned)
                          Padding(
                            padding: const EdgeInsets.only(left: 8.0, top: 4.0),
                            child: Icon(
                              Icons.push_pin,
                              color: Colors.orange,
                              size: 22,
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
                                size: TextSize.medium,
                              ),
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.end,
                          ),
                        ),
                      ],
                    ),
                    // Date (less obvious, smaller, gray)
                    Padding(
                      padding: const EdgeInsets.only(top: 2.0, bottom: 4.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 14,
                            color: Colors.grey[500],
                          ),
                          SizedBox(
                            width: Responsive.space(context, size: Space.tiny),
                          ),
                          Text(
                            announcement.date,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Department tags to the right
                    if (announcement.tags.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 2.0),
                        child: SizedBox(
                          width: double.infinity,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children:
                                announcement.tags.map((tag) {
                                  return Container(
                                    margin: const EdgeInsets.only(left: 4),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(
                                        0xffD9D9D9,
                                      ).withOpacity(0.8),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      tag,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.black,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  );
                                }).toList(),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
