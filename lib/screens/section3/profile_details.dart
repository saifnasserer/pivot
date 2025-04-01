import 'package:flutter/material.dart';
import 'package:pivot/responsive.dart';
import 'package:auto_size_text/auto_size_text.dart';

class ProfileDetails extends StatelessWidget {
  const ProfileDetails({
    super.key,

    required this.name,
    required this.meta,
    this.year = '',
  });
  final String name;
  final String meta;
  final String year;
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                meta,
                style: TextStyle(
                  fontSize: Responsive.space(context, size: Space.medium),
                  color: Color(0xffd9d9d9),
                ),
              ),
              AutoSizeText(
                name,
                style: TextStyle(
                  fontSize: Responsive.space(context, size: Space.xlarge) * 1.2,
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                minFontSize: 10,
                textAlign: TextAlign.end,
              ),
              SizedBox(height: Responsive.space(context, size: Space.small)),
              Text(
                year,
                style: TextStyle(
                  fontSize: Responsive.space(context, size: Space.medium),
                  color: Color(0xffd9d9d9),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        SizedBox(width: Responsive.space(context, size: Space.large)),
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.black, width: 3.0),
          ),
          child: CircleAvatar(
            radius: Responsive.space(context, size: Space.large) * 3,
            backgroundColor: Colors.black,
            child: ClipOval(
              child: Image.asset(
                'assets/images/profile.JPG',
                width: Responsive.space(context, size: Space.large) * 6,
                height: Responsive.space(context, size: Space.large) * 6,
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
