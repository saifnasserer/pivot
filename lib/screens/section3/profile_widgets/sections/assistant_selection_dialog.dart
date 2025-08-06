import 'package:flutter/material.dart';
import 'package:pivot/models/section_model.dart';
import 'package:pivot/models/subject_model.dart';
import 'package:pivot/models/user_profile.dart';
import 'package:pivot/providers/user_profile_provider.dart';
import 'package:pivot/responsive.dart';
import 'package:provider/provider.dart';

// Assistant Selection Dialog Widget
class AssistantSelectionDialog extends StatefulWidget {
  final Subject subject;
  final Section section;
  final List<UserProfile> assistants;
  final String? selectedAssistantId;
  final Function(String) onAssistantSelected;

  const AssistantSelectionDialog({
    required this.subject,
    required this.section,
    required this.assistants,
    required this.selectedAssistantId,
    required this.onAssistantSelected,
  });

  @override
  State<AssistantSelectionDialog> createState() =>
      _AssistantSelectionDialogState();
}

class _AssistantSelectionDialogState extends State<AssistantSelectionDialog> {
  String? _selectedAssistantId;
  bool _isSaving = false;
  bool _isEditMode = false;

  @override
  void initState() {
    super.initState();
    // Initialize with the passed parameter first
    _selectedAssistantId = widget.selectedAssistantId;

    // Then read the current preference from the provider
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (mounted) {
        final userProfileProvider = Provider.of<UserProfileProvider>(
          context,
          listen: false,
        );

        // Get the current logged-in user profile
        final currentUser = userProfileProvider.loggedInUserProfile;
        if (currentUser != null) {
          final currentAssistantId =
              currentUser.assistantPreferences[widget.subject.id];

          print(
            'Dialog reading preference for ${widget.subject.id}: $currentAssistantId',
          );
          print(
            'Current user assistant preferences: ${currentUser.assistantPreferences}',
          );

          setState(() {
            _selectedAssistantId =
                currentAssistantId ?? widget.selectedAssistantId;
          });
        }
      }
    });
  }

  void _toggleEditMode() {
    if (mounted) {
      setState(() {
        _isEditMode = !_isEditMode;
      });
    }
  }

  void _onAssistantSelected(String assistantId) {
    if (mounted) {
      setState(() {
        _selectedAssistantId = assistantId;
      });
    }
    // Don't save immediately, just update local state
    // The save will happen when the user clicks the save button
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
                  // Subject icon and basic info
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Container(
                        padding: EdgeInsets.all(
                          Responsive.space(context, size: Space.small),
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(
                            Responsive.space(context, size: Space.large),
                          ),
                        ),
                        child: Icon(
                          Icons.class_,
                          color: Colors.black,
                          size: Responsive.space(context, size: Space.medium),
                        ),
                      ),
                      SizedBox(
                        width: Responsive.space(context, size: Space.medium),
                      ),
                      Expanded(
                        child: Text(
                          widget.subject.name,
                          style: TextStyle(
                            fontSize: Responsive.text(
                              context,
                              size: TextSize.heading,
                            ),
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ],
                  ),

                  SizedBox(
                    height: Responsive.space(context, size: Space.medium),
                  ),
                  Divider(thickness: 1, color: Colors.grey[200]),
                  SizedBox(
                    height: Responsive.space(context, size: Space.medium),
                  ),

                  // Section details
                  _buildEnhancedDetailSection(context, widget.section),

                  // Assistants section
                  if (widget.assistants.isNotEmpty) ...[
                    SizedBox(
                      height: Responsive.space(context, size: Space.medium),
                    ),
                    _buildAssistantsSection(
                      context,
                      widget.assistants,
                      widget.subject,
                      _selectedAssistantId,
                      _onAssistantSelected,
                    ),
                  ] else ...[
                    SizedBox(
                      height: Responsive.space(context, size: Space.medium),
                    ),
                    _buildNoAssistantsSection(context),
                  ],
                ],
              ),
            ),
          ),
        ),

        // Footer with action buttons
        Container(
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
                  widget.assistants.isNotEmpty &&
                  _selectedAssistantId != null)
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
                                await widget.onAssistantSelected(
                                  _selectedAssistantId!,
                                );
                                // Success message will be shown by the parent
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
                        horizontal: Responsive.space(
                          context,
                          size: Space.large,
                        ),
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
                        horizontal: Responsive.space(
                          context,
                          size: Space.large,
                        ),
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
        ),
      ],
    );
  }

  Widget _buildEnhancedDetailSection(BuildContext context, Section section) {
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
          _buildEnhancedDetailRow(
            context,
            'السكاشن',
            section.name,
            Icons.class_,
            Colors.blue,
          ),
          SizedBox(height: Responsive.space(context, size: Space.small)),
          _buildEnhancedDetailRow(
            context,
            'المكان',
            section.location,
            Icons.location_on_outlined,
            Colors.green,
          ),
          SizedBox(height: Responsive.space(context, size: Space.small)),
          _buildEnhancedDetailRow(
            context,
            'الأيام',
            section.days,
            Icons.calendar_today,
            Colors.orange,
          ),
          SizedBox(height: Responsive.space(context, size: Space.small)),
          _buildEnhancedDetailRow(
            context,
            'الوقت',
            section.time,
            Icons.access_time,
            Colors.purple,
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedDetailRow(
    BuildContext context,
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

  Widget _buildAssistantsSection(
    BuildContext context,
    List<UserProfile> assistants,
    Subject subject,
    String? selectedAssistantId,
    Function(String) onAssistantSelected,
  ) {
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
                // Edit Button
                IconButton(
                  onPressed: _toggleEditMode,
                  icon: Icon(
                    _isEditMode ? Icons.close : Icons.edit,
                    color: _isEditMode ? Colors.red : Colors.black,
                  ),
                  tooltip:
                      _isEditMode ? 'إلغاء التعديل' : 'تعديل المعيد الافتراضي',
                ),
                // Status indicator
                if (selectedAssistantId != null)
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
                    'المعيدين',
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
            itemCount: assistants.length,
            separatorBuilder:
                (context, index) => Divider(height: 1, color: Colors.grey[200]),
            itemBuilder: (context, index) {
              final assistant = assistants[index];
              return _buildAssistantTile(
                context,
                assistant,
                subject,
                selectedAssistantId,
                onAssistantSelected,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAssistantTile(
    BuildContext context,
    UserProfile assistant,
    Subject subject,
    String? selectedAssistantId,
    Function(String) onAssistantSelected,
  ) {
    final isSelected = _isEditMode && selectedAssistantId == assistant.id;

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
        assistant.name,
        style: TextStyle(
          fontSize: Responsive.text(context, size: TextSize.medium),
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
      subtitle: Text(
        _isEditMode
            ? (isSelected
                ? 'المعيد الافتراضي المختار'
                : 'انقر لاختيار كمعيد افتراضي')
            : 'معيد',
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
              ? () => onAssistantSelected(assistant.id)
              : () {
                Navigator.of(context).pop();
                Navigator.pushNamed(
                  context,
                  '/assistant-profile',
                  arguments: assistant,
                );
              },
    );
  }

  Widget _buildNoAssistantsSection(BuildContext context) {
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
              'لا يوجد معيدين مسجلين لهذه المادة بعد',
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
}
