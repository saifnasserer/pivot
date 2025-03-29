import 'package:flutter/material.dart';
import 'package:pivot/responsive.dart';

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
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              meta,
              style: TextStyle(
                fontSize: Responsive.space(context, size: Space.medium),
                color: Color(0xffd9d9d9),
              ),
            ),
            Text(
              name,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: Responsive.space(context, size: Space.xlarge) * 1.2,
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
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
        SizedBox(width: Responsive.space(context, size: Space.large)),
        CircleAvatar(
          radius: Responsive.space(context, size: Space.large) * 3,
          backgroundColor: Colors.black,
          child: Icon(Icons.person, color: Colors.white),
        ),
      ],
    );
  }
}
