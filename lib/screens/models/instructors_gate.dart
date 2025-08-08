import 'package:flutter/material.dart';
import 'package:pivot/models/user_profile.dart';
import 'package:pivot/models/subject_model.dart';
import 'package:pivot/models/section_model.dart';
import 'package:pivot/providers/user_profile_provider.dart';
import 'package:pivot/responsive.dart';
import 'package:provider/provider.dart';

/// Configuration for the InstructorsGate dialog
class InstructorsGateConfig {
  final String title;
  final String emptyMessage;
  final String instructorType; // 'professor', 'assistant', 'instructor'
  final String instructorLabel; // 'دكتور', 'معيد', 'مدرس'
  final String defaultInstructorLabel; // 'دكتور افتراضي', 'معيد افتراضي'
  final IconData icon;
  final Color primaryColor;
  final bool enableSelection;
  final bool enableEditMode;
  final Function(String)? onInstructorSelected;
  final Function(UserProfile)? onInstructorTapped;

  const InstructorsGateConfig({
    required this.title,
    required this.emptyMessage,
    required this.instructorType,
    required this.instructorLabel,
    required this.defaultInstructorLabel,
    required this.icon,
    required this.primaryColor,
    this.enableSelection = false,
    this.enableEditMode = false,
    this.onInstructorSelected,
    this.onInstructorTapped,
  });

  /// Create a copy of this config with modified values
  InstructorsGateConfig copyWith({
    String? title,
    String? emptyMessage,
    String? instructorType,
    String? instructorLabel,
    String? defaultInstructorLabel,
    IconData? icon,
    Color? primaryColor,
    bool? enableSelection,
    bool? enableEditMode,
    Function(String)? onInstructorSelected,
    Function(UserProfile)? onInstructorTapped,
  }) {
    return InstructorsGateConfig(
      title: title ?? this.title,
      emptyMessage: emptyMessage ?? this.emptyMessage,
      instructorType: instructorType ?? this.instructorType,
      instructorLabel: instructorLabel ?? this.instructorLabel,
      defaultInstructorLabel:
          defaultInstructorLabel ?? this.defaultInstructorLabel,
      icon: icon ?? this.icon,
      primaryColor: primaryColor ?? this.primaryColor,
      enableSelection: enableSelection ?? this.enableSelection,
      enableEditMode: enableEditMode ?? this.enableEditMode,
      onInstructorSelected: onInstructorSelected ?? this.onInstructorSelected,
      onInstructorTapped: onInstructorTapped ?? this.onInstructorTapped,
    );
  }

  /// Predefined configurations
  static const professors = InstructorsGateConfig(
    title: 'دكاترة المادة',
    emptyMessage: 'لا يوجد دكاترة مسجلين لهذه المادة بعد',
    instructorType: 'professor',
    instructorLabel: 'دكتور',
    defaultInstructorLabel: 'دكتور افتراضي',
    icon: Icons.people,
    primaryColor: Colors.blue,
    enableSelection: false,
    enableEditMode: false,
  );

  static const assistants = InstructorsGateConfig(
    title: 'المعيدين',
    emptyMessage: 'لا يوجد معيدين مسجلين لهذه المادة بعد',
    instructorType: 'assistant',
    instructorLabel: 'معيد',
    defaultInstructorLabel: 'معيد افتراضي',
    icon: Icons.people_outline,
    primaryColor: Colors.orange,
    enableSelection: true,
    enableEditMode: true,
  );

  static const instructors = InstructorsGateConfig(
    title: 'المدرسين',
    emptyMessage: 'لا يوجد مدرسين مسجلين لهذه المادة بعد',
    instructorType: 'instructor',
    instructorLabel: 'مدرس',
    defaultInstructorLabel: 'مدرس افتراضي',
    icon: Icons.school,
    primaryColor: Colors.green,
    enableSelection: false,
    enableEditMode: false,
  );
}

/// Reusable dialog for displaying and selecting instructors
class InstructorsGate extends StatefulWidget {
  final Subject subject;
  final List<UserProfile> instructors;
  final InstructorsGateConfig config;
  final String? selectedInstructorId;
  final Section? section; // Optional, for section-specific details

  const InstructorsGate({
    super.key,
    required this.subject,
    required this.instructors,
    required this.config,
    this.selectedInstructorId,
    this.section,
  });

  @override
  State<InstructorsGate> createState() => _InstructorsGateState();
}

class _InstructorsGateState extends State<InstructorsGate> {
  String? _selectedInstructorId;
  bool _isSaving = false;
  bool _isEditMode = false;

