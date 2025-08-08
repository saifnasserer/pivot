import 'package:flutter/material.dart';
import 'package:pivot/responsive.dart';
import 'package:pivot/screens/section2/adminstration/announcement/add_announcement_controller.dart';

class StylingStep extends StatelessWidget {
  final Color selectedColor;
  final List<String> selectedTags;
  final String? selectedLevel;
  final Function(Color) onColorChanged;
  final Function(List<String>) onTagsChanged;
  final Function(String?) onLevelChanged;
  final Animation<double> fadeAnimation;
  final Animation<Offset> slideAnimation;

  const StylingStep({
    super.key,
    required this.selectedColor,
    required this.selectedTags,
    required this.selectedLevel,
    required this.onColorChanged,
    required this.onTagsChanged,
    required this.onLevelChanged,
    required this.fadeAnimation,
    required this.slideAnimation,
  });

  List<String> _getAvailableTagsForLevel(String? selectedLevel) {
    // Always include "عام" tag
    final availableTags = ['عام'];

    if (selectedLevel == null) {
      // If no level selected, show all tags
      return AddAnnouncementController.availableTags;
    }

    // Add department tags based on level
    if (selectedLevel == 'الفرقة الأولى' || selectedLevel == 'الفرقة الثانية') {
      // Levels 1 & 2: Only General department
      availableTags.add('General');
    } else if (selectedLevel == 'الفرقة الثالثة' ||
        selectedLevel == 'الفرقة الرابعة') {
      // Levels 3 & 4: All departments except General
      availableTags.addAll(['SC', 'AI', 'CS', 'IS']);
    }

    return availableTags;
  }

