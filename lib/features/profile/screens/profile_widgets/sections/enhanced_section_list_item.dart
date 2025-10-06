import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pivot/models/section_model.dart';
import 'package:pivot/models/user_profile.dart';
import 'package:pivot/features/subjects/providers/subjects_provider.dart';
import 'package:pivot/features/user/providers/user_profile_provider.dart';
import 'package:pivot/responsive.dart';
import 'package:pivot/models/subject_model.dart';
import 'package:pivot/widgets/unified_dialog.dart';
import 'package:pivot/screens/models/instructors_gate.dart';

/// Enhanced section list item with simplified approach - similar to subjects
class EnhancedSectionListItem extends ConsumerStatefulWidget {
  const EnhancedSectionListItem({
    super.key,
    required this.subject,
    required this.sections,
    required this.index,
  });

  final Subject subject;
  final List<Section> sections;
  final int index;

  @override
  ConsumerState<EnhancedSectionListItem> createState() =>
      _EnhancedSectionListItemState();
}

class _EnhancedSectionListItemState
    extends ConsumerState<EnhancedSectionListItem>
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
    final subjectsState = ref.read(subjectsProvider);
    final instructors =
        subjectsState.instructorsBySubject[widget.subject.id] ?? [];

    print('🎯 EnhancedSectionListItem: Clicked ${widget.subject.name}');
    print(
      '📊 EnhancedSectionListItem: Found ${instructors.length} instructors',
    );

    // Filter assistants for configuration
    final assistants =
        instructors.where((prof) => prof.role == 'miniProfessor').toList();

    print('📊 EnhancedSectionListItem: Found ${assistants.length} assistants');

    // If there are instructors, show InstructorsGate dialog
    if (instructors.isNotEmpty) {
      _showInstructorsGateDialog(instructors, assistants);
    } else {
      // Show a simple dialog for subjects without instructors
      print(
        '⚠️ EnhancedSectionListItem: No instructors found, showing placeholder',
      );
      _showNoInstructorsDialog();
    }
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
                                // Show section info if available, otherwise show placeholder
                                if (widget.sections.isNotEmpty)
                                  ...widget.sections
                                      .take(1)
                                      .map(
                                        (section) => [
                                          _buildInfoChip(
                                            context,
                                            section.location,
                                            Colors.green,
                                          ),
                                          _buildInfoChip(
                                            context,
                                            '${section.days} - ${section.time}',
                                            Colors.orange,
                                          ),
                                        ],
                                      )
                                      .expand((e) => e)
                                else
                                  _buildInfoChip(
                                    context,
                                    'سيتم إضافة السكشن قريباً',
                                    Colors.grey,
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
                          color:
                              widget.sections.isNotEmpty
                                  ? Colors.black.withOpacity(0.1)
                                  : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(
                            Responsive.space(context, size: Space.medium),
                          ),
                        ),
                        child: Icon(
                          Icons.class_,
                          color:
                              widget.sections.isNotEmpty
                                  ? Colors.black
                                  : Colors.grey.shade400,
                          size: 20,
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
          Responsive.space(context, size: Space.medium),
        ),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
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

  void _showNoInstructorsDialog() {
    showDialog(
      context: context,
      builder:
          (context) => UnifiedDialog(
            title: widget.subject.name,
            content: Padding(
              padding: EdgeInsets.symmetric(
                vertical: Responsive.space(context, size: Space.large),
              ),
              child: Text(
                'لا يوجد معيدين أو دكاترة مسجلين لهذه المادة بعد',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: Responsive.text(context, size: TextSize.medium),
                  color: Colors.black87,
                ),
              ),
            ),
            showActions: true,
            confirmText: 'اوكي',
            onConfirm: () => Navigator.of(context).pop(),
            onCancel: null,
            actions: null,
          ),
    );
  }

  void _showInstructorsGateDialog(
    List<UserProfile> instructors,
    List<UserProfile> assistants,
  ) async {
    final userProfileState = ref.read(userProfileProvider);
    final currentUser = userProfileState.loggedInUserProfile;
    final currentAssistantId =
        currentUser?.assistantPreferences[widget.subject.id];

    // Auto-save preference if only one assistant
    if (assistants.length == 1 && currentAssistantId != assistants.first.id) {
      try {
        final loggedInUser = userProfileState.loggedInUserProfile;
        if (loggedInUser != null) {
          await ref
              .read(userProfileProvider.notifier)
              .updateAssistantPreferences({
                ...loggedInUser.assistantPreferences,
                widget.subject.id: assistants.first.id,
              });
        }
      } catch (e) {
        print('⚠️ Failed to auto-save single assistant preference: $e');
      }
    }

    // Check if widget is still mounted after async operations
    if (!mounted) return;

    // Show InstructorsGate dialog with assistants configuration
    bool saveSucceeded = false;
    bool saveFailed = false;

    try {
      await showInstructorsGate(
        context: context,
        ref: ref,
        subject: widget.subject,
        instructors: assistants.isNotEmpty ? assistants : instructors,
        config:
            assistants.isNotEmpty
                ? InstructorsGateConfig.assistants.copyWith(
                  enableSelection: true,
                  enableEditMode:
                      assistants.length >
                      1, // Only enable edit if multiple assistants
                  onInstructorSelected: (assistantId) async {
                    final userProfileState = ref.read(userProfileProvider);
                    final loggedInUser = userProfileState.loggedInUserProfile;
                    if (loggedInUser == null) {
                      throw Exception('No logged-in user found');
                    }

                    await ref
                        .read(userProfileProvider.notifier)
                        .updateAssistantPreferences({
                          ...loggedInUser.assistantPreferences,
                          widget.subject.id: assistantId,
                        });

                    // Mark save as successful
                    saveSucceeded = true;
                  },
                )
                : InstructorsGateConfig.professors,
        selectedInstructorId: currentAssistantId,
        section: widget.sections.isNotEmpty ? widget.sections.first : null,
      );
    } catch (e) {
      saveFailed = true;
      print('❌ Failed to save assistant preference: $e');
    }

    // Show feedback after dialog closes
    if (!mounted) return;

    if (saveSucceeded && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم حفظ اختيار المعيد بنجاح'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    } else if (saveFailed && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('فشل في حفظ اختيار المعيد'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
