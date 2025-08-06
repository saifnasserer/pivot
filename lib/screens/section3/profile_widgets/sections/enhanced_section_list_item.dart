import 'package:flutter/material.dart';
import 'package:pivot/models/section_model.dart';
import 'package:pivot/models/subject_model.dart';
import 'package:pivot/models/user_profile.dart';
import 'package:pivot/providers/subject_provider.dart';
import 'package:pivot/providers/user_profile_provider.dart';
import 'package:pivot/responsive.dart';
import 'package:provider/provider.dart';
import 'assistant_selection_dialog.dart';

/// Enhanced section list item with better design and functionality
class EnhancedSectionListItem extends StatefulWidget {
  const EnhancedSectionListItem({
    super.key,
    required this.section,
    required this.subject,
    required this.index,
  });

  final Section section;
  final Subject subject;
  final int index;

  @override
  State<EnhancedSectionListItem> createState() =>
      _EnhancedSectionListItemState();
}

class _EnhancedSectionListItemState extends State<EnhancedSectionListItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.02).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onTap() {
    final instructors =
        Provider.of<SubjectProvider>(
          context,
          listen: false,
        ).instructorsBySubject[widget.subject.id];
    final assistants =
        instructors?.where((prof) => prof.role == 'miniProfessor').toList() ??
        [];
    _showEnhancedSectionDetails(
      context,
      widget.subject,
      widget.section,
      assistants,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Padding(
            padding: EdgeInsets.only(
              bottom: Responsive.space(context, size: Space.small),
            ),
            child: Material(
              elevation: _isHovered ? 4 : 0.5,
              borderRadius: BorderRadius.circular(
                Responsive.space(context, size: Space.large),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(
                  Responsive.space(context, size: Space.large),
                ),
                onTap: _onTap,
                onHover: (hovered) {
                  setState(() {
                    _isHovered = hovered;
                  });
                  if (hovered) {
                    _animationController.forward();
                  } else {
                    _animationController.reverse();
                  }
                },
                child: Container(
                  padding: Responsive.padding(context, size: Space.medium),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(
                      Responsive.space(context, size: Space.large),
                    ),
                    border: Border.all(
                      color:
                          _isHovered
                              ? Colors.black.withOpacity(0.2)
                              : Colors.grey.shade200,
                    ),
                    gradient:
                        _isHovered
                            ? LinearGradient(
                              colors: [Colors.grey.shade50, Colors.white],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                            : null,
                  ),
                  child: Row(
                    children: [
                      // Arrow icon (RTL - on the left)
                      Icon(
                        Icons.arrow_back_ios,
                        color: _isHovered ? Colors.black : Colors.grey.shade400,
                        size: 16,
                      ),

                      // Section info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              widget.subject.name,
                              style: TextStyle(
                                fontSize: Responsive.text(
                                  context,
                                  size: TextSize.medium,
                                ),
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.right,
                            ),
                            SizedBox(
                              height: Responsive.space(
                                context,
                                size: Space.small,
                              ),
                            ),
                            Wrap(
                              spacing: Responsive.space(
                                context,
                                size: Space.small,
                              ),
                              runSpacing: Responsive.space(
                                context,
                                size: Space.tiny,
                              ),
                              alignment: WrapAlignment.end,
                              children: [
                                _buildInfoChip(
                                  context,
                                  widget.section.location,
                                  Colors.green,
                                ),
                                _buildInfoChip(
                                  context,
                                  '${widget.section.days} - ${widget.section.time}',
                                  Colors.orange,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      SizedBox(
                        width: Responsive.space(context, size: Space.medium),
                      ),

                      // Section icon (RTL - on the right)
                      Container(
                        padding: EdgeInsets.all(
                          Responsive.space(context, size: Space.small),
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(
                            Responsive.space(context, size: Space.medium),
                          ),
                        ),
                        child: Icon(
                          Icons.class_,
                          color: Colors.black,
                          size: Responsive.text(context, size: TextSize.medium),
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

  Widget _buildInfoChip(BuildContext context, String text, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: Responsive.space(context, size: Space.small),
        vertical: Responsive.space(context, size: Space.tiny),
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(
          Responsive.space(context, size: Space.small),
        ),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: Responsive.text(context, size: TextSize.small),
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  void _showEnhancedSectionDetails(
    BuildContext context,
    Subject subject,
    Section section,
    List<UserProfile> assistants,
  ) async {
    final userProfileProvider = Provider.of<UserProfileProvider>(
      context,
      listen: false,
    );
    final currentUser = userProfileProvider.userProfile;
    final currentAssistantId = currentUser?.assistantPreferences[subject.id];

    // Auto-select if only one assistant
    String? selectedAssistantId = currentAssistantId;
    if (assistants.length == 1 && selectedAssistantId == null) {
      selectedAssistantId = assistants.first.id;
      // Auto-save the preference
      try {
        final loggedInUser = userProfileProvider.loggedInUserProfile;
        if (loggedInUser != null) {
          await userProfileProvider.updateAssistantPreferences({
            ...loggedInUser.assistantPreferences,
            subject.id: selectedAssistantId,
          });
          print(
            'Auto-saved assistant preference: ${subject.id} -> $selectedAssistantId',
          );
        }
      } catch (e) {
        print('Failed to auto-save assistant preference: $e');
      }
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(
                Responsive.space(context, size: Space.large),
              ),
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.8,
                maxWidth: MediaQuery.of(context).size.width * 0.9,
              ),
              child: AssistantSelectionDialog(
                subject: subject,
                section: section,
                assistants: assistants,
                selectedAssistantId: null, // Dialog will read from provider
                onAssistantSelected: (assistantId) async {
                  try {
                    // Get the current logged-in user profile
                    final loggedInUser =
                        userProfileProvider.loggedInUserProfile;
                    if (loggedInUser == null) {
                      throw Exception('No logged-in user found');
                    }

                    print(
                      'Saving assistant preference: ${subject.id} -> $assistantId',
                    );
                    print(
                      'Current preferences: ${loggedInUser.assistantPreferences}',
                    );

                    await userProfileProvider.updateAssistantPreferences({
                      ...loggedInUser.assistantPreferences,
                      subject.id: assistantId,
                    });
                    // Show success message
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('تم حفظ اختيار المعيد بنجاح'),
                        backgroundColor: Colors.green,
                        duration: Duration(seconds: 2),
                      ),
                    );
                    // Close the dialog after successful update
                    Navigator.of(context).pop();
                  } catch (e) {
                    print('Failed to update assistant preference: $e');
                    // Show error message to user
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('فشل في حفظ اختيار المعيد'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    // Re-throw to let the dialog handle the error state
                    rethrow;
                  }
                },
              ),
            ),
          ),
    );
  }
}
