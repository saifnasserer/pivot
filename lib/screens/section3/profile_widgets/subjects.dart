import 'package:flutter/material.dart';
import 'package:pivot/responsive.dart';
import 'package:pivot/widgets/unified_dialog.dart';
import 'package:pivot/models/subject_model.dart';
import 'package:pivot/models/user_profile.dart';

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
    showDialog(
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
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Expanded(
                    child: Directionality(
                      textDirection: TextDirection.rtl,
                      child: SingleChildScrollView(
                        padding: Responsive.padding(
                          context,
                          size: Space.medium,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            // Subject icon and basic info
                            Container(
                              width: double.infinity,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Container(
                                    padding: EdgeInsets.all(
                                      Responsive.space(
                                        context,
                                        size: Space.small,
                                      ),
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(
                                        Responsive.space(
                                          context,
                                          size: Space.large,
                                        ),
                                      ),
                                    ),
                                    child: Icon(
                                      Icons.menu_book_rounded,
                                      color: Colors.black,
                                      size: Responsive.space(
                                        context,
                                        size: Space.medium,
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    width: Responsive.space(
                                      context,
                                      size: Space.medium,
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      subject.name,
                                      style: TextStyle(
                                        fontSize: Responsive.text(
                                          context,
                                          size: TextSize.heading,
                                        ),
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                      textAlign: TextAlign.right,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),

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

                            // Subject details section
                            _buildEnhancedDetailSection(context, subject),

                            // Professors section
                            if (professors.isNotEmpty) ...[
                              SizedBox(
                                height: Responsive.space(
                                  context,
                                  size: Space.medium,
                                ),
                              ),
                              _buildProfessorsSection(context, professors),
                            ] else ...[
                              SizedBox(
                                height: Responsive.space(
                                  context,
                                  size: Space.medium,
                                ),
                              ),
                              _buildNoProfessorsSection(context),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Footer with action button
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
                      border: Border(
                        top: BorderSide(color: Colors.grey.shade200),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(
                              horizontal: Responsive.space(
                                context,
                                size: Space.large,
                              ),
                              vertical: Responsive.space(
                                context,
                                size: Space.medium,
                              ),
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
                                width: Responsive.space(
                                  context,
                                  size: Space.small,
                                ),
                              ),
                              Text('إغلاق'),
                            ],
                          ),
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

  Widget _buildEnhancedDetailSection(BuildContext context, Subject subject) {
    return Container(
      padding: Responsive.padding(context, size: Space.medium),
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
          UnifiedSectionHeader(
            title: 'تفاصيل المادة',
            icon: Icons.info_outline,
          ),
          _buildEnhancedDetailRow(
            context,
            'القسم',
            subject.departments.join(', '),
            Icons.business,
            Colors.blue,
          ),
          SizedBox(height: Responsive.space(context, size: Space.small)),
          _buildEnhancedDetailRow(
            context,
            'الترم',
            subject.year.toString(),
            Icons.school,
            Colors.green,
          ),
          SizedBox(height: Responsive.space(context, size: Space.small)),
          _buildEnhancedDetailRow(
            context,
            'الساعات',
            subject.hours.toString(),
            Icons.tag,
            Colors.orange,
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

  Widget _buildProfessorsSection(
    BuildContext context,
    List<UserProfile> professors,
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
            child: UnifiedSectionHeader(
              title: 'دكاترة المادة',
              icon: Icons.people,
            ),
          ),
          ListView.separated(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: professors.length,
            separatorBuilder:
                (context, index) => Divider(height: 1, color: Colors.grey[200]),
            itemBuilder: (context, index) {
              final professor = professors[index];
              return _buildProfessorTile(context, professor);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildProfessorTile(BuildContext context, UserProfile professor) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Colors.black.withOpacity(0.1),
        child: Icon(Icons.person, color: Colors.black),
      ),
      title: Text(
        professor.name,
        style: TextStyle(
          fontSize: Responsive.text(context, size: TextSize.medium),
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
      subtitle: Text(
        'دكتور',
        style: TextStyle(
          fontSize: Responsive.text(context, size: TextSize.small),
          color: Colors.grey.shade600,
        ),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios,
        color: Colors.grey.shade400,
        size: 16,
      ),
      onTap: () {
        Navigator.of(context).pop();
        Navigator.pushNamed(context, '/doctor-profile', arguments: professor);
      },
    );
  }

  Widget _buildNoProfessorsSection(BuildContext context) {
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
              'لا يوجد دكاترة مسجلين لهذه المادة بعد',
              style: TextStyle(
                fontSize: Responsive.text(context, size: TextSize.medium),
                color: Colors.orange,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
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
