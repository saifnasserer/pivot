import 'package:flutter/material.dart';
import 'package:pivot/models/user_profile.dart';
import 'package:pivot/providers/user_profile_provider.dart';
import 'package:provider/provider.dart';
import 'package:pivot/responsive.dart';
import 'package:pivot/widgets/unified_dialog.dart';

class SocialMediaWidget extends StatelessWidget {
  final UserProfile userProfile;
  final bool isOwnProfile;
  final Function(UserProfile)? onProfileUpdated;

  const SocialMediaWidget({
    super.key,
    required this.userProfile,
    required this.isOwnProfile,
    this.onProfileUpdated,
  });

  void _showSocialMediaDialog(BuildContext context) {
    final TextEditingController platformController = TextEditingController();
    final TextEditingController urlController = TextEditingController();
    final TextEditingController displayNameController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return UnifiedDialog(
              title: 'إضافة رابط التواصل الاجتماعي',
              subtitle: 'أضف رابط منصة التواصل الاجتماعي الخاصة بك',
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  UnifiedFormField(
                    controller: platformController,
                    label: 'المنصة',
                    hint: 'مثال: Facebook, Twitter, LinkedIn',
                  ),
                  SizedBox(
                    height: Responsive.space(context, size: Space.medium),
                  ),
                  UnifiedFormField(
                    controller: urlController,
                    label: 'الرابط',
                    hint: 'https://www.facebook.com/username',
                    keyboardType: TextInputType.url,
                  ),
                  SizedBox(
                    height: Responsive.space(context, size: Space.medium),
                  ),
                  UnifiedFormField(
                    controller: displayNameController,
                    label: 'الاسم المعروض',
                    hint: 'اختياري - اسم معروض للرابط',
                  ),
                ],
              ),
              confirmText: 'إضافة',
              confirmIcon: Icons.add_link,
              onConfirm: () async {
                if (platformController.text.isNotEmpty &&
                    urlController.text.isNotEmpty) {
                  final newLink = SocialMediaLink(
                    platform: platformController.text.trim(),
                    url: urlController.text.trim(),
                    displayName:
                        displayNameController.text.trim().isEmpty
                            ? null
                            : displayNameController.text.trim(),
                  );

                  final updatedLinks = [
                    ...userProfile.socialMediaLinks,
                    newLink,
                  ];

                  try {
                    await context
                        .read<UserProfileProvider>()
                        .updateSocialMediaLinks(userProfile.id, updatedLinks);

                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('تم إضافة الرابط بنجاح'),
                        backgroundColor: Colors.green,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            Responsive.space(context, size: Space.large),
                          ),
                        ),
                      ),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('فشل في إضافة الرابط: $e'),
                        backgroundColor: Colors.red,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            Responsive.space(context, size: Space.large),
                          ),
                        ),
                      ),
                    );
                  }
                }
              },
              onCancel: () => Navigator.of(context).pop(),
            );
          },
        );
      },
    );
  }

  Widget _buildSocialMediaLink(BuildContext context, SocialMediaLink link) {
    IconData getIconForPlatform(String platform) {
      switch (platform.toLowerCase()) {
        case 'facebook':
          return Icons.facebook;
        case 'twitter':
          return Icons.flutter_dash;
        case 'linkedin':
          return Icons.work;
        case 'instagram':
          return Icons.camera_alt;
        case 'youtube':
          return Icons.play_circle;
        case 'github':
          return Icons.code;
        default:
          return Icons.link;
      }
    }

    Color getColorForPlatform(String platform) {
      switch (platform.toLowerCase()) {
        case 'facebook':
          return Colors.blue[600]!;
        case 'twitter':
          return Colors.lightBlue[400]!;
        case 'linkedin':
          return Colors.blue[700]!;
        case 'instagram':
          return Colors.purple[400]!;
        case 'youtube':
          return Colors.red[600]!;
        case 'github':
          return Colors.black87;
        default:
          return Colors.grey[600]!;
      }
    }

    return Container(
      margin: EdgeInsets.only(
        bottom: Responsive.space(context, size: Space.small),
      ),
      padding: EdgeInsets.all(Responsive.space(context, size: Space.medium)),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(
          Responsive.space(context, size: Space.medium),
        ),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(
              Responsive.space(context, size: Space.small),
            ),
            decoration: BoxDecoration(
              color: getColorForPlatform(link.platform),
              borderRadius: BorderRadius.circular(
                Responsive.space(context, size: Space.medium),
              ),
            ),
            child: Icon(
              getIconForPlatform(link.platform),
              color: Colors.white,
              size: Responsive.text(context, size: TextSize.medium),
            ),
          ),
          SizedBox(width: Responsive.space(context, size: Space.medium)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  link.platform,
                  style: TextStyle(
                    fontSize: Responsive.text(context, size: TextSize.medium),
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                if (link.displayName != null)
                  Text(
                    link.displayName!,
                    style: TextStyle(
                      fontSize: Responsive.text(context, size: TextSize.small),
                      color: Colors.black54,
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.open_in_new, size: 20),
            onPressed: () {
              // TODO: Open URL in browser
            },
            color: Colors.black54,
          ),
        ],
      ),
    );
  }

  Widget _buildSocialMediaLinksDisplay(BuildContext context) {
    final loggedInUser = context.watch<UserProfileProvider>().userProfile;
    final isOwnProfile = loggedInUser?.id == userProfile.id;
    final canEditSocial =
        isOwnProfile ||
        loggedInUser?.role == 'Admin' ||
        loggedInUser?.role == 'Super Admin';

    if (userProfile.socialMediaLinks.isEmpty) {
      if (canEditSocial) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(
                Responsive.space(context, size: Space.large),
              ),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(
                  Responsive.space(context, size: Space.medium),
                ),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                children: [
                  Icon(Icons.link, size: 48, color: Colors.grey[400]),
                  SizedBox(
                    height: Responsive.space(context, size: Space.medium),
                  ),
                  Text(
                    'لا توجد روابط تواصل اجتماعي مضافة.',
                    style: TextStyle(
                      fontSize: Responsive.text(context, size: TextSize.medium),
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(
                    height: Responsive.space(context, size: Space.small),
                  ),
                  Text(
                    'اضغط على زر التعديل لإضافة روابط التواصل الاجتماعي',
                    style: TextStyle(
                      fontSize: Responsive.text(context, size: TextSize.small),
                      color: Colors.grey[500],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        );
      } else {
        return const SizedBox.shrink();
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...userProfile.socialMediaLinks.map(
          (link) => _buildSocialMediaLink(context, link),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final loggedInUser = context.watch<UserProfileProvider>().userProfile;
    final isOwnProfile = loggedInUser?.id == userProfile.id;
    final canEditSocial =
        isOwnProfile ||
        loggedInUser?.role == 'Admin' ||
        loggedInUser?.role == 'Super Admin';

    if (userProfile.socialMediaLinks.isEmpty && !canEditSocial) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'وسائل التواصل الاجتماعي',
              style: TextStyle(
                fontSize: Responsive.text(context, size: TextSize.heading),
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            if (canEditSocial)
              Container(
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(
                    Responsive.space(context, size: Space.medium),
                  ),
                ),
                child: IconButton(
                  icon: const Icon(Icons.add, color: Colors.white),
                  onPressed: () {
                    _showSocialMediaDialog(context);
                  },
                ),
              ),
          ],
        ),
        SizedBox(height: Responsive.space(context, size: Space.medium)),
        _buildSocialMediaLinksDisplay(context),
      ],
    );
  }
}
