import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pivot/models/user_profile.dart';
import 'package:pivot/features/administration/screens/doctor/edit_about_route.dart';
import 'package:pivot/features/user/providers/user_profile_provider.dart';
import 'package:pivot/responsive.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AboutMeWidget extends ConsumerStatefulWidget {
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
  ConsumerState<AboutMeWidget> createState() => _AboutMeWidgetState();
}

class _AboutMeWidgetState extends ConsumerState<AboutMeWidget> {
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
        } else {}
      } catch (e) {}
    } else {}
  }

  @override
  Widget build(BuildContext context) {
    // Get the logged-in user to check permissions
    final loggedInUser = ref.watch(userProfileProvider).loggedInUserProfile;

    // Edit icon should only appear for:
    // 1. The user themselves (isOwnProfile)
    // 2. Admins and Super Admins
    // 3. NOT for students and professors
    final canEdit =
        widget.isOwnProfile ||
        (loggedInUser?.role == 'Admin' || loggedInUser?.role == 'Super Admin');
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
              'عن $displayTitle${widget.userProfile.name}',
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
