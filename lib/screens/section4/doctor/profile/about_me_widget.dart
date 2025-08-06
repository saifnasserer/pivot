import 'package:flutter/material.dart';
import 'package:pivot/models/user_profile.dart';
import 'package:pivot/responsive.dart';
import 'package:pivot/screens/section4/doctor/edit_about_route.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AboutMeWidget extends StatefulWidget {
  final UserProfile userProfile;
  final bool isOwnProfile;
  final Function(UserProfile)? onProfileUpdated;

  const AboutMeWidget({
    super.key,
    required this.userProfile,
    required this.isOwnProfile,
    this.onProfileUpdated,
  });

  @override
  State<AboutMeWidget> createState() => _AboutMeWidgetState();
}

class _AboutMeWidgetState extends State<AboutMeWidget> {
  Future<void> _showEditAboutScreen(BuildContext context) async {
    final result = await Navigator.push(
      context,
      AnimatedEditAboutRoute(
        userProfile: widget.userProfile,
        initialAboutText: widget.userProfile.aboutMe,
      ),
    );

    print('Edit about screen result: $result');
    if (result == true && mounted) {
      print('Updating displayed profile after successful edit');
      try {
        final doc =
            await FirebaseFirestore.instance
                .collection('users')
                .doc(widget.userProfile.id)
                .get();

        if (doc.exists) {
          final updatedProfile = UserProfile.fromJson(doc.data()!);
          print('Updated profile about: ${updatedProfile.aboutMe}');
          widget.onProfileUpdated?.call(updatedProfile);
        } else {
          print('Document does not exist');
        }
      } catch (e) {
        print('Error fetching updated profile: $e');
      }
    } else {
      print('Edit was not successful or widget not mounted');
    }
  }

  @override
  Widget build(BuildContext context) {
    final canEdit = widget.userProfile.role != 'student';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'عن دكتور ${widget.userProfile.name}',
              style: TextStyle(
                fontSize: Responsive.text(context, size: TextSize.heading),
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
