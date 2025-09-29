import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:pivot/models/user_profile.dart';
import 'package:pivot/providers/user_profile_provider.dart';
import 'package:pivot/responsive.dart';
import 'package:pivot/widgets/unified_dialog.dart';
import 'package:pivot/features/administration/screens/doctor/edit_about_route.dart';
import 'package:provider/provider.dart';

class SocialMediaOption {
  final String name;
  final String displayName;
  final IconData icon;
  final Color color;
  final String urlPrefix;

  const SocialMediaOption({
    required this.name,
    required this.displayName,
    required this.icon,
    required this.color,
    required this.urlPrefix,
  });
}

class ContactInfoWidget extends StatelessWidget {
  final UserProfile userProfile;
  final bool isOwnProfile;
  final Function(UserProfile)? onProfileUpdated;

  const ContactInfoWidget({
    super.key,
    required this.userProfile,
    this.isOwnProfile = false,
    this.onProfileUpdated,
  });

  static const List<SocialMediaOption> socialMediaOptions = [
    SocialMediaOption(
      name: 'facebook',
      displayName: 'Facebook',
      icon: Icons.facebook,
      color: Color(0xFF1877F2),
      urlPrefix: 'https://www.facebook.com/',
    ),
    SocialMediaOption(
      name: 'youtube',
      displayName: 'YouTube',
      icon: Icons.play_circle,
      color: Color(0xFFFF0000),
      urlPrefix: 'https://www.youtube.com/',
    ),
    SocialMediaOption(
      name: 'linkedin',
      displayName: 'LinkedIn',
      icon: Icons.work,
      color: Color(0xFF0077B5),
      urlPrefix: 'https://www.linkedin.com/in/',
    ),
    SocialMediaOption(
      name: 'researchgate',
      displayName: 'ResearchGate',
      icon: Icons.school,
      color: Color(0xFF00CCBB),
      urlPrefix: 'https://www.researchgate.net/profile/',
    ),
    SocialMediaOption(
      name: 'googlescholar',
      displayName: 'Google Scholar',
      icon: Icons.science,
      color: Color(0xFF4285F4),
      urlPrefix: 'https://scholar.google.com/citations?user=',
    ),
    SocialMediaOption(
      name: 'benha',
      displayName: 'Benha University Profile',
      icon: Icons.account_balance,
      color: Color(0xFF2E7D32),
      urlPrefix: 'https://',
    ),
  ];

