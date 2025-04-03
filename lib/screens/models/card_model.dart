import 'package:flutter/material.dart';
import 'package:pivot/providers/bookmarks.dart';
import 'package:pivot/responsive.dart';
import 'package:pivot/screens/section2/adminstration/models/announcement_data.dart';
import 'package:pivot/screens/section4/doctor/doctor_profile.dart';
import 'package:provider/provider.dart';

class CardModel extends StatefulWidget {
  final String title;
  final String date;
  final Color color;
  final String description;
  final List<String> tags;
  final String? imageUrl;
  final String? doctorName;
  final bool isDoctorCard;

  CardModel({
    super.key,
    required this.title,
    required this.date,
    required this.color,
    required this.description,
    required this.tags,
    this.imageUrl,
    this.doctorName,
    this.isDoctorCard = false,
  });

  @override
  State<CardModel> createState() => _CardModelState();
}

class _CardModelState extends State<CardModel> {
  int shareCount = 0;

  AnnouncementData _createAnnouncementData() {
    return AnnouncementData(
      title: widget.title,
      date: widget.date,
      color: widget.color,
      description: widget.description,
      tags: widget.tags,
    );
  }

  @override
  Widget build(BuildContext context) {
    final bookmarksProvider = Provider.of<Bookmarks>(context);
    final bool isCurrentlyBookmarked = bookmarksProvider.isBookmarked(
      _createAnnouncementData(),
    );

    return Container(
      margin: EdgeInsets.all(3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: widget.color.withOpacity(0.15),
      ),
      child: Padding(
        padding: EdgeInsets.all(Responsive.space(context, size: Space.large)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      widget.title,
                      textAlign: TextAlign.right,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                      style: TextStyle(
                        fontSize:
                            Responsive.text(context, size: TextSize.heading) *
                            1.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(
                      height: Responsive.space(context, size: Space.medium),
                    ),
                    Text(
                      widget.description,
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontSize: Responsive.text(
                          context,
                          size: TextSize.medium,
                        ),
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (widget.date != null)
                          Align(
                            alignment: Alignment.centerRight,
                            child: Padding(
                              padding: EdgeInsets.only(
                                top: Responsive.space(
                                  context,
                                  size: Space.medium,
                                ),
                              ),
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.7),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.calendar_today,
                                      size: 16,
                                      color: Colors.white,
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      widget.date,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize:
                                            Responsive.text(
                                              context,
                                              size: TextSize.small,
                                            ) *
                                            0.9,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        if (widget.tags.isNotEmpty)
                          Padding(
                            padding: EdgeInsets.only(
                              top: Responsive.space(
                                context,
                                size: Space.medium,
                              ),
                            ),
                            child: Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              alignment: WrapAlignment.end,
                              children:
                                  widget.tags.map((tag) {
                                    return Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Color(
                                          0xffe1e0da,
                                        ).withOpacity(0.5),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: widget.color.withOpacity(0.5),
                                          width: 1,
                                        ),
                                      ),
                                      child: Text(
                                        tag,
                                        style: TextStyle(
                                          fontSize:
                                              Responsive.text(
                                                context,
                                                size: TextSize.small,
                                              ) *
                                              0.9,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    );
                                  }).toList(),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Column(
              children: [
                Center(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: Colors.white,
                      border: Border.all(color: Colors.black),
                    ),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: Responsive.space(
                          context,
                          size: Space.medium,
                        ),
                        vertical: Responsive.space(context, size: Space.small),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            onPressed: () {
                              setState(() {
                                shareCount++;
                              });
                            },
                            icon: Icon(Icons.share),
                          ),
                          SizedBox(
                            width: Responsive.space(context, size: Space.small),
                          ),
                          Row(
                            children: [
                              IconButton(
                                onPressed: () {
                                  final bookmarks = Provider.of<Bookmarks>(
                                    context,
                                    listen: false,
                                  );
                                  final itemData = _createAnnouncementData();

                                  if (isCurrentlyBookmarked) {
                                    bookmarks.removeBookmark(itemData);
                                  } else {
                                    bookmarks.addBookmark(itemData);
                                  }
                                },
                                icon: Icon(
                                  isCurrentlyBookmarked
                                      ? Icons.bookmark
                                      : Icons.bookmark_border,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(height: Responsive.space(context, size: Space.medium)),
                Divider(color: Colors.black),
                SizedBox(height: Responsive.space(context, size: Space.small)),
                InkWell(
                  onTap: () {
                    Navigator.pushNamed(context, DoctorProfile.id);
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: Responsive.space(context, size: Space.medium),
                      vertical: Responsive.space(context, size: Space.small),
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.arrow_back_ios_new,
                          size: 16,
                          color: Colors.white,
                        ),
                        SizedBox(
                          width: Responsive.space(context, size: Space.small),
                        ),
                        Text(
                          'دكتور احمد طه ',
                          style: TextStyle(
                            fontSize:
                                Responsive.text(context, size: TextSize.small) *
                                1.1,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(
                          width: Responsive.space(context, size: Space.small),
                        ),
                        CircleAvatar(
                          radius: Responsive.space(context, size: Space.medium),
                          backgroundColor: widget.color,
                          child: Image.asset(
                            'assets/icon.png',
                            width:
                                Responsive.space(context, size: Space.medium) *
                                1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
