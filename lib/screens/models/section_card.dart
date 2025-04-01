import 'package:flutter/material.dart';
import 'package:pivot/providers/section_provider.dart';
import 'package:pivot/responsive.dart';
import 'package:pivot/screens/section4/assistants/add_edit_section_dialog.dart';
import 'package:pivot/screens/section4/assistants/all_tasks.dart';
import 'package:provider/provider.dart';

class SectionCard extends StatelessWidget {
  final String sectionId;
  final String title;
  final String days;
  final String location;
  final String time;
  final String subjectName;

  const SectionCard({
    super.key,
    required this.sectionId,
    required this.title,
    required this.days,
    required this.location,
    required this.time,
    required this.subjectName,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(
          context,
          TasksControl.id,
          arguments: sectionId, // Pass sectionId as argument
        );
      },
      onLongPress: () {
        final sectionProvider = context.read<SectionProvider>();
        // 1. Find the specific SectionInfo object for this card
        final sectionToEdit = sectionProvider.getSectionById(
          subjectName,
          sectionId,
        );

        if (sectionToEdit != null) {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AddEditSectionDialog(
                subjectNames:
                    sectionProvider.subjectNames, // List of all subjects
                initialSubjectName:
                    subjectName, // The original subject of this section
                sectionToEdit: sectionToEdit, // The section data to edit
              );
            },
          );
        } else {
          // Optional: Handle case where section couldn't be found (shouldn't normally happen)
          print(
            "Error: Could not find section $sectionId in subject $subjectName to edit.",
          );
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('حدث خطأ: لم يتم العثور على السكشن للتعديل'),
            ),
          );
        }
      },
      child: Container(
        margin: EdgeInsets.only(bottom: Responsive.space(context)),
        padding: EdgeInsets.all(Responsive.space(context)),
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(Responsive.space(context) * 0.8),
          color: Colors.grey[200],
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Section Title (Prominent)
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Icon(
                  Icons.location_on_outlined,
                  size: Responsive.text(context),
                  color: Colors.black54,
                ),
                SizedBox(width: Responsive.space(context) * 0.5),
                Text(
                  location, // Use parameter
                  style: TextStyle(
                    color: Colors.black87,
                    fontSize: Responsive.text(context) * 0.95,
                  ),
                ),
                Spacer(),
                Text(
                  title, // Use parameter
                  style: TextStyle(
                    color: Colors.black87,
                    fontSize: Responsive.text(context) * 1.1,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: Responsive.space(context) * 0.75),

            // Days Row
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Icon(
                  Icons.access_time_outlined,
                  size: Responsive.text(context),
                  color: Colors.black54,
                ),
                SizedBox(width: Responsive.space(context) * 0.5),
                Text(
                  time, // Use parameter
                  style: TextStyle(
                    color: Colors.black87,
                    fontSize: Responsive.text(context) * 0.95,
                  ),
                ),

                SizedBox(width: Responsive.space(context)),
                Expanded(
                  child: Text(
                    textAlign: TextAlign.right,
                    days, // Use parameter
                    style: TextStyle(
                      color: Colors.black87,
                      fontSize: Responsive.text(context) * 0.95,
                    ),
                  ),
                ),

                // ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
