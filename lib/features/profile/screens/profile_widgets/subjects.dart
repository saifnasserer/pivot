import 'package:flutter/material.dart';
import 'package:pivot/models/user_profile.dart';
import 'package:pivot/screens/models/instructors_gate.dart';
import 'package:pivot/responsive.dart';
import 'package:pivot/models/subject_model.dart';

/// Enhanced subjects builder with better UX and performance
class SubjectsBuilder {
  /// Builds a complete subjects list with enhanced features
  static List<Widget> buildSubjectsSlivers(
    BuildContext context,
    List<Subject> subjects,
    Map<String, List<UserProfile>> instructorsMap, {
    bool enableAnimations = true,
    List<String>? enrolledIds,
  }) {
    if (subjects.isEmpty) {
      return [_buildEmptyState(context, enrolledIds)];
    }

    return [
      _buildSubjectsList(context, subjects, instructorsMap, enableAnimations),
    ];
  }

  /// Builds enhanced empty state
  static Widget _buildEmptyState(
    BuildContext context,
    List<String>? enrolledIds,
  ) {
    return SliverFillRemaining(
      hasScrollBody: false,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(
                Responsive.space(context, size: Space.large),
              ),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.school_outlined,
                size: Responsive.text(context, size: TextSize.heading) * 1.5,
                color: Colors.grey.shade400,
              ),
            ),
            SizedBox(height: Responsive.space(context, size: Space.large)),
            Text(
              'لا توجد مواد مسجلة',
              style: TextStyle(
                fontSize: Responsive.text(context, size: TextSize.heading),
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: Responsive.space(context, size: Space.small)),
            Text(
              'قم بتسجيل المواد أولاً',
              style: TextStyle(
                fontSize: Responsive.text(context, size: TextSize.medium),
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: Responsive.space(context, size: Space.large)),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  '/subject-selection',
                  arguments: {'previouslySelectedIds': enrolledIds},
                );
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
                    Responsive.space(context, size: Space.large),
                  ),
                ),
              ),
              child: const Text('تسجيل المواد'),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds subjects list with enhanced styling
  static Widget _buildSubjectsList(
    BuildContext context,
    List<Subject> subjects,
    Map<String, List<UserProfile>> instructorsMap,
    bool enableAnimations,
  ) {
    return SliverPadding(
      padding: EdgeInsets.symmetric(
        horizontal: Responsive.space(context, size: Space.medium),
        vertical: Responsive.space(context, size: Space.small),
      ),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          final subject = subjects[index];
          final instructors = instructorsMap[subject.id];

          return AnimatedContainer(
            duration:
                enableAnimations
                    ? Duration(milliseconds: 300 + (index * 50))
                    : Duration.zero,
            curve: Curves.easeInOut,
            child: EnhancedSubjectListItem(
              subject: subject,
              instructors: instructors,
              index: index,
            ),
          );
        }, childCount: subjects.length),
      ),
    );
  }
}

/// Enhanced subject list item with better design and functionality
class EnhancedSubjectListItem extends StatefulWidget {
  const EnhancedSubjectListItem({
    super.key,
    required this.subject,
    this.instructors,
    required this.index,
  });

  final Subject subject;
  final List<UserProfile>? instructors;
  final int index;

  @override
  State<EnhancedSubjectListItem> createState() =>
      _EnhancedSubjectListItemState();
}

class _EnhancedSubjectListItemState extends State<EnhancedSubjectListItem>
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
    _showEnhancedSubjectDetails(context, widget.subject, _getProfessors());
  }

  List<UserProfile> _getProfessors() {
    return widget.instructors
            ?.where((prof) => prof.role.toLowerCase() == 'professor')
            .toList() ??
        [];
  }

  @override
  Widget build(BuildContext context) {
    final professors = _getProfessors();

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            margin: EdgeInsets.only(
              bottom: Responsive.space(context, size: Space.small),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(
                  Responsive.space(context, size: Space.large),
                ),
                onTap: _onTap,
                onHover: (hovered) {
                  setState(() => _isHovered = hovered);
                  if (hovered) {
                    _animationController.forward();
                  } else {
                    _animationController.reverse();
                  }
                },
                child: Container(
                  padding: Responsive.padding(context, size: Space.medium),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(
                      Responsive.space(context, size: Space.large),
                    ),
                    border: Border.all(
                      color: _isHovered ? Colors.black : Colors.grey.shade200,
                      width: _isHovered ? 2 : 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(
                          _isHovered ? 0.1 : 0.05,
                        ),
                        blurRadius: _isHovered ? 8 : 4,
                        offset: Offset(0, _isHovered ? 4 : 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // Arrow icon (RTL - on the left)
                      Icon(
                        Icons.arrow_back_ios,
                        color: _isHovered ? Colors.black : Colors.grey.shade400,
                        size: 16,
                      ),

                      // Subject info
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
                                size: Space.tiny,
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
                                  'الترم ${widget.subject.year}',
                                  Colors.blue,
                                ),
                                _buildInfoChip(
                                  context,
                                  '${widget.subject.hours} ساعة',
                                  Colors.green,
                                ),
                                if (professors.isNotEmpty)
                                  _buildInfoChip(
                                    context,
                                    '${professors.length} دكتور',
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

                      // Subject icon (RTL - on the right)
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
                          Icons.menu_book_rounded,
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

  Widget _buildInfoChip(BuildContext context, String label, Color color) {
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
        label,
        style: TextStyle(
          fontSize: Responsive.text(context, size: TextSize.small),
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  void _showEnhancedSubjectDetails(
    BuildContext context,
    Subject subject,
    List<UserProfile> professors,
  ) {
    showInstructorsGate(
      context: context,
      subject: subject,
      instructors: professors,
      config: InstructorsGateConfig.professors,
    );
  }
}

// Keep the original function for backward compatibility
List<Widget> buildSubjectsSlivers(
  BuildContext context,
  List<Subject> subjects,
  Map<String, List<UserProfile>> instructorsMap,
) {
  return SubjectsBuilder.buildSubjectsSlivers(
    context,
    subjects,
    instructorsMap,
    enableAnimations: true,
  );
}

// Keep the original class for backward compatibility
class SubjectListItem extends StatelessWidget {
  const SubjectListItem({super.key, required this.subject, this.instructors});

  final Subject subject;
  final List<UserProfile>? instructors;

  @override
  Widget build(BuildContext context) {
    return EnhancedSubjectListItem(
      subject: subject,
      instructors: instructors,
      index: 0,
    );
  }
}