  Widget _buildContactRow(
    BuildContext context,
    IconData icon,
    String label,
    String value,
    VoidCallback? onTap,
  ) {
    return Container(
      margin: EdgeInsets.only(
        bottom: Responsive.space(context, size: Space.medium),
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
              color: Colors.black,
              borderRadius: BorderRadius.circular(
                Responsive.space(context, size: Space.medium),
              ),
            ),
            child: Icon(
              icon,
              size: Responsive.text(context, size: TextSize.medium),
              color: Colors.white,
            ),
          ),
          SizedBox(width: Responsive.space(context, size: Space.medium)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: Responsive.text(context, size: TextSize.small),
                    fontWeight: FontWeight.w600,
                    color: Colors.black54,
                  ),
                ),
                SizedBox(height: Responsive.space(context, size: Space.small)),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: Responsive.text(context, size: TextSize.medium),
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          if (onTap != null)
            Container(
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(
                  Responsive.space(context, size: Space.medium),
                ),
              ),
              child: IconButton(
                icon: Icon(Icons.open_in_new, size: 20),
                onPressed: onTap,
                color: Colors.black54,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSocialMediaIcons(BuildContext context) {
    final loggedInUser = context.watch<UserProfileProvider>().userProfile;
    final canEditSocial =
        isOwnProfile ||
        loggedInUser?.role == 'Admin' ||
        loggedInUser?.role == 'Super Admin';

    if (userProfile.socialMediaLinks.isEmpty) {
      if (canEditSocial) {
        return Container(
          padding: EdgeInsets.all(
            Responsive.space(context, size: Space.medium),
          ),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(
              Responsive.space(context, size: Space.medium),
            ),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: () => _showAddSocialMediaDialog(context),
                child: Container(
                  width: Responsive.space(context, size: Space.large) * 2,
                  height: Responsive.space(context, size: Space.large) * 2,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                        spreadRadius: 1,
                      ),
                    ],
                    border: Border.all(color: Colors.grey[400]!, width: 2),
                  ),
                  child: Icon(
                    Icons.add,
                    color: Colors.black54,
                    size: Responsive.text(context, size: TextSize.heading),
                  ),
                ),
              ),
            ],
          ),
        );
      }
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(Responsive.space(context, size: Space.medium)),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(
          Responsive.space(context, size: Space.medium),
        ),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: [
            ...userProfile.socialMediaLinks.map((link) {
              final option = socialMediaOptions.firstWhere(
                (opt) => opt.name.toLowerCase() == link.platform.toLowerCase(),
                orElse: () => socialMediaOptions.last, // benha as fallback
              );

              return Container(
                margin: EdgeInsets.only(
                  right: Responsive.space(context, size: Space.medium),
                ),
                child: GestureDetector(
                  onTap: () => _launchUrl(context, link.url),
                  child: Container(
                    width: Responsive.space(context, size: Space.large) * 2,
                    height: Responsive.space(context, size: Space.large) * 2,
                    decoration: BoxDecoration(
                      color: option.color,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: option.color.withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                          spreadRadius: 1,
                        ),
                      ],
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: Icon(
                      option.icon,
                      color: Colors.white,
                      size: Responsive.text(context, size: TextSize.heading),
                    ),
                  ),
                ),
              );
            }),
            if (canEditSocial)
              Container(
                margin: EdgeInsets.only(
                  right: Responsive.space(context, size: Space.medium),
                ),
                child: GestureDetector(
                  onTap: () => _showAddSocialMediaDialog(context),
                  child: Container(
                    width: Responsive.space(context, size: Space.large) * 2,
                    height: Responsive.space(context, size: Space.large) * 2,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                          spreadRadius: 1,
                        ),
                      ],
                      border: Border.all(color: Colors.grey[400]!, width: 2),
                    ),
                    child: Icon(
                      Icons.add,
                      color: Colors.black54,
                      size: Responsive.text(context, size: TextSize.heading),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showAddSocialMediaDialog(BuildContext context) {
    SocialMediaOption? selectedOption;
    final TextEditingController urlController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return UnifiedDialog(
              title: 'إضافة وسيلة تواصل اجتماعي',
              subtitle: 'اختر المنصة وأضف الرابط الكامل',
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Platform selection
                  DropdownButtonFormField<SocialMediaOption>(
                    initialValue: selectedOption,
                    decoration: InputDecoration(
                      labelText: 'المنصة',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          Responsive.space(context, size: Space.medium),
                        ),
                      ),
                    ),
                    items:
                        socialMediaOptions.map((option) {
                          return DropdownMenuItem(
                            value: option,
                            child: Row(
                              children: [
                                Icon(option.icon, color: option.color),
                                SizedBox(
                                  width: Responsive.space(
                                    context,
                                    size: Space.small,
                                  ),
                                ),
                                Text(option.displayName),
                              ],
                            ),
                          );
                        }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedOption = value;
                      });
                    },
                  ),
                  SizedBox(
                    height: Responsive.space(context, size: Space.medium),
                  ),

                  // URL input - always ask for full URL
                  if (selectedOption != null)
                    UnifiedFormField(
                      controller: urlController,
                      label: 'الرابط الكامل',
                      hint:
                          selectedOption!.name == 'facebook'
                              ? 'https://www.facebook.com/username'
                              : selectedOption!.name == 'youtube'
                              ? 'https://www.youtube.com/channel/username'
                              : selectedOption!.name == 'linkedin'
                              ? 'https://www.linkedin.com/in/username'
                              : selectedOption!.name == 'researchgate'
                              ? 'https://www.researchgate.net/profile/username'
                              : selectedOption!.name == 'googlescholar'
                              ? 'https://scholar.google.com/citations?user=username'
                              : selectedOption!.name == 'benha'
                              ? 'https://benha.edu.eg/profile/username'
                              : 'https://example.com',
                    ),
                ],
              ),
              confirmText: 'إضافة',
              confirmIcon: Icons.add_link,
              onConfirm: () async {
                if (selectedOption != null && urlController.text.isNotEmpty) {
                  String url = urlController.text.trim();

                  // Ensure URL has protocol
                  if (!url.startsWith('http://') &&
                      !url.startsWith('https://')) {
                    url = 'https://$url';
                  }

                  final newLink = SocialMediaLink(
                    platform: selectedOption!.name,
                    url: url,
                    displayName: selectedOption!.displayName,
                  );

                  final updatedLinks = [
                    ...userProfile.socialMediaLinks,
                    newLink,
                  ];

                  try {
                    await context
                        .read<UserProfileProvider>()
                        .updateSocialMediaLinks(userProfile.id, updatedLinks);

                    // Update the local userProfile to trigger UI refresh
                    if (onProfileUpdated != null) {
                      final updatedProfile = userProfile.copyWith(
                        socialMediaLinks: updatedLinks,
                      );
                      onProfileUpdated!(updatedProfile);
                    }

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

  Future<void> _launchUrl(BuildContext context, String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw 'Could not launch $url';
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('فشل في فتح الرابط: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final loggedInUser = context.watch<UserProfileProvider>().userProfile;
    final canEdit =
        isOwnProfile ||
        loggedInUser?.role == 'Admin' ||
        loggedInUser?.role == 'Super Admin';

    return _buildSocialMediaIcons(context);
  }

  void _navigateToEditAbout(BuildContext context) {
    Navigator.push(
      context,
      AnimatedEditAboutRoute(
        userProfile: userProfile,
        initialAboutText: userProfile.aboutMe,
      ),
    ).then((result) {
      if (result == true && onProfileUpdated != null) {
        // Call the callback to refresh the profile data if edit was successful
        onProfileUpdated!(userProfile);
      }
    });
  }
}
