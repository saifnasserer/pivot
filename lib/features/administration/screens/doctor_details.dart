import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pivot/models/user_profile.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:pivot/screens/models/card_model.dart';
import 'package:pivot/responsive.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:pivot/features/user/providers/user_profile_provider.dart';

class DoctorDetails extends ConsumerStatefulWidget {
  const DoctorDetails({super.key, required this.userProfile});
  final UserProfile userProfile;

  @override
  ConsumerState<DoctorDetails> createState() => _DoctorDetailsState();
}

class _DoctorDetailsState extends ConsumerState<DoctorDetails>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

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

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _showFullScreenImage() {
    if (widget.userProfile.profileImageUrl != null &&
        widget.userProfile.profileImageUrl!.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) => FullScreenImageViewer(
                imageUrl: widget.userProfile.profileImageUrl!,
              ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
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

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Container(
          padding: EdgeInsets.all(
            Responsive.space(context, size: Space.medium),
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.grey[50]!, Colors.white],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey[200]!, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 3),
                spreadRadius: 1,
              ),
            ],
          ),
          child: Column(
            children: [
              // Profile image at the top
              GestureDetector(
                onTap: _showFullScreenImage,
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.grey[300]!, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: Responsive.space(context, size: Space.large) * 3,
                    backgroundColor: Colors.grey[200],
                    child: ClipOval(
                      child:
                          widget.userProfile.profileImageUrl != null &&
                                  widget.userProfile.profileImageUrl!.isNotEmpty
                              ? CachedNetworkImage(
                                imageUrl: widget.userProfile.profileImageUrl!,
                                width:
                                    Responsive.space(
                                      context,
                                      size: Space.large,
                                    ) *
                                    6,
                                height:
                                    Responsive.space(
                                      context,
                                      size: Space.large,
                                    ) *
                                    6,
                                fit: BoxFit.cover,
                                placeholder:
                                    (context, url) => Container(
                                      width:
                                          Responsive.space(
                                            context,
                                            size: Space.large,
                                          ) *
                                          6,
                                      height:
                                          Responsive.space(
                                            context,
                                            size: Space.large,
                                          ) *
                                          6,
                                      decoration: BoxDecoration(
                                        color: Colors.grey[200],
                                        shape: BoxShape.circle,
                                      ),
                                      child: Center(
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                Colors.grey[600]!,
                                              ),
                                        ),
                                      ),
                                    ),
                                errorWidget:
                                    (context, url, error) => Container(
                                      width:
                                          Responsive.space(
                                            context,
                                            size: Space.large,
                                          ) *
                                          6,
                                      height:
                                          Responsive.space(
                                            context,
                                            size: Space.large,
                                          ) *
                                          6,
                                      decoration: BoxDecoration(
                                        color: Colors.grey[200],
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.person,
                                        size:
                                            Responsive.space(
                                              context,
                                              size: Space.large,
                                            ) *
                                            2.5,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                              )
                              : Container(
                                width:
                                    Responsive.space(
                                      context,
                                      size: Space.large,
                                    ) *
                                    6,
                                height:
                                    Responsive.space(
                                      context,
                                      size: Space.large,
                                    ) *
                                    6,
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.person,
                                  size:
                                      Responsive.space(
                                        context,
                                        size: Space.large,
                                      ) *
                                      2.5,
                                  color: Colors.grey[600],
                                ),
                              ),
                    ),
                  ),
                ),
              ),

              SizedBox(height: Responsive.space(context, size: Space.medium)),

              // Title
              Text(
                displayTitle,
                style: TextStyle(
                  fontSize: Responsive.text(context, size: TextSize.small),
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),

              SizedBox(height: Responsive.space(context, size: Space.small)),

              // Name
              AutoSizeText(
                widget.userProfile.name,
                style: TextStyle(
                  fontSize: Responsive.text(context, size: TextSize.heading),
                  color: Colors.black87,
                  fontWeight: FontWeight.bold,
                  height: 1.1,
                ),
                maxLines: 2,
                minFontSize: 14,
                stepGranularity: 1,
                textAlign: TextAlign.center,
              ),

              SizedBox(height: Responsive.space(context, size: Space.small)),

              // Role badge
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: Responsive.space(context, size: Space.medium),
                  vertical: Responsive.space(context, size: Space.small),
                ),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.blue.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.school, size: 16, color: Colors.blue[700]),
                    SizedBox(
                      width: Responsive.space(context, size: Space.small),
                    ),
                    Text(
                      widget.userProfile.role,
                      style: TextStyle(
                        fontSize: Responsive.text(
                          context,
                          size: TextSize.small,
                        ),
                        color: Colors.blue[700],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: Responsive.space(context, size: Space.small)),

              // Department info
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: Responsive.space(context, size: Space.medium),
                  vertical: Responsive.space(context, size: Space.small),
                ),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.grey[300]!, width: 1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      size: 16,
                      color: Colors.grey[600],
                    ),
                    SizedBox(
                      width: Responsive.space(context, size: Space.small),
                    ),
                    AutoSizeText(
                      widget.userProfile.department,
                      style: TextStyle(
                        fontSize: Responsive.text(
                          context,
                          size: TextSize.small,
                        ),
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      minFontSize: 12,
                      stepGranularity: 1,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
