import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:pivot/models/user_profile.dart';
import 'package:pivot/responsive.dart';
import 'package:auto_size_text/auto_size_text.dart';

class ProfileDetails extends StatelessWidget {
  const ProfileDetails({super.key, required this.userProfile});
  final UserProfile userProfile;

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
                'الفرقة ${userProfile.level}',
                style: TextStyle(
                  fontSize: Responsive.space(context, size: Space.small) * 2,
                  color: Color(0xffd9d9d9),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: AutoSizeText(
                      userProfile.name,
                      style: TextStyle(
                        fontSize:
                            Responsive.space(context, size: Space.large) * 1.5,
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      minFontSize: 10,
                      textAlign: TextAlign.end,
                    ),
                  ),
                ],
              ),
              SizedBox(height: Responsive.space(context, size: Space.small)),
              AutoSizeText(
                (' ${userProfile.department} سكشن ${userProfile.section} قسم '),
                style: TextStyle(
                  fontSize: Responsive.space(context, size: Space.small) * 2,
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
            border: Border.all(
              color: Colors.black,
              width: Responsive.space(context, size: Space.small) / 2,
            ),
          ),
          child: CircleAvatar(
            radius: Responsive.space(context, size: Space.large) * 2.5,
            backgroundColor: Colors.black,
            child: ClipOval(
              child:
                  userProfile.profileImageUrl != null &&
                          userProfile.profileImageUrl!.isNotEmpty
                      ? CachedNetworkImage(
                        imageUrl: userProfile.profileImageUrl!,
                        width: Responsive.space(context, size: Space.large) * 6,
                        height:
                            Responsive.space(context, size: Space.large) * 6,
                        fit: BoxFit.cover,
                        placeholder:
                            (context, url) => const Center(
                              child: CircularProgressIndicator(
                                color: Colors.white,
                              ),
                            ),
                        errorWidget:
                            (context, url, error) => Icon(
                              Icons.person,
                              size:
                                  Responsive.space(context, size: Space.large) *
                                  2.5,
                              color: Colors.white,
                            ),
                      )
                      : Icon(
                        Icons.person,
                        size:
                            Responsive.space(context, size: Space.large) * 2.5,
                        color: Colors.white,
                      ),
            ),
          ),
        ),
      ],
    );
  }
}