  @override
  void initState() {
    super.initState();
    _selectedInstructorId = widget.selectedInstructorId;

    // Initialize with current preference if in selection mode
    if (widget.config.enableSelection) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (mounted) {
          final userProfileProvider = Provider.of<UserProfileProvider>(
            context,
            listen: false,
          );

          // Ensure we're using the logged-in user's profile
          userProfileProvider.ensureLoggedInUserProfileIsCurrent();

          final currentUser = userProfileProvider.loggedInUserProfile;
          if (currentUser != null) {
            final currentInstructorId =
                currentUser.assistantPreferences[widget.subject.id];

            print(
              'InstructorsGate reading preference for ${widget.subject.id}: $currentInstructorId',
            );
            print(
              'Current user assistant preferences: ${currentUser.assistantPreferences}',
            );

            setState(() {
              _selectedInstructorId =
                  currentInstructorId ?? widget.selectedInstructorId;
            });
          }
        }
      });
    }
  }

  void _toggleEditMode() {
    if (mounted) {
      setState(() {
        _isEditMode = !_isEditMode;
      });
    }
  }

  void _onInstructorSelected(String instructorId) {
    if (mounted) {
      setState(() {
        _selectedInstructorId = instructorId;
      });
    }
  }

  void _onInstructorTapped(UserProfile instructor) {
    if (widget.config.onInstructorTapped != null) {
      widget.config.onInstructorTapped!(instructor);
    } else {
      // Default navigation based on instructor type
      Navigator.of(context).pop();
      switch (widget.config.instructorType) {
        case 'professor':
          Navigator.pushNamed(
            context,
            '/doctor-profile',
            arguments: instructor,
          );
          break;
        case 'assistant':
          Navigator.pushNamed(
            context,
            '/assistant-profile',
            arguments: instructor,
          );
          break;
        default:
          Navigator.pushNamed(
            context,
            '/doctor-profile',
            arguments: instructor,
          );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Expanded(
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: SingleChildScrollView(
              padding: Responsive.padding(context, size: Space.medium),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Subject header
                  _buildSubjectHeader(),

                  SizedBox(
                    height: Responsive.space(context, size: Space.medium),
                  ),
                  Divider(thickness: 1, color: Colors.grey[200]),
                  SizedBox(
                    height: Responsive.space(context, size: Space.medium),
                  ),

                  // Section details (if provided)
                  if (widget.section != null) ...[
                    _buildSectionDetails(widget.section!),
                    SizedBox(
                      height: Responsive.space(context, size: Space.medium),
                    ),
                  ],

                  // Instructors section
                  if (widget.instructors.isNotEmpty) ...[
                    _buildInstructorsSection(),
                  ] else ...[
                    _buildNoInstructorsSection(),
                  ],
                ],
              ),
            ),
          ),
        ),

        // Footer with action buttons
        _buildFooter(),
      ],
    );
  }

  Widget _buildSubjectHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          padding: EdgeInsets.all(Responsive.space(context, size: Space.small)),
          decoration: BoxDecoration(
            color: widget.config.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(
              Responsive.space(context, size: Space.large),
            ),
          ),
          child: Icon(
            widget.config.icon,
            color: widget.config.primaryColor,
            size: Responsive.space(context, size: Space.medium),
          ),
        ),
        SizedBox(width: Responsive.space(context, size: Space.medium)),
        Expanded(
          child: Text(
            widget.subject.name,
            style: TextStyle(
              fontSize: Responsive.text(context, size: TextSize.heading),
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionDetails(Section section) {
    return Container(
      padding: Responsive.padding(context, size: Space.medium),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.grey.shade50, Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(
          Responsive.space(context, size: Space.medium),
        ),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          _buildDetailRow('السكاشن', section.name, Icons.class_, Colors.blue),
          SizedBox(height: Responsive.space(context, size: Space.small)),
          _buildDetailRow(
            'المكان',
            section.location,
            Icons.location_on_outlined,
            Colors.green,
          ),
          SizedBox(height: Responsive.space(context, size: Space.small)),
          _buildDetailRow(
            'الأيام',
            section.days,
            Icons.calendar_today,
            Colors.orange,
          ),
          SizedBox(height: Responsive.space(context, size: Space.small)),
          _buildDetailRow(
            'الوقت',
            section.time,
            Icons.access_time,
            Colors.purple,
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(Responsive.space(context, size: Space.small)),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(
              Responsive.space(context, size: Space.small),
            ),
          ),
          child: Icon(icon, color: color, size: 18),
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
                  color: Colors.grey.shade600,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: Responsive.text(context, size: TextSize.medium),
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInstructorsSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(
          Responsive.space(context, size: Space.large),
        ),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Padding(
            padding: EdgeInsets.all(
              Responsive.space(context, size: Space.medium),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Edit Button (if enabled)
                if (widget.config.enableEditMode)
                  IconButton(
                    onPressed: _toggleEditMode,
                    icon: Icon(
                      _isEditMode ? Icons.close : Icons.edit,
                      color: _isEditMode ? Colors.red : Colors.black,
                    ),
                    tooltip:
                        _isEditMode
                            ? 'إلغاء التعديل'
                            : 'تعديل ${widget.config.defaultInstructorLabel}',
                  ),
                // Status indicator
                if (widget.config.enableSelection &&
                    _selectedInstructorId != null)
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: Responsive.space(context, size: Space.small),
                      vertical: Responsive.space(context, size: Space.tiny),
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(
                        Responsive.space(context, size: Space.small),
                      ),
                      border: Border.all(color: Colors.green.withOpacity(0.3)),
                    ),
                    child: Text(
                      'تم الاختيار',
                      style: TextStyle(
                        fontSize: Responsive.text(
                          context,
                          size: TextSize.small,
                        ),
                        color: Colors.green,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                // Title
                Expanded(
                  child: Text(
                    widget.config.title,
                    style: TextStyle(
                      fontSize: Responsive.text(context, size: TextSize.medium),
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
          ),
          ListView.separated(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: widget.instructors.length,
            separatorBuilder:
                (context, index) => Divider(height: 1, color: Colors.grey[200]),
            itemBuilder: (context, index) {
              final instructor = widget.instructors[index];
              return _buildInstructorTile(instructor);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildInstructorTile(UserProfile instructor) {
    final isSelected =
        widget.config.enableSelection &&
        _isEditMode &&
        _selectedInstructorId == instructor.id;

    return ListTile(
      leading: CircleAvatar(
        backgroundColor:
            isSelected
                ? Colors.green.withOpacity(0.2)
                : Colors.black.withOpacity(0.1),
        child: Icon(
          isSelected ? Icons.check : Icons.person,
          color: isSelected ? Colors.green : Colors.black,
        ),
      ),
      title: Text(
        instructor.name,
        style: TextStyle(
          fontSize: Responsive.text(context, size: TextSize.medium),
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
      subtitle: Text(
        _isEditMode
            ? (isSelected
                ? widget.config.defaultInstructorLabel
                : 'انقر لاختيار ك${widget.config.defaultInstructorLabel}')
            : widget.config.instructorLabel,
        style: TextStyle(
          fontSize: Responsive.text(context, size: TextSize.small),
          color: isSelected ? Colors.green.shade700 : Colors.grey.shade600,
        ),
      ),
      trailing: Icon(
        _isEditMode
            ? (isSelected ? Icons.check_circle : Icons.radio_button_unchecked)
            : Icons.arrow_forward_ios,
        color: isSelected ? Colors.green : Colors.grey.shade400,
        size: 20,
      ),
      onTap:
          _isEditMode
              ? () => _onInstructorSelected(instructor.id)
              : () => _onInstructorTapped(instructor),
    );
  }

  Widget _buildNoInstructorsSection() {
    return Container(
      padding: Responsive.padding(context, size: Space.medium),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(
          Responsive.space(context, size: Space.large),
        ),
        border: Border.all(color: Colors.orange.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Colors.orange, size: 24),
          SizedBox(width: Responsive.space(context, size: Space.medium)),
          Expanded(
            child: Text(
              widget.config.emptyMessage,
              style: TextStyle(
                fontSize: Responsive.text(context, size: TextSize.small),
                color: Colors.orange,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: Responsive.padding(context, size: Space.medium),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(
            Responsive.space(context, size: Space.large),
          ),
          bottomRight: Radius.circular(
            Responsive.space(context, size: Space.large),
          ),
        ),
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          if (_isEditMode &&
              widget.config.enableSelection &&
              widget.instructors.isNotEmpty &&
              _selectedInstructorId != null)
            Expanded(
              child: ElevatedButton(
                onPressed:
                    _isSaving
                        ? null
                        : () async {
                          if (mounted) {
                            setState(() {
                              _isSaving = true;
                            });
                          }
                          try {
                            if (widget.config.onInstructorSelected != null) {
                              await widget.config.onInstructorSelected!(
                                _selectedInstructorId!,
                              );
                            }
                          } catch (e) {
                            if (mounted) {
                              setState(() {
                                _isSaving = false;
                              });
                            }
                          }
                        },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(
                    horizontal: Responsive.space(context, size: Space.large),
                    vertical: Responsive.space(context, size: Space.medium),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      Responsive.space(context, size: Space.medium),
                    ),
                  ),
                ),
                child:
                    _isSaving
                        ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                        : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.save, size: 18),
                            SizedBox(
                              width: Responsive.space(
                                context,
                                size: Space.small,
                              ),
                            ),
                            Text('حفظ الاختيار'),
                          ],
                        ),
              ),
            )
          else
            Expanded(
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey.shade300,
                  foregroundColor: Colors.black87,
                  padding: EdgeInsets.symmetric(
                    horizontal: Responsive.space(context, size: Space.large),
                    vertical: Responsive.space(context, size: Space.medium),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      Responsive.space(context, size: Space.medium),
                    ),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.close, size: 18),
                    SizedBox(
                      width: Responsive.space(context, size: Space.small),
                    ),
                    Text('إغلاق'),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Helper function to show InstructorsGate dialog
Future<void> showInstructorsGate({
  required BuildContext context,
  required Subject subject,
  required List<UserProfile> instructors,
  required InstructorsGateConfig config,
  String? selectedInstructorId,
  Section? section,
}) {
  return showDialog(
    context: context,
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
            child: InstructorsGate(
              subject: subject,
              instructors: instructors,
              config: config,
              selectedInstructorId: selectedInstructorId,
              section: section,
            ),
          ),
        ),
  ).then((_) {
    // Restore logged-in user profile when dialog is dismissed
    final userProfileProvider = Provider.of<UserProfileProvider>(
      context,
      listen: false,
    );
    userProfileProvider.restoreLoggedInUserProfile();
  });
}
