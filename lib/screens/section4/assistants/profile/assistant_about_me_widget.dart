import 'package:flutter/material.dart';
import 'package:pivot/models/user_profile.dart';
import 'package:pivot/screens/section4/doctor/edit_about_route.dart';
import 'package:pivot/responsive.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


class AssistantAboutMeWidget extends StatefulWidget {
  final UserProfile userProfile;
  final bool isOwnProfile;
  final Function(UserProfile)? onProfileUpdated;

  const AssistantAboutMeWidget({
    super.key,
    required this.userProfile,
    required this.isOwnProfile,
    this.onProfileUpdated,
  });

  @override
  State<AssistantAboutMeWidget> createState() => _AssistantAboutMeWidgetState();
}

class _AssistantAboutMeWidgetState extends State<AssistantAboutMeWidget> {
  Future<void> _showEditAboutScreen(BuildContext context) async {
    final result = await Navigator.push(
      context,
      AnimatedEditAboutRoute(
        userProfile: widget.userProfile,
        initialAboutText: widget.userProfile.aboutMe,
      ),
    );

    if (result == true && mounted) {
      try {
        final doc =
            await FirebaseFirestore.instance
                .collection('users')
                .doc(widget.userProfile.id)
                .get();

        if (doc.exists) {
          final updatedProfile = UserProfile.fromJson(doc.data()!);
          widget.onProfileUpdated?.call(updatedProfile);
        } else {
        }
      } catch (e) {
      }
    } else {
    }
  }

  @override
  Widget build(BuildContext context) {
    final canEdit = widget.userProfile.role != 'student';
    String displayTitle = widget.userProfile.name;
    if (widget.userProfile.role.toLowerCase() == 'professor') {
      String title =
          widget.userProfile.gender == 'ذكر' ? 'الدكتور ' : 'الدكتورة ';
      displayTitle = title;
    } else if (widget.userProfile.role.toLowerCase() == 'miniprofessor') {
      String title =
          widget.userProfile.gender == 'ذكر' ? 'البشمهندس ' : 'البشمهندسة ';
      displayTitle = title;
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'عن $displayTitle ${widget.userProfile.name}',
              style: TextStyle(
                fontSize: Responsive.text(context, size: TextSize.medium),
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            if (canEdit)
              Container(
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(
                    Responsive.space(context, size: Space.medium),
                  ),
                ),
                child: IconButton(
                  icon: const Icon(Icons.edit, color: Colors.white),
                  onPressed: () => _showEditAboutScreen(context),
                ),
              ),
          ],
        ),
        SizedBox(height: Responsive.space(context, size: Space.medium)),
        Text(
          widget.userProfile.aboutMe.isNotEmpty
              ? widget.userProfile.aboutMe
              : 'لم يتم تقديمه بعد.',
          style: TextStyle(
            fontSize: Responsive.text(context, size: TextSize.medium),
            color: Colors.black87,
            height: 1.6,
          ),
        ),
      ],
    );
  }
}
