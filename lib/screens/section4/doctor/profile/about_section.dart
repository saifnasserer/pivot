import 'package:flutter/material.dart';
import 'package:pivot/models/user_profile.dart';
import 'package:pivot/screens/section4/doctor_details.dart';
import 'package:pivot/screens/section4/doctor/profile/about_me_widget.dart';
import 'package:pivot/screens/section4/doctor/profile/contact_info_widget.dart';
import 'package:pivot/responsive.dart';


class AboutSection extends StatefulWidget {
  final UserProfile userProfile;
  final bool isOwnProfile;
  final Function(UserProfile)? onProfileUpdated;

  const AboutSection({
    super.key,
    required this.userProfile,
    required this.isOwnProfile,
    this.onProfileUpdated,
  });

  @override
  State<AboutSection> createState() => _AboutSectionState();
}

class _AboutSectionState extends State<AboutSection>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late List<Animation<double>> _sectionAnimations;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );

    // Create staggered animations for sections
    _sectionAnimations = List.generate(3, (index) {
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _animationController,
          curve: Interval(
            (index * 0.15).clamp(0.0, 1.0),
            ((index + 1) * 0.15).clamp(0.0, 1.0),
            curve: Curves.easeOut,
          ),
        ),
      );
    });

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.grey[50]!, Colors.white],
            ),
          ),
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  // Doctor Details Section with enhanced styling
                  _buildDoctorDetailsSection(),

                  SizedBox(
                    height: Responsive.space(context, size: Space.large),
                  ),

                  // About Me Section with enhanced styling
                  _buildAboutMeSection(),

                  SizedBox(
                    height: Responsive.space(context, size: Space.large),
                  ),

                  // Contact Information Section with enhanced styling (includes social media)
                  _buildContactInfoSection(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDoctorDetailsSection() {
    return FadeTransition(
      opacity: _sectionAnimations[0],
      child: Container(
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
        child: DoctorDetails(userProfile: widget.userProfile),
      ),
    );
  }

  Widget _buildAboutMeSection() {
    return FadeTransition(
      opacity: _sectionAnimations[1],
      child: Container(
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
        child: AboutMeWidget(
          userProfile: widget.userProfile,
          isOwnProfile: widget.isOwnProfile,
          onProfileUpdated: widget.onProfileUpdated,
        ),
      ),
    );
  }

  Widget _buildContactInfoSection() {
    return FadeTransition(
      opacity: _sectionAnimations[2],
      child: Container(
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
        child: ContactInfoWidget(
          userProfile: widget.userProfile,
          isOwnProfile: widget.isOwnProfile,
          onProfileUpdated: widget.onProfileUpdated,
        ),
      ),
    );
  }
}
