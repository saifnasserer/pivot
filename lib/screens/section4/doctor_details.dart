import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:pivot/models/user_profile.dart';
import 'package:pivot/responsive.dart';
import 'package:auto_size_text/auto_size_text.dart';

class DoctorDetails extends StatelessWidget {
  const DoctorDetails({super.key, required this.userProfile});
  final UserProfile userProfile;

  @override
  Widget build(BuildContext context) {
    String displayTitle = userProfile.name;
    if (userProfile.role.toLowerCase() == 'professor') {
      String title = userProfile.gender == 'ذكر' ? 'الدكتور ' : 'الدكتورة ';
      displayTitle = title;
    } else if (userProfile.role.toLowerCase() == 'miniprofessor') {
      String title = userProfile.gender == 'ذكر' ? 'البشمهندس ' : 'البشمهندسة ';
      displayTitle = title;
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                displayTitle,
                style: TextStyle(
                  fontSize: Responsive.space(context, size: Space.medium),
                  color: const Color(0xffd9d9d9),
                ),
              ),
              AutoSizeText(
                userProfile.name,
                style: TextStyle(
                  fontSize: Responsive.space(context, size: Space.xlarge) * 1.2,
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                minFontSize: Responsive.space(context, size: Space.tiny),
                textAlign: TextAlign.end,
              ),
              SizedBox(height: Responsive.space(context, size: Space.small)),
              // Text(
              //   userProfile.department,
              //   style: TextStyle(
              //     fontSize: Responsive.space(context, size: Space.medium),
              //     color: Color(0xffd9d9d9),
              //     fontWeight: FontWeight.bold,
              //   ),
              // ),
            ],
          ),
        ),
        SizedBox(width: Responsive.space(context, size: Space.large)),
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.black,
              width: Responsive.space(context, size: Space.tiny),
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