  Widget _buildColorOption(
    BuildContext context, {
    required Color color,
    required String label,
    required bool isSelected,
  }) {
    return GestureDetector(
      onTap: () => onColorChanged(color),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: color.withOpacity(0.3),
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? Colors.black : Colors.transparent,
                width: 3,
              ),
            ),
            child:
                isSelected
                    ? Center(
                      child: Icon(Icons.check, color: Colors.black87, size: 40),
                    )
                    : null,
          ),
          SizedBox(height: Responsive.space(context, size: Space.small)),
          Text(
            label,
            style: TextStyle(
              fontSize: Responsive.text(context, size: TextSize.medium),
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: fadeAnimation,
      builder: (context, child) {
        return FadeTransition(
          opacity: fadeAnimation,
          child: AnimatedBuilder(
            animation: slideAnimation,
            builder: (context, child) {
              return SlideTransition(
                position: slideAnimation,
                child: Container(
                  width: double.infinity,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header
                      Container(
                        padding: Responsive.padding(context, size: Space.large),
                        decoration: BoxDecoration(
                          color: Colors.purple.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(
                            Responsive.space(context, size: Space.large),
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    'التصميم والأقسام',
                                    style: TextStyle(
                                      fontSize:
                                          Responsive.text(
                                            context,
                                            size: TextSize.heading,
                                          ) *
                                          1.2,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.purple[700],
                                    ),
                                    textAlign: TextAlign.right,
                                  ),
                                  Text(
                                    'اختر اللون والأقسام المستهدفة',
                                    style: TextStyle(
                                      fontSize: Responsive.text(
                                        context,
                                        size: TextSize.medium,
                                      ),
                                      color: Colors.purple[600],
                                    ),
                                    textAlign: TextAlign.right,
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(
                              width: Responsive.space(
                                context,
                                size: Space.medium,
                              ),
                            ),
                            Icon(
                              Icons.palette,
                              color: Colors.purple[700],
                              size:
                                  Responsive.space(context, size: Space.large) *
                                  1.5,
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        height: Responsive.space(context, size: Space.large),
                      ),

                      // Color selection
                      Text(
                        'اختر مستوى الأهمية:',
                        style: TextStyle(
                          fontSize: Responsive.text(
                            context,
                            size: TextSize.heading,
                          ),
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[700],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(
                        height: Responsive.space(context, size: Space.large),
                      ),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildColorOption(
                            context,
                            color: const Color(0xFFFF5252),
                            label: 'مهم',
                            isSelected:
                                selectedColor == const Color(0xFFFF5252),
                          ),
                          _buildColorOption(
                            context,
                            color: const Color(0xFFFFEF86),
                            label: 'متوسط',
                            isSelected:
                                selectedColor == const Color(0xFFFFEF86),
                          ),
                          _buildColorOption(
                            context,
                            color: const Color(0xFF99F16C),
                            label: 'عادي',
                            isSelected:
                                selectedColor == const Color(0xFF99F16C),
                          ),
                        ],
                      ),
                      SizedBox(
                        height: Responsive.space(context, size: Space.large),
                      ),

                      // Level selection
                      Text(
                        'اختر الفرقة المستهدفة:',
                        style: TextStyle(
                          fontSize: Responsive.text(
                            context,
                            size: TextSize.heading,
                          ),
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[700],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(
                        height: Responsive.space(context, size: Space.medium),
                      ),

                      // Level options
                      Wrap(
                        spacing: Responsive.space(context, size: Space.medium),
                        runSpacing: Responsive.space(
                          context,
                          size: Space.small,
                        ),
                        alignment: WrapAlignment.center,
                        children:
                            [
                              'الفرقة الأولى',
                              'الفرقة الثانية',
                              'الفرقة الثالثة',
                              'الفرقة الرابعة',
                            ].map((level) {
                              final isSelected = selectedLevel == level;
                              return FilterChip(
                                label: Text(
                                  level,
                                  style: TextStyle(
                                    color:
                                        isSelected
                                            ? Colors.white
                                            : Colors.black87,
                                    fontWeight: FontWeight.w600,
                                    fontSize: Responsive.text(
                                      context,
                                      size: TextSize.medium,
                                    ),
                                  ),
                                ),
                                selected: isSelected,
                                onSelected: (selected) {
                                  final newLevel = selected ? level : null;
                                  onLevelChanged(newLevel);

                                  // Clear selected tags when level changes to prevent invalid selections
                                  if (newLevel != selectedLevel) {
                                    onTagsChanged([]);
                                  }
                                },
                                selectedColor: Colors.blue[600],
                                backgroundColor: Colors.grey[200],
                                checkmarkColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(25),
                                ),
                                padding: EdgeInsets.symmetric(
                                  horizontal: Responsive.space(
                                    context,
                                    size: Space.medium,
                                  ),
                                  vertical: Responsive.space(
                                    context,
                                    size: Space.small,
                                  ),
                                ),
                              );
                            }).toList(),
                      ),
                      SizedBox(
                        height: Responsive.space(context, size: Space.large),
                      ),

                      // Tags selection
                      Text(
                        'اختر الأقسام المستهدفة:',
                        style: TextStyle(
                          fontSize: Responsive.text(
                            context,
                            size: TextSize.heading,
                          ),
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[700],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      if (selectedLevel == null)
                        Padding(
                          padding: EdgeInsets.only(
                            top: Responsive.space(context, size: Space.small),
                          ),
                          child: Text(
                            'يرجى اختيار الفرقة أولاً',
                            style: TextStyle(
                              fontSize: Responsive.text(
                                context,
                                size: TextSize.small,
                              ),
                              color: Colors.orange[600],
                              fontStyle: FontStyle.italic,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      SizedBox(
                        height: Responsive.space(context, size: Space.large),
                      ),

                      Wrap(
                        spacing: Responsive.space(context, size: Space.medium),
                        runSpacing: Responsive.space(
                          context,
                          size: Space.small,
                        ),
                        alignment: WrapAlignment.center,
                        children:
                            _getAvailableTagsForLevel(selectedLevel).map((tag) {
                              final isSelected = selectedTags.contains(tag);
                              final isEnabled =
                                  selectedLevel !=
                                  null; // Disable if no level selected
                              return FilterChip(
                                label: Text(
                                  tag,
                                  style: TextStyle(
                                    color:
                                        isEnabled
                                            ? (isSelected
                                                ? Colors.white
                                                : Colors.black87)
                                            : Colors.grey[400],
                                    fontWeight: FontWeight.w600,
                                    fontSize: Responsive.text(
                                      context,
                                      size: TextSize.medium,
                                    ),
                                  ),
                                ),
                                selected: isSelected,
                                onSelected:
                                    isEnabled
                                        ? (selected) {
                                          final newTags = List<String>.from(
                                            selectedTags,
                                          );
                                          if (selected) {
                                            if (!newTags.contains(tag)) {
                                              newTags.add(tag);
                                            }
                                          } else {
                                            newTags.remove(tag);
                                          }
                                          onTagsChanged(newTags);
                                        }
                                        : null,
                                selectedColor: selectedColor,
                                backgroundColor:
                                    isEnabled
                                        ? Colors.grey[200]
                                        : Colors.grey[100],
                                checkmarkColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(25),
                                ),
                                padding: EdgeInsets.symmetric(
                                  horizontal: Responsive.space(
                                    context,
                                    size: Space.medium,
                                  ),
                                  vertical: Responsive.space(
                                    context,
                                    size: Space.small,
                                  ),
                                ),
                              );
                            }).toList(),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
