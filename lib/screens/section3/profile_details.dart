import 'package:flutter/material.dart';
import 'package:pivot/responsive.dart';

class ProfileDetails extends StatelessWidget {
  const ProfileDetails({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              'SC قسم',
              style: TextStyle(
                fontSize: Responsive.space(context, size: Space.medium),
                color: Color(0xffd9d9d9),
              ),
            ),
            Text(
              'فاطمة بشير',
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: Responsive.space(context, size: Space.xlarge) * 1.2,
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'فرقة تالتة',
              style: TextStyle(
                fontSize: Responsive.space(context, size: Space.medium),
                color: Color(0xffd9d9d9),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        SizedBox(width: Responsive.space(context, size: Space.large)),
        Container(
          width: Responsive.space(context, size: Space.large) * 5,
          height: Responsive.space(context, size: Space.large) * 5,
          decoration: BoxDecoration(
            color: Colors.black,
            shape: BoxShape.circle,
            // image: DecorationImage(
            //   image: AssetImage('assets/icon.png'),
            //   fit: BoxFit.cover,
            // ),
          ),
        ),
      ],
    );
  }
}
