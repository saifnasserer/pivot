import 'package:flutter/material.dart';
import 'package:pivot/responsive.dart';
import 'package:pivot/screens/section4/doctor_profile.dart';

class CardModel extends StatefulWidget {
  CardModel({
    super.key,
    required this.color,
    required this.title,
    required this.desc,
    this.tags,
    this.date,
  });

  final Color color;
  final String title;
  final String desc;
  final List<String>? tags;
  final String? date;
  bool checked = false;
  @override
  State<CardModel> createState() => _CardModelState();
}

class _CardModelState extends State<CardModel> {
  int bookmarkCount = 0;
  int shareCount = 0;
  @override
  Widget build(BuildContext context) {
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
            // Title and description in a scrollable container
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
                      textAlign: TextAlign.right,
                      widget.desc,
                      style: TextStyle(
                        fontSize: Responsive.text(
                          context,
                          size: TextSize.medium,
                        ),
                      ),
                    ),

                    // Display tags if available , and date
                    Column(
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
                                      widget.date!,
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
                        if (widget.tags != null && widget.tags!.isNotEmpty)
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
                                  widget.tags!.map((tag) {
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

            // Fixed bottom section
            Column(
              children: [
                // Action buttons container
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
                                  setState(() {
                                    widget.checked = !widget.checked;
                                    widget.checked
                                        ? bookmarkCount++
                                        : bookmarkCount--;
                                  });
                                },
                                icon: Icon(
                                  widget.checked
                                      ? Icons.bookmark
                                      : Icons.bookmark_border_outlined,
                                ),
                              ),
                              // Only show counter when bookmarked
                              if (widget.checked)
                                Text(
                                  bookmarkCount.toString(),
                                  style: TextStyle(
                                    fontSize: Responsive.text(
                                      context,
                                      size: TextSize.small,
                                    ),
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold,
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

                // Doctor section
                Divider(color: Colors.black),
                SizedBox(height: Responsive.space(context, size: Space.small)),
                InkWell(
                  onTap: () {
                    Navigator.pushNamed(context, DoctorProfile.id);
                    // Navigate to doctor profile or show more info
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('تم النقر على الدكتور'),
                        duration: Duration(seconds: 1),
                      ),
                    );
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
