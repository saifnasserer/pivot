import 'package:flutter/material.dart';
import 'package:pivot/responsive.dart';
import 'package:pivot/screens/section2/adminstration/models/announcement_data.dart';
import 'package:pivot/screens/section3/profile_widgets/bookmark_card.dart';
import 'package:gradient_borders/gradient_borders.dart';

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
    final now = DateTime.now();
    final isScheduled =
        announcement.publishAt != null && announcement.publishAt!.isAfter(now);
    final isExpired =
        announcement.expireAt != null && announcement.expireAt!.isBefore(now);
    final hasExpiry = announcement.expireAt != null;
    final accentColor =
        isExpired
            ? Colors.grey[400]!
            : (announcement.pinned
                ? Colors.orange[600]!
                : (isScheduled ? Colors.blue[600]! : announcement.color));
    final opacity = isExpired ? 0.6 : 1.0;
    final Color baseColor = announcement.color.withOpacity(0.18);
    final Color tagDepartmentColor = Colors.blue[200]!;
    final Color tagGeneralColor = Colors.green[200]!;
    final Color tagDefaultColor = Colors.grey[200]!;

    return Opacity(
      opacity: opacity,
      child: InkWell(
        borderRadius: BorderRadius.circular(
          Responsive.space(context, size: Space.large),
        ),
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
        child: Container(
          margin: EdgeInsets.symmetric(
            vertical: Responsive.space(context, size: Space.small),
          ),
          padding: EdgeInsets.all(Responsive.space(context, size: Space.small)),
          decoration: BoxDecoration(
            color: baseColor,
            borderRadius: BorderRadius.circular(
              Responsive.space(context, size: Space.large),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
            border:
                announcement.pinned
                    ? GradientBoxBorder(
                      gradient: LinearGradient(
                        begin: Alignment.topRight,
                        end: Alignment.bottomLeft,
                        colors: [Color(0xFF4158D0), Color(0xFFC850C0)],
                      ),
                      width: 2,
                    )
                    : Border.all(
                      color: accentColor.withOpacity(0.18),
                      width: Responsive.space(context, size: Space.tiny) / 2,
                    ),
          ),
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: Row(
              children: [
                SizedBox(width: Responsive.space(context, size: Space.small)),
                // Main info column (Expanded)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Text(
                        announcement.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: Responsive.text(
                            context,
                            size: TextSize.medium,
                          ),
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(
                        height: Responsive.space(context, size: Space.tiny),
                      ),
                      // Date and tags row
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size:
                                Responsive.space(context, size: Space.small) *
                                2,
                            color: Colors.grey[500],
                          ),
                          SizedBox(
                            width: Responsive.space(context, size: Space.tiny),
                          ),
                          Text(
                            announcement.date,
                            style: TextStyle(
                              fontSize: Responsive.text(
                                context,
                                size: TextSize.small,
                              ),
                              color: Colors.grey[600],
                            ),
                          ),
                          if (hasExpiry) ...[
                            SizedBox(
                              width: Responsive.space(
                                context,
                                size: Space.small,
                              ),
                            ),
                            Icon(
                              Icons.event,
                              size: Responsive.space(
                                context,
                                size: Space.small,
                              ),
                              color: isExpired ? Colors.red : Colors.grey[600],
                            ),
                            SizedBox(
                              width: Responsive.space(
                                context,
                                size: Space.tiny,
                              ),
                            ),
                            Text(
                              '/${announcement.expireAt!.month.toString().padLeft(2, '0')}/${announcement.expireAt!.day.toString().padLeft(2, '0')}',
                              style: TextStyle(
                                fontSize: Responsive.text(
                                  context,
                                  size: TextSize.small,
                                ),
                                color:
                                    isExpired ? Colors.red : Colors.grey[600],
                              ),
                            ),
                          ],
                          // Tags (scrollable like skills)
                          if (announcement.tags.isNotEmpty) ...[
                            SizedBox(
                              width: Responsive.space(
                                context,
                                size: Space.small,
                              ),
                            ),
                            Expanded(
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children:
                                      announcement.tags.map((tag) {
                                        Color tagColor;
                                        Color tagTextColor = Colors.black87;
                                        String displayTag = tag;

                                        // Handle old format "اخبار قسم SC" -> extract "SC"
                                        if (tag.startsWith('اخبار قسم ')) {
                                          displayTag = tag.replaceFirst(
                                            'اخبار قسم ',
                                            '',
                                          );
                                        }

                                        if ([
                                          'SC',
                                          'AI',
                                          'CS',
                                          'IS',
                                        ].contains(displayTag)) {
                                          tagColor = tagDepartmentColor;
                                          tagTextColor = Colors.blue[900]!;
                                        } else if (displayTag == 'عام') {
                                          tagColor = tagGeneralColor;
                                          tagTextColor = Colors.green[900]!;
                                        } else {
                                          tagColor = tagDefaultColor;
                                        }
                                        return Container(
                                          margin: EdgeInsets.only(left: 4),
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: tagColor,
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
                                              fontSize: Responsive.text(
                                                context,
                                                size: TextSize.small,
                                              ),
                                              color: tagTextColor,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                // Three-dot menu
                SizedBox(width: Responsive.space(context, size: Space.small)),
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert, color: Colors.grey[700]),
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
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
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: Row(
                              children: [
                                Icon(
                                  Icons.edit_outlined,
                                  size: 18,
                                  color: Colors.blue[600],
                                ),
                                SizedBox(
                                  width: Responsive.space(
                                    context,
                                    size: Space.small,
                                  ),
                                ),
                                Text('تعديل', style: TextStyle(fontSize: 14)),
                              ],
                            ),
                          ),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(
                                Icons.delete_outline,
                                size: 18,
                                color: Colors.red[600],
                              ),
                              SizedBox(
                                width: Responsive.space(
                                  context,
                                  size: Space.small,
                                ),
                              ),
                              Text('حذف', style: TextStyle(fontSize: 14)),
                            ],
                          ),
                        ),
                        if (!announcement.pinned)
                          PopupMenuItem(
                            value: 'pin',
                            child: Row(
                              children: [
                                Icon(
                                  Icons.push_pin_outlined,
                                  size: 18,
                                  color: Colors.orange[600],
                                ),
                                SizedBox(
                                  width: Responsive.space(
                                    context,
                                    size: Space.small,
                                  ),
                                ),
                                Text('تثبيت', style: TextStyle(fontSize: 14)),
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
                                  color: Colors.orange[600],
                                ),
                                SizedBox(
                                  width: Responsive.space(
                                    context,
                                    size: Space.small,
                                  ),
                                ),
                                Text(
                                  'إلغاء التثبيت',
                                  style: TextStyle(fontSize: 14),
                                ),
                              ],
                            ),
                          ),
                      ],
                  borderRadius: BorderRadius.circular(
                    Responsive.space(context, size: Space.large),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
