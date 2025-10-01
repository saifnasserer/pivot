import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pivot/features/user/providers/user_profile_provider.dart';
import 'package:pivot/models/user_profile.dart';
import 'package:pivot/features/profile/screens/profile_details.dart';
import 'package:pivot/features/profile/providers/profile_provider.dart';
import 'quick_actions_section.dart';
import 'package:pivot/responsive.dart';
import 'package:pivot/widgets/unified_dialog.dart';

class ProfileDetailsTab extends ConsumerStatefulWidget {
  const ProfileDetailsTab({super.key});

  @override
  ConsumerState<ProfileDetailsTab> createState() => _ProfileDetailsTabState();
}

class _ProfileDetailsTabState extends ConsumerState<ProfileDetailsTab>
    with TickerProviderStateMixin {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final userProfileState = ref.watch(userProfileProvider);
    final userProfile = userProfileState.loggedInUserProfile;

    if (userProfile == null) {
      return _buildLoadingState();
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.grey[50]!, Colors.white],
        ),
      ),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.all(Responsive.space(context, size: Space.medium)),
        child: Column(
          children: [
            // Profile Details Section with enhanced styling
            _buildProfileDetailsSection(userProfile),

            SizedBox(height: Responsive.space(context, size: Space.large)),

            // Quick Actions Section with enhanced styling
            _buildQuickActionsSection(userProfile),

            SizedBox(height: Responsive.space(context, size: Space.large)),

            // Logout Section
            _buildLogoutSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(
              Responsive.space(context, size: Space.large),
            ),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.grey[600]!),
            ),
          ),
          SizedBox(height: Responsive.space(context, size: Space.medium)),
          Text(
            'جاري تحميل البيانات...',
            style: TextStyle(
              fontSize: Responsive.text(context, size: TextSize.medium),
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileDetailsSection(UserProfile userProfile) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(Responsive.space(context, size: Space.large)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(
          Responsive.space(context, size: Space.large),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: 1,
          ),
        ],
        border: Border.all(color: Colors.grey[200]!, width: 1),
      ),
      child: ProfileDetails(userProfile: userProfile),
    );
  }

  Widget _buildQuickActionsSection(UserProfile userProfile) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(
          Responsive.space(context, size: Space.large),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: 1,
          ),
        ],
        border: Border.all(color: Colors.grey[200]!, width: 1),
      ),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: QuickActionsSection(userProfile: userProfile),
      ),
    );
  }

  Widget _buildLogoutSection() {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(
            Responsive.space(context, size: Space.large),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, 8),
              spreadRadius: 1,
            ),
          ],
          border: Border.all(color: Colors.grey[200]!, width: 1),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(
              Responsive.space(context, size: Space.large),
            ),
            onTap: () => _showLogoutConfirmationDialog(context),
            child: Padding(
              padding: EdgeInsets.all(
                Responsive.space(context, size: Space.large),
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(
                      Responsive.space(context, size: Space.small),
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(
                        Responsive.space(context, size: Space.medium),
                      ),
                    ),
                    child: Icon(
                      Icons.logout,
                      color: Colors.red,
                      size: Responsive.text(context, size: TextSize.heading),
                    ),
                  ),
                  SizedBox(
                    width: Responsive.space(context, size: Space.medium),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'تسجيل الخروج',
                          style: TextStyle(
                            fontSize: Responsive.text(
                              context,
                              size: TextSize.medium,
                            ),
                            fontWeight: FontWeight.w600,
                            color: Colors.red,
                          ),
                        ),
                        SizedBox(
                          height: Responsive.space(context, size: Space.tiny),
                        ),
                        Text(
                          'تسجيل الخروج من التطبيق',
                          style: TextStyle(
                            fontSize: Responsive.text(
                              context,
                              size: TextSize.small,
                            ),
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.grey[400],
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showLogoutConfirmationDialog(BuildContext context) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return UnifiedDialog(
          title: 'تسجيل الخروج',
          content: Text('متأكد؟', textAlign: TextAlign.center),
          confirmText: 'تأكيد الخروج',
          onConfirm: () async {
            await ref.read(profileProvider.notifier).logout();
            if (!context.mounted) return;
            Navigator.of(context).pushNamedAndRemoveUntil(
              '/auth-wrapper',
              (Route<dynamic> route) => false,
            );
          },
          onCancel: () => Navigator.of(context).pop(),
        );
      },
    );
  }
}
