import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:pivot/models/user_profile.dart';
import 'package:pivot/providers/user_profile_provider.dart';
import 'package:pivot/providers/subject_provider.dart';
import 'package:pivot/screens/section3/subject_selection_screen.dart';
import 'package:pivot/responsive.dart';

class QuickActionsSection extends StatefulWidget {
  final UserProfile userProfile;

  const QuickActionsSection({super.key, required this.userProfile});

  @override
  State<QuickActionsSection> createState() => _QuickActionsSectionState();
}

class _QuickActionsSectionState extends State<QuickActionsSection>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late List<Animation<double>> _itemAnimations;

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

    // Create staggered animations for items
    _itemAnimations = List.generate(6, (index) {
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _animationController,
          curve: Interval(
            (index * 0.1).clamp(0.0, 1.0),
            ((index + 1) * 0.1).clamp(0.0, 1.0),
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
              // Header
              Row(
                children: [
                  Icon(
                    Icons.dashboard_outlined,
                    color: Colors.grey[600],
                    size: 20,
                  ),
                  SizedBox(width: Responsive.space(context, size: Space.small)),
                  Text(
                    'الوصول السريع',
                    style: TextStyle(
                      fontSize: Responsive.text(
                        context,
                        size: TextSize.heading,
                      ),
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),

              SizedBox(height: Responsive.space(context, size: Space.large)),

              // Action items in vertical column
              Column(
                children: [
                  _buildActionItem(
                    context,
                    0,
                    'تعديل البيانات',
                    Icons.edit_outlined,
                    () => Navigator.pushNamed(context, '/edit-profile'),
                  ),

                  SizedBox(
                    height: Responsive.space(context, size: Space.small),
                  ),

                  // _buildActionItem(
                  //   context,
                  //   1,
                  //   'الإشعارات',
                  //   Icons.notifications_outlined,
                  //   () => _showNotificationSettingsDialog(context),
                  // ),
                  SizedBox(
                    height: Responsive.space(context, size: Space.small),
                  ),

                  _buildActionItem(
                    context,
                    2,
                    'إرسال ملاحظات',
                    Icons.feedback_outlined,
                    () => Navigator.pushNamed(context, '/feedback'),
                  ),

                  SizedBox(
                    height: Responsive.space(context, size: Space.small),
                  ),

                  _buildRoleSpecificActionItem(context, 3),

                  // Super Admin specific items
                  if (widget.userProfile.role == 'Super Admin') ...[
                    SizedBox(
                      height: Responsive.space(context, size: Space.small),
                    ),
                    _buildActionItem(
                      context,
                      4,
                      'ادارة المستخدمين',
                      Icons.admin_panel_settings_outlined,
                      () => Navigator.pushNamed(context, '/user-management'),
                    ),

                    SizedBox(
                      height: Responsive.space(context, size: Space.small),
                    ),

                    _buildActionItem(
                      context,
                      5,
                      'ادارة المواد',
                      Icons.class_outlined,
                      () => Navigator.pushNamed(
                        context,
                        '/global-subject-management',
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleSpecificActionItem(
    BuildContext context,
    int animationIndex,
  ) {
    if (widget.userProfile.role == 'Student' ||
        widget.userProfile.role == 'Admin' ||
        widget.userProfile.role == 'Super Admin') {
      return _buildActionItem(
        context,
        animationIndex,
        'تسجيل المواد',
        Icons.school_outlined,
        () => _navigateToSubjectSelection(
          context,
          widget.userProfile.enrolledSubjects ?? [],
        ),
      );
    } else if (widget.userProfile.role == 'Professor' ||
        widget.userProfile.role == 'miniProfessor') {
      return _buildActionItem(
        context,
        animationIndex,
        'المواد الخاصة بي',
        Icons.book_outlined,
        () => _navigateToSubjectSelection(
          context,
          widget.userProfile.teachingSubjects ?? [],
        ),
      );
    } else {
      return _buildActionItem(
        context,
        animationIndex,
        'إعدادات متقدمة',
        Icons.settings_outlined,
        () => Navigator.pushNamed(context, '/advanced-settings'),
      );
    }
  }

  Widget _buildActionItem(
    BuildContext context,
    int animationIndex,
    String title,
    IconData icon,
    VoidCallback onPressed,
  ) {
    return ScaleTransition(
      scale: _itemAnimations[animationIndex],
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onPressed,
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: Responsive.space(context, size: Space.medium),
              vertical: Responsive.space(context, size: Space.small),
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!, width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Row(
              children: [
                // Icon container
                Container(
                  padding: EdgeInsets.all(
                    Responsive.space(context, size: Space.small),
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!, width: 1),
                  ),
                  child: Icon(
                    icon,
                    color: Colors.grey[700],
                    size: Responsive.text(context, size: TextSize.heading),
                  ),
                ),

                SizedBox(width: Responsive.space(context, size: Space.medium)),

                // Title
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: Responsive.text(context, size: TextSize.small),
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                      height: 1.2,
                    ),
                  ),
                ),

                // Arrow icon
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
    );
  }

  Future<void> _navigateToSubjectSelection(
    BuildContext context,
    List<String> previouslySelectedIds,
  ) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => SubjectSelectionScreen(
              previouslySelectedIds: previouslySelectedIds,
            ),
      ),
    );
    // Reset subject filter after returning
    try {
      final userProfile = context.read<UserProfileProvider>().userProfile;
      if (userProfile != null) {
        final subjectProvider = context.read<SubjectProvider>();
        subjectProvider.fetchAndFilterSubjects(userProfile);
      }
    } catch (e) {}
  }

  // Future<void> _showNotificationSettingsDialog(BuildContext context) async {
  //   final provider = context.read<ProfileProvider>();
  //   Map<String, bool> prefs = await provider.loadNotificationPreferences();

  //   return showDialog(
  //     context: context,
  //     barrierDismissible: true,
  //     builder: (BuildContext context) {
  //       return StatefulBuilder(
  //         builder: (context, setState) {
  //           return UnifiedDialog(
  //             title: 'إعدادات الإشعارات',
  //             subtitle: 'تخصيص إعدادات الإشعارات حسب احتياجاتك',
  //             content: SingleChildScrollView(
  //               child: Column(
  //                 mainAxisSize: MainAxisSize.min,
  //                 crossAxisAlignment: CrossAxisAlignment.center,
  //                 children: [
  //                   FutureBuilder<bool>(
  //                     future: provider.checkNotificationPermissions(),
  //                     builder: (context, snapshot) {
  //                       final hasPermission = snapshot.data ?? false;
  //                       return Container(
  //                         padding: EdgeInsets.all(
  //                           Responsive.space(context, size: Space.small),
  //                         ),
  //                         decoration: BoxDecoration(
  //                           color: Colors.grey.shade100,
  //                           borderRadius: BorderRadius.circular(8),
  //                           border: Border.all(color: Colors.grey.shade200),
  //                         ),
  //                         child: Column(
  //                           children: [
  //                             Row(
  //                               children: [
  //                                 Icon(
  //                                   hasPermission
  //                                       ? Icons.notifications_active
  //                                       : Icons.notifications_off,
  //                                   color:
  //                                       hasPermission
  //                                           ? Colors.green
  //                                           : Colors.red,
  //                                 ),
  //                                 SizedBox(
  //                                   width: Responsive.space(
  //                                     context,
  //                                     size: Space.small,
  //                                   ),
  //                                 ),
  //                                 Expanded(
  //                                   child: Text(
  //                                     hasPermission
  //                                         ? 'الإشعارات مفعلة'
  //                                         : 'الإشعارات معطلة',
  //                                     style: TextStyle(
  //                                       fontWeight: FontWeight.bold,
  //                                       color:
  //                                           hasPermission
  //                                               ? Colors.green
  //                                               : Colors.red,
  //                                     ),
  //                                   ),
  //                                 ),
  //                                 if (!hasPermission)
  //                                   TextButton(
  //                                     onPressed: () async {
  //                                       final granted =
  //                                           await provider
  //                                               .requestNotificationPermissions();
  //                                       if (!granted) {
  //                                         // Show permission dialog
  //                                       }
  //                                       setState(() {});
  //                                     },
  //                                     child: Text(
  //                                       'تفعيل',
  //                                       style: TextStyle(
  //                                         fontWeight: FontWeight.bold,
  //                                         color: Colors.black,
  //                                       ),
  //                                     ),
  //                                   ),
  //                               ],
  //                             ),
  //                           ],
  //                         ),
  //                       );
  //                     },
  //                   ),
  //                   SizedBox(
  //                     height: Responsive.space(context, size: Space.medium),
  //                   ),

  //                   // Notification switches
  //                   SwitchListTile(
  //                     title: Text('إشعارات المحاضرات'),
  //                     subtitle: Text('تنبيهات بمواعيد المحاضرات'),
  //                     value: prefs['classNotifications']!,
  //                     onChanged:
  //                         (value) => setState(
  //                           () => prefs['classNotifications'] = value,
  //                         ),
  //                     activeColor: Colors.green,
  //                   ),
  //                   SwitchListTile(
  //                     title: Text('إشعارات المهام'),
  //                     subtitle: Text('تنبيهات بمواعيد تسليم المهام'),
  //                     value: prefs['taskNotifications']!,
  //                     onChanged:
  //                         (value) => setState(
  //                           () => prefs['taskNotifications'] = value,
  //                         ),
  //                     activeColor: Colors.green,
  //                   ),
  //                   SwitchListTile(
  //                     title: Text('إشعارات الإعلانات'),
  //                     subtitle: Text('تنبيهات بالإعلانات الجديدة'),
  //                     value: prefs['announcementNotifications']!,
  //                     onChanged:
  //                         (value) => setState(
  //                           () => prefs['announcementNotifications'] = value,
  //                         ),
  //                     activeColor: Colors.green,
  //                   ),
  //                 ],
  //               ),
  //             ),
  //             confirmText: 'حفظ',
  //             confirmIcon: Icons.save,
  //             onConfirm: () async {
  //               await provider.saveNotificationPreferences(
  //                 classNotifications: prefs['classNotifications']!,
  //                 taskNotifications: prefs['taskNotifications']!,
  //                 announcementNotifications:
  //                     prefs['announcementNotifications']!,
  //               );
  //               Navigator.of(context).pop();
  //               ScaffoldMessenger.of(context).showSnackBar(
  //                 SnackBar(
  //                   content: Text('تم حفظ إعدادات الإشعارات'),
  //                   backgroundColor: Colors.green,
  //                   behavior: SnackBarBehavior.floating,
  //                   shape: RoundedRectangleBorder(
  //                     borderRadius: BorderRadius.circular(
  //                       Responsive.space(context, size: Space.large),
  //                     ),
  //                   ),
  //                 ),
  //               );
  //             },
  //             onCancel: () => Navigator.of(context).pop(),
  //           );
  //         },
  //       );
  //     },
  //   );
  // }
}
