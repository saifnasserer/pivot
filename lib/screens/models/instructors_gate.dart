import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pivot/models/user_profile.dart';
import 'package:pivot/models/section_model.dart';
import 'package:pivot/features/user/providers/user_profile_provider.dart';
import 'package:pivot/responsive.dart';
import 'package:pivot/models/subject_model.dart';
import 'package:pivot/features/home/screens/adminstration/animated_route.dart';
import 'package:pivot/features/administration/screens/assistants/profile/assistant_profile_main.dart';
import 'package:pivot/features/administration/screens/doctor/profile/doctor_profile.dart';

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
class InstructorsGate extends ConsumerStatefulWidget {
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
  ConsumerState<InstructorsGate> createState() => _InstructorsGateState();
}

class _InstructorsGateState extends ConsumerState<InstructorsGate>
    with TickerProviderStateMixin {
  String? _selectedInstructorId;
  bool _isSaving = false;
  bool _isEditMode = false;

  // Animation controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _selectedInstructorId = widget.selectedInstructorId;

    // Initialize animations
    _initializeAnimations();

    // Initialize with current preference if in selection mode
    if (widget.config.enableSelection) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (mounted) {
          // Ensure we're using the logged-in user's profile
          final userProfileState = ref.read(userProfileProvider);
          final currentUser = userProfileState.loggedInUserProfile;
          if (currentUser != null) {
            final currentInstructorId =
                currentUser.assistantPreferences[widget.subject.id];

            setState(() {
              _selectedInstructorId =
                  currentInstructorId ?? widget.selectedInstructorId;
            });
          }
        }
      });
    }
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.05),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
    );

    // Start animations
    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
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
      // Default navigation based on instructor type with AnimatedAddRoute
      // Create navigation arguments that include both instructor and subject
      final navigationArgs = {
        'instructor': instructor,
        'subject': widget.subject,
        'fromSubject': true, // Flag to indicate we came from a subject
      };

      Widget destinationScreen;
      switch (widget.config.instructorType) {
        case 'professor':
          destinationScreen = const DoctorProfile();
          break;
        case 'assistant':
          destinationScreen = const AssistantProfileMain();
          break;
        default:
          destinationScreen = const DoctorProfile();
      }

      Navigator.of(context).pushReplacement(
        AnimatedAddRoute(
          startPosition: Offset.zero,
          child: destinationScreen,
          arguments: navigationArgs,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back, color: Colors.black),
          ),
          title: Text(
            widget.config.title,
            style: TextStyle(
              fontSize: Responsive.text(context, size: TextSize.heading),
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          centerTitle: true,
          actions: [
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
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              // Animated content
              Expanded(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: SingleChildScrollView(
                      padding: Responsive.padding(context, size: Space.large),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          // Subject header
                          _buildSubjectHeader(),

                          SizedBox(
                            height: Responsive.space(
                              context,
                              size: Space.medium,
                            ),
                          ),
                          Divider(thickness: 1, color: Colors.grey[200]),
                          SizedBox(
                            height: Responsive.space(
                              context,
                              size: Space.medium,
                            ),
                          ),

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
              ),

              // Footer with action buttons
              _buildFooter(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSubjectHeader() {
    return Container(
      padding: Responsive.padding(context, size: Space.medium),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            widget.config.primaryColor.withOpacity(0.1),
            widget.config.primaryColor.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(
          Responsive.space(context, size: Space.medium),
        ),
        border: Border.all(color: widget.config.primaryColor.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'المادة',
                  style: TextStyle(
                    fontSize: Responsive.text(context, size: TextSize.small),
                    color: Colors.grey.shade600,
                  ),
                  textAlign: TextAlign.right,
                ),
                SizedBox(height: Responsive.space(context, size: Space.tiny)),
                Text(
                  widget.subject.name,
                  style: TextStyle(
                    fontSize: Responsive.text(context, size: TextSize.heading),
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.right,
                ),
              ],
            ),
          ),
          // SizedBox(width: Responsive.space(context, size: Space.medium)),
          // Container(
          //   padding: EdgeInsets.all(
          //     Responsive.space(context, size: Space.medium),
          //   ),
          //   decoration: BoxDecoration(
          //     color: widget.config.primaryColor.withOpacity(0.15),
          //     borderRadius: BorderRadius.circular(
          //       Responsive.space(context, size: Space.medium),
          //     ),
          //   ),
          //   child: Icon(
          //     widget.config.icon,
          //     color: widget.config.primaryColor,
          //     size: Responsive.space(context, size: Space.large),
          //   ),
          // ),
        ],
      ),
    );
  }

  Widget _buildInstructorsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Status indicator
        if (widget.config.enableSelection && _selectedInstructorId != null)
          Container(
            margin: EdgeInsets.only(
              bottom: Responsive.space(context, size: Space.medium),
            ),
            padding: EdgeInsets.symmetric(
              horizontal: Responsive.space(context, size: Space.medium),
              vertical: Responsive.space(context, size: Space.small),
            ),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(
                Responsive.space(context, size: Space.medium),
              ),
              border: Border.all(color: Colors.green.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Text(
                  'تم الاختيار',
                  style: TextStyle(
                    fontSize: Responsive.text(context, size: TextSize.medium),
                    color: Colors.green,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(width: Responsive.space(context, size: Space.small)),
                Icon(Icons.check_circle, color: Colors.green, size: 20),
              ],
            ),
          ),

        // Instructors list
        ListView.separated(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: widget.instructors.length,
          separatorBuilder:
              (context, index) => SizedBox(
                height: Responsive.space(context, size: Space.small),
              ),
          itemBuilder: (context, index) {
            final instructor = widget.instructors[index];
            return _buildInstructorTile(instructor);
          },
        ),
      ],
    );
  }

  Widget _buildInstructorTile(UserProfile instructor) {
    final isSelected =
        widget.config.enableSelection &&
        _isEditMode &&
        _selectedInstructorId == instructor.id;

    return Container(
      decoration: BoxDecoration(
        color: isSelected ? Colors.green.withOpacity(0.05) : Colors.white,
        borderRadius: BorderRadius.circular(
          Responsive.space(context, size: Space.medium),
        ),
        border: Border.all(
          color:
              isSelected ? Colors.green.withOpacity(0.3) : Colors.grey.shade200,
          width: isSelected ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap:
              _isEditMode
                  ? () => _onInstructorSelected(instructor.id)
                  : () => _onInstructorTapped(instructor),
          borderRadius: BorderRadius.circular(
            Responsive.space(context, size: Space.medium),
          ),
          child: Padding(
            padding: Responsive.padding(context, size: Space.medium),
            child: Row(
              children: [
                CircleAvatar(
                  radius: Responsive.space(context, size: Space.medium),
                  backgroundColor:
                      isSelected
                          ? Colors.green.withOpacity(0.2)
                          : widget.config.primaryColor.withOpacity(0.1),
                  child: Icon(
                    isSelected ? Icons.check : Icons.person,
                    color:
                        isSelected ? Colors.green : widget.config.primaryColor,
                    size: Responsive.space(context, size: Space.medium),
                  ),
                ),

                // Trailing icon
                SizedBox(width: Responsive.space(context, size: Space.medium)),
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        instructor.name,
                        style: TextStyle(
                          fontSize: Responsive.text(
                            context,
                            size: TextSize.medium,
                          ),
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                        textAlign: TextAlign.right,
                      ),
                      SizedBox(
                        height: Responsive.space(context, size: Space.tiny),
                      ),
                      Text(
                        _isEditMode
                            ? (isSelected
                                ? widget.config.defaultInstructorLabel
                                : 'انقر لاختيار ك${widget.config.defaultInstructorLabel}')
                            : widget.config.instructorLabel,
                        style: TextStyle(
                          fontSize: Responsive.text(
                            context,
                            size: TextSize.small,
                          ),
                          color:
                              isSelected
                                  ? Colors.green.shade700
                                  : Colors.grey.shade600,
                        ),
                        textAlign: TextAlign.right,
                      ),
                    ],
                  ),
                ),
                SizedBox(width: Responsive.space(context, size: Space.medium)),
                // Leading avatar
                Icon(
                  _isEditMode
                      ? (isSelected
                          ? Icons.check_circle
                          : Icons.radio_button_unchecked)
                      : Icons.arrow_forward_ios,
                  color: isSelected ? Colors.green : Colors.grey.shade400,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNoInstructorsSection() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(height: Responsive.space(context, size: Space.xlarge)),
          Container(
            padding: EdgeInsets.all(
              Responsive.space(context, size: Space.large),
            ),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.inbox_outlined,
              color: Colors.orange,
              size: Responsive.space(context, size: Space.xlarge) * 1.5,
            ),
          ),
          SizedBox(height: Responsive.space(context, size: Space.large)),
          Text(
            'لا يوجد ${widget.config.instructorLabel}ين',
            style: TextStyle(
              fontSize: Responsive.text(context, size: TextSize.heading),
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: Responsive.space(context, size: Space.small)),
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: Responsive.space(context, size: Space.large),
            ),
            child: Text(
              widget.config.emptyMessage,
              style: TextStyle(
                fontSize: Responsive.text(context, size: TextSize.medium),
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(height: Responsive.space(context, size: Space.xlarge)),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    // Only show footer when in edit mode and selection is enabled
    if (!_isEditMode ||
        !widget.config.enableSelection ||
        widget.instructors.isEmpty ||
        _selectedInstructorId == null) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: Responsive.padding(context, size: Space.large),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
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

                      // Reset saving state and close screen on success
                      if (mounted) {
                        setState(() {
                          _isSaving = false;
                        });
                        Navigator.of(context).pop();
                      }
                    } catch (e) {
                      // Reset saving state on error
                      if (mounted) {
                        setState(() {
                          _isSaving = false;
                        });
                      }
                      // Error will be shown by the callback's ScaffoldMessenger
                    }
                  },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(
              vertical: Responsive.space(context, size: Space.medium),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(
                Responsive.space(context, size: Space.medium),
              ),
            ),
            elevation: 0,
          ),
          child:
              _isSaving
                  ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                  : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.save, size: 20),
                      SizedBox(
                        width: Responsive.space(context, size: Space.small),
                      ),
                      Text(
                        'حفظ الاختيار',
                        style: TextStyle(
                          fontSize: Responsive.text(
                            context,
                            size: TextSize.medium,
                          ),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
        ),
      ),
    );
  }
}

/// Helper function to navigate to InstructorsGate screen
Future<void> showInstructorsGate({
  required BuildContext context,
  required WidgetRef ref,
  required Subject subject,
  required List<UserProfile> instructors,
  required InstructorsGateConfig config,
  String? selectedInstructorId,
  Section? section,
}) {
  return Navigator.of(context).push(
    AnimatedAddRoute(
      startPosition: Offset.zero,
      child: InstructorsGate(
        subject: subject,
        instructors: instructors,
        config: config,
        selectedInstructorId: selectedInstructorId,
        section: section,
      ),
    ),
  );
}
