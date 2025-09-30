import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pivot/models/lecture_model.dart';
import 'package:pivot/models/user_profile.dart';
import 'package:pivot/providers/doctor_subject_provider.dart';
import 'package:pivot/features/user/providers/user_profile_provider.dart';
import 'package:pivot/features/media/screens/material_links_screen.dart';
import 'package:pivot/features/administration/screens/doctor/profile/material_links_route.dart';
import 'package:pivot/providers/user_profile_provider.dart';
import 'package:provider/provider.dart';
import 'package:pivot/responsive.dart';
import 'package:pivot/widgets/unified_dialog.dart';

class SubjectModel extends StatefulWidget {
  final Lecture lecture;
  final IconData? icon;
  final bool canEdit;

  const SubjectModel({
    super.key,
    required this.lecture,
    this.icon,
    this.canEdit = false,
  });

  @override
  State<SubjectModel> createState() => _SubjectModelState();
}

class _SubjectModelState extends State<SubjectModel>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    setState(() => _isPressed = true);
    _animationController.forward();
  }

  void _onTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
    _animationController.reverse();
  }

  void _onTapCancel() {
    setState(() => _isPressed = false);
    _animationController.reverse();
  }

  Future<void> _handleNavigation() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      final userProvider = context.read<UserProfileProvider>();
      final currentUser = FirebaseAuth.instance.currentUser;

      // Try to get the current user profile
      UserProfile? loggedInUser = userProvider.loggedInUserProfile;
      if (loggedInUser == null && currentUser != null) {
        // If loggedInUserProfile is null but we have a current user, fetch their profile
        loggedInUser = await userProvider.getUserProfileById(currentUser.uid);
      }

      if (mounted) {
        Navigator.of(context).push(
          MaterialLinksRoute(
            lecture: widget.lecture,
            child: MaterialLinksScreen(
              lecture: widget.lecture,
              loggedInUser: loggedInUser,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('حدث خطأ أثناء التحميل: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<DoctorSubjectProvider>(context, listen: false);

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            margin: EdgeInsets.symmetric(
              horizontal: Responsive.space(context, size: Space.small),
              vertical: Responsive.space(context, size: Space.tiny),
            ),
            decoration: BoxDecoration(
              color: _isPressed ? Colors.grey.shade100 : Colors.white,
              borderRadius: BorderRadius.circular(
                Responsive.space(context, size: Space.large),
              ),
              border: Border.all(
                color: _isPressed ? Colors.grey.shade300 : Colors.grey.shade200,
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
                if (_isPressed)
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(
                  Responsive.space(context, size: Space.large),
                ),
                onTap: _isLoading ? null : _handleNavigation,
                onTapDown: _isLoading ? null : _onTapDown,
                onTapUp: _isLoading ? null : _onTapUp,
                onTapCancel: _isLoading ? null : _onTapCancel,
                child: Padding(
                  padding: EdgeInsets.all(
                    Responsive.space(context, size: Space.small),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (widget.canEdit)
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(
                              Responsive.space(context, size: Space.large),
                            ),
                          ),
                          child: IconButton(
                            icon: Icon(
                              Icons.delete_outline,
                              color: Colors.red.shade600,
                              size: Responsive.space(
                                context,
                                size: Space.medium,
                              ),
                            ),
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return UnifiedDialog(
                                    title: 'حذف المحتوى',
                                    subtitle: widget.lecture.title,
                                    content: const Text(
                                      'متأكد ؟ \n المحتوى هيتم حذفه بكل اللي جوا.',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                    onCancel: () => Navigator.of(context).pop(),
                                    onConfirm: () {
                                      provider.deleteLecture(widget.lecture.id);
                                      Navigator.of(context).pop();
                                    },
                                    confirmText: 'حذف',
                                    confirmIcon: Icons.delete,
                                  );
                                },
                              );
                            },
                            tooltip: 'حذف المحتوى',
                          ),
                        ),
                      SizedBox(
                        width: Responsive.space(context, size: Space.small),
                      ),
                      Expanded(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    widget.lecture.title,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.right,
                                    style: TextStyle(
                                      color:
                                          _isLoading
                                              ? Colors.grey.shade400
                                              : Colors.black87,
                                      fontSize: Responsive.text(context),
                                      fontWeight: FontWeight.w600,
                                      height: 1.3,
                                    ),
                                  ),
                                  if (_isLoading) ...[
                                    SizedBox(
                                      height: Responsive.space(
                                        context,
                                        size: Space.tiny,
                                      ),
                                    ),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        SizedBox(
                                          width: Responsive.space(
                                            context,
                                            size: Space.small,
                                          ),
                                          height: Responsive.space(
                                            context,
                                            size: Space.small,
                                          ),
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                  Colors.grey.shade400,
                                                ),
                                          ),
                                        ),
                                        SizedBox(
                                          width: Responsive.space(
                                            context,
                                            size: Space.tiny,
                                          ),
                                        ),
                                        Text(
                                          'جاري التحميل...',
                                          style: TextStyle(
                                            color: Colors.grey.shade500,
                                            fontSize: Responsive.text(
                                              context,
                                              size: TextSize.small,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            SizedBox(
                              width: Responsive.space(
                                context,
                                size: Space.medium,
                              ),
                            ),
                            Container(
                              width:
                                  Responsive.space(context, size: Space.large) *
                                  2.5,
                              height:
                                  Responsive.space(context, size: Space.large) *
                                  2.5,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors:
                                      _isLoading
                                          ? [
                                            Colors.grey.shade200,
                                            Colors.grey.shade300,
                                          ]
                                          : [
                                            Colors.blue.shade50,
                                            Colors.blue.shade100,
                                          ],
                                ),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Icon(
                                widget.icon ?? Icons.menu_book_rounded,
                                size: Responsive.space(
                                  context,
                                  size: Space.large,
                                ),
                                color:
                                    _isLoading
                                        ? Colors.grey.shade400
                                        : Colors.blue.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
