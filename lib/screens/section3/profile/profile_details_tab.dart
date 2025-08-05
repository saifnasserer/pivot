import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:pivot/models/user_profile.dart';
import 'package:pivot/providers/user_profile_provider.dart';
import 'package:pivot/responsive.dart';
import 'package:pivot/screens/section3/profile_details.dart';
import 'quick_actions_section.dart';

class ProfileDetailsTab extends StatefulWidget {
  const ProfileDetailsTab({super.key});

  @override
  State<ProfileDetailsTab> createState() => _ProfileDetailsTabState();
}

class _ProfileDetailsTabState extends State<ProfileDetailsTab>
    with TickerProviderStateMixin {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProfileProvider>(
      builder: (context, userProfileProvider, child) {
        final userProfile = userProfileProvider.loggedInUserProfile;
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
            padding: EdgeInsets.all(
              Responsive.space(context, size: Space.medium),
            ),
            child: Column(
              children: [
                // Profile Details Section with enhanced styling
                _buildProfileDetailsSection(userProfile),

                SizedBox(height: Responsive.space(context, size: Space.large)),

                // Quick Actions Section with enhanced styling
                _buildQuickActionsSection(userProfile),

                // Additional info section
                // SizedBox(height: Responsive.space(context, size: Space.large)),
                // _buildAdditionalInfoSection(userProfile),
              ],
            ),
          ),
        );
      },
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
}
