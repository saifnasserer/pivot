import 'package:flutter/material.dart';
import 'package:pivot/responsive.dart';

class CardModel extends StatefulWidget {
  const CardModel({super.key, required this.color});

  final Color color;
  @override
  State<CardModel> createState() => _CardModelState();
}

class _CardModelState extends State<CardModel> {
  int likeCount = 0;
  int bookmarkCount = 0;
  int shareCount = 0;
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: widget.color.withOpacity(0.3),
      ),
      child: Padding(
        padding: EdgeInsets.all(Responsive.space(context)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              textAlign: TextAlign.right,
              'خبر نص نص',
              style: TextStyle(
                fontSize:
                    Responsive.text(context, size: TextSize.heading) * 1.5,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: Responsive.space(context, size: Space.xlarge)),
            Text(
              textAlign: TextAlign.right,
              'دكتور سيف ناصر قرر يأجل المحاضرة بتاعة النهاردة لاسباب خاصة وهيتم تعويضها ف انتظر المعاد الجديد من الدكتور',
              style: TextStyle(
                fontSize: Responsive.text(context, size: TextSize.medium),
              ),
            ),
            SizedBox(height: Responsive.space(context, size: Space.xlarge) * 8),
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
                    horizontal: Responsive.space(context, size: Space.medium),
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
                      IconButton(
                        onPressed: () {
                          setState(() {
                            bookmarkCount++;
                          });
                        },
                        icon: Icon(Icons.bookmark_border_outlined),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(height: Responsive.space(context, size: Space.large)),

            // Doctor section
            Divider(color: Colors.black),
            SizedBox(height: Responsive.space(context, size: Space.medium)),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'دكتور احمد طه قرر',
                  style: TextStyle(
                    fontSize: Responsive.text(context, size: TextSize.medium),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(width: Responsive.space(context, size: Space.small)),
                Image.asset(
                  'assets/icon.png',
                  width: Responsive.space(context, size: Space.xlarge) * 2,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
